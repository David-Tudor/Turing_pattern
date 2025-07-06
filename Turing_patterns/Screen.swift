//
//  PetriDish.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//

import Foundation
import SwiftUI



struct Simulation {
    let height: Int
    let width: Int
    let chem_cols: [Colour]
    var values: Grid
    
    init(height: Int, width: Int, chem_cols: [Colour]) {
        self.height = height
        self.width = width
        self.chem_cols = chem_cols
        self.values = Grid(height: height, width: width, num_chems: chem_cols.count)
    }
    
    func export_to_view() -> some View {
        let background_pixel = make_PixelData(col: .grey)
        var pixel_data = [PixelData](repeating: background_pixel, count: Int(height * width))
        
        for x in 0 ..< width {
            for y in 0 ..< height {
                // mix of colour channels for each chemical
                
                // show most concentrated chemical
                guard let i = find_idx_of_max(of: values[x,y].concs) else {
                    continue // pixel is left as background (grey) if all concs are equal
                }
                pixel_data[(x * height) + y] = make_PixelData(col: chem_cols[i])
            }
        }
        
        let cgimage = pixeldata_to_image(pixels: pixel_data, width: width, height: height)
        return Image(cgimage, scale: 1, label: Text(""))
    }
    
    func is_point_valid(_ x: Int, _ y: Int) -> Bool {
        if x >= 0 && y >= 0 && x < height && y < width {
            return true
        } else {
            return false
        }
    }
    
    mutating func clear_values() {
        values = Grid(height: height, width: width, num_chems: chem_cols.count)
    }
    
    mutating func create_circle(of chem_i: Int, around position: [Int], diameter: Double, amount: Double) {
        let coords = get_integs_in_circle(diameter: diameter)
        var x = 0
        var y = 0
        
        for xy in coords {
            x = xy[0] + position[0]
            y = xy[1] + position[1]
            if is_point_valid(x, y) {
                values[x, y].concs[chem_i] += amount
            }
        }
    }
    
    mutating func time_step() {
        let zeros = [Double](repeating: 0.0, count: chem_cols.count)
        var new_values = values
        var lap = zeros
        
        for x in 0 ..< width {
            for y in 0 ..< height {
                lap = laplacian(x, y) // check for negatives
                for i in 0..<chem_cols.count { // use map?
                    new_values[x,y].concs[i] += lap[i] * 0.1 // dt = 0.1
                }
                
            }
        }
        values = new_values
//        print(values[100,100].concs, values[100,101].concs)
        
        // make a colour mode for gradients
        // circular diffusion
    }
    
    func laplacian(_ x: Int, _ y: Int) -> [Double] {
        // using h = 1
        var ans = [Double](repeating: 0.0, count: chem_cols.count)
        if (x != 0) && (y != 0) && (x != width-1) && (y != height-1) {
            for i in 0..<chem_cols.count { // XXX needs efficiency
                ans[i] = values[x-1,y].concs[i] + values[x+1,y].concs[i] + values[x,y-1].concs[i] + values[x,y+1].concs[i] - 4*values[x,y].concs[i]
            }
             
        }
        return ans
        
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

