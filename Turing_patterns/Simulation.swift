//
//  PetriDish.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//

import Foundation
import SwiftUI
import simd



struct Simulation {
    let height: Int
    let width: Int
    var chem_cols: [Colour] // overwritten with cym if <=3 colours
    var values: Grid
    var is_running = false
    var background_col: Colour // if white (255,...), cym used, else rgb or specified colours
    var dt: Double
    let diffusion_const = 2.0
    
    
    init(height: Int, width: Int, chem_cols: [Colour], dt: Double, background_col_enum: Colour_enum) {
        self.height = height
        self.width = width
        self.dt = dt
        self.values = Grid(height: height, width: width, num_chems: chem_cols.count)
        self.background_col = rgb_for(col: background_col_enum)
        self.chem_cols = []
        
    }
    
    func export_to_view() -> some View {
        let background_pixel = make_PixelData(rgb: background_col)
        var pixel_data = [PixelData](repeating: background_pixel, count: Int(height * width))
        
        for x in 0 ..< width {
            for y in 0 ..< height {
                // move 0 check to the start? add mode option?
                
                if values[x,y].concs.allSatisfy({$0 == 0.0}) {
                    pixel_data[(x * height) + y] = background_pixel
                } else if chem_cols.count <= 3 {
                    pixel_data[(x * height) + y] = make_PixelData(rgb: concs_to_colours(concs: values[x,y].concs))
                } else {
                    // show most concentrated chemical
                    guard let i = find_idx_of_max(of: values[x,y].concs) else {
                        continue // pixel is left as background (grey) if all concs are zero
                    }
                    pixel_data[(x * height) + y] = make_PixelData(rgb: chem_cols[i])
                }
            }
        }
        
        let cgimage = pixeldata_to_image(pixels: pixel_data, width: width, height: height)
        return Image(cgimage, scale: 1, label: Text(""))
    }
    
    func concs_to_colours(concs: [Double]) -> Colour {
        // returns a rgb or cym Colour. concs of different chemicals change independent channels (so assumes <= 3 concs)
        var c = 0.0
        
        var col: [Int]
        let sign: Int
        if (background_col != [255,255,255]) {
            col = [0, 0, 0] // additive colour for rgb
            sign = 1
        } else {
            col = [255, 255, 255] // subtractive colour for cym
            sign = -1
        }
        
        for i in 0 ..< concs.count {
            c = concs[i]
            col[i] += sign * Int( 256 * c/(c+0.1) )
        }
        return col
    }
    
    func is_point_valid(_ x: Int, _ y: Int) -> Bool {
        x >= 0 && y >= 0 && x < height && y < width
    }
    
    func is_point_edge(_ x: Int, _ y: Int) -> Bool {
        (x == 0) || (y == 0) || (x == width-1) || (y == height-1)
    }
    
    mutating func clear_values() {
        values = Grid(height: height, width: width, num_chems: chem_cols.count)
    }
    
    mutating func create_circle(of chem_i: Int, around position: [Int], diameter: Double, amount: Double) {
        // if chem_i == chem_cols.count, sponge up chemicals, else add the chosen one.
        let coords = get_integs_in_circle(diameter: diameter)
        var x = 0
        var y = 0
        
        for xy in coords {
            x = xy[0] + position[0]
            y = xy[1] + position[1]
            if is_point_valid(x, y) {
                if chem_i == chem_cols.count {
                    values[x, y].concs = [Double](repeating: 0.0, count: chem_cols.count) // sponge
                } else {
                    values[x, y].concs[chem_i] += amount // add chemical
                }
            }
        }
    }
    
    mutating func time_step() {

        let zeros = [Double](repeating: 0.0, count: chem_cols.count)
        var new_values = values
        var lap = zeros
        let Ddt = diffusion_const * dt
        
        for x in 0 ..< width {
            for y in 0 ..< height {
                lap = laplacian(x, y) // TODO check for negatives
                for i in 0..<chem_cols.count {
                    new_values[x,y].concs[i] += lap[i] * Ddt
                    if new_values[x,y].concs[i] < 0 {
                        print("WARNING, DIFFUSION WOULD MAKE NEGATIVE \(new_values[x,y].concs[i]-lap[i] * Ddt) + \(lap[i]) * \(Ddt)")
                        new_values[x,y].concs[i] = 0
                    }
                }
            }
        }
        values = new_values
        values = reaction()
        
    }
    
    
    
    func laplacian(_ x: Int, _ y: Int) -> [Double] {
        // using h = 1
        var ans = [Double](repeating: 0.0, count: chem_cols.count)
        if !is_point_edge(x,y) {
            for i in 0..<chem_cols.count {
                // kernel https://math.stackexchange.com/questions/3464125/how-was-the-2d-discrete-laplacian-matrix-calculated
                ans[i] = 0.1666 * ( 4 * (values[x-1,y].concs[i] + values[x+1,y].concs[i] + values[x,y-1].concs[i] + values[x,y+1].concs[i])
                                 + (values[x-1,y-1].concs[i] + values[x+1,y+1].concs[i] + values[x+1,y-1].concs[i] + values[x-1,y+1].concs[i])
                                 - 20 * values[x,y].concs[i] )
            }
        }
        return ans
    }
    
    func reaction() -> Grid {
//        let rates = [1.0, 0.1, 0.4]
        let rates = [1.0, 0.05, 0.2]
        func expr1(_ a: Double, _ b: Double, _ p: Double) -> Double { return -rates[0] * a*b*b + rates[1] * pow(b, 3) }
        func expr2(_ a: Double, _ b: Double, _ p: Double) -> Double { return -rates[2] * b }
        var new_values = values
        var concs: [Double]
        var val1: Double
        var val2: Double
        for x in 0 ..< width {
            for y in 0 ..< height { // can't use a matrix as not linear e.g. in b. what else?
                concs = values[x,y].concs
                val1 = expr1(concs[0], concs[1], concs[2]) * dt
                val2 = expr2(concs[0], concs[1], concs[2]) * dt
                if new_values[x,y].concs[0] > -val1 && new_values[x,y].concs[1] > val1 { // only react if concs will stay positive
                    new_values[x,y].concs[0] +=  val1
                    new_values[x,y].concs[1] += -val1
                }
                if new_values[x,y].concs[1] > -val2 && new_values[x,y].concs[2] > val2 {
                    new_values[x,y].concs[1] +=  val2
                    new_values[x,y].concs[2] += -val2
                }
            }
            
        }
        return new_values
    }
    
}

struct Grid {
    var values: [Cell]
    let height: Int
    let width: Int
    
    subscript(row: Int, column: Int) -> Cell {
        get { return values[(row * height) + column] }
        set { values[(row * height) + column] = newValue }
    }
    
    init(height: Int, width: Int, num_chems: Int) {
        let cell = Cell(concs: [Double](repeating: 0.0, count: num_chems))
        self.values = [Cell](repeating: cell, count: Int(height * width))
        self.height = height
        self.width = width
    }
}

struct Cell {
    var concs: [Double]
}
