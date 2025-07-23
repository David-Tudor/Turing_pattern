//
//  PetriDish.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//

import Foundation
import SwiftUI
import simd

import Accelerate

struct Simulation {
    let height: Int
    let width: Int
    var chem_cols: [Colour] // data passed from simulation_container via onChange
    var values: Grid
    var is_running = false
    var background_col: Colour // if white (255,...), cym used, else rgb or specified colours
    var dt: Num
    var diffusion_consts: [Num] = []
    var reaction_funcs: [ ([Num]) -> [Num] ]
    
    var test_concs: [Num] {
        [Num].init(repeating: 1.0, count: chem_cols.count)
    }
    
    var test_results_all: [[Bool]] {
        var ans: [[Bool]] = []
        for f in reaction_funcs {
            ans.append(f(test_concs).map{!$0.isZero})
        }
        return ans
    }
    
    var chem_idxs_all: [[Int]] {
        var ans = [[Int]].init(repeating: [], count: reaction_funcs.count)
        for i in 0..<reaction_funcs.count {
            for j in 0..<chem_cols.count where test_results_all[i][j] {
                ans[i].append(j)
            }
        }
        return ans
    }
    
    init(height: Int, width: Int, chem_cols: [Colour], dt: Num, background_col_enum: Colour_enum, chems: [String], equation_list: [String], rate_list: [[Num]]) {
        self.height = height
        self.width = width
        self.dt = dt
        self.values = Grid(height: height, width: width, num_chems: chem_cols.count)
        self.background_col = rgb_for(col: background_col_enum)
        self.chem_cols = []
        self.reaction_funcs = make_reaction_functions(chems: chems, equation_list: equation_list, rate_list: rate_list)
    }
    
    func export_to_view() -> some View {
        let background_pixel = make_PixelData(rgb: background_col)
        var pixel_data = [PixelData](repeating: background_pixel, count: Int(height * width))
        
        for x in 0 ..< width {
            for y in 0 ..< height {
                // move 0 check to the start? add mode option?
                
                if values[x,y].concs.allSatisfy({$0 == 0.0}) {
                    pixel_data[(y * width) + x] = background_pixel
                } else if chem_cols.count <= 3 {
                    pixel_data[(y * width) + x] = make_PixelData(rgb: concs_to_colours(concs: values[x,y].concs))
                } else {
                    // show most concentrated chemical
                    guard let i = find_idx_of_max(of: values[x,y].concs) else {
                        continue // pixel is left as background (grey) if all concs are zero
                    }
                    pixel_data[(y * width) + x] = make_PixelData(rgb: chem_cols[i])
                }
            }
        }
        
        let cgimage = pixeldata_to_image(pixels: pixel_data, width: width, height: height)
        return Image(cgimage, scale: 1, label: Text(""))
    }
    
    func concs_to_colours(concs: [Num]) -> Colour {
        // returns a rgb or cym Colour. concs of different chemicals change independent channels (so assumes <= 3 concs)
        var c: Num = 0.0
        
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
    
    mutating func create_circle(of chem_i: Int?, around position: [Int], diameter: Double, amount: Num) {
        // if chem_i == nil, sponge up chemicals, else add the chosen one.
        let coords = get_integs_in_circle(diameter: diameter)
        var x = 0
        var y = 0
        
        for xy in coords {
            x = xy[0] + position[0]
            y = xy[1] + position[1]
            if is_point_valid(x, y) {
                if let chemical = chem_i  {
                    values[x, y].concs[chemical] += amount // add chemical
                } else {
                    values[x, y].concs = [Num](repeating: 0.0, count: chem_cols.count) // sponge
                }
            }
        }
    }
    
    mutating func time_step() {
        values = diffusion()
        values = reaction()
    }
    
    // Diffusion functions
    
    func diffusion() -> Grid {
        let Ddt = diffusion_consts.map { Float($0 * dt) }
        var src = [[Float]].init(repeating: [Float].init(repeating: 0.0, count: height*width), count: chem_cols.count)
        var dst = src
        for i in 0..<chem_cols.count {
            var key = 0
            for y in 0 ..< height {
                for x in 0 ..< width {
                    src[i][key] = Float(values[x,y].concs[i])
                    key += 1
                }
            }
        }
        
        // kernel https://math.stackexchange.com/questions/3464125/how-was-the-2d-discrete-laplacian-matrix-calculated
        let kernel: [Float] = [
            1,  4,  1,
            4, -20, 4,
            1,  4,  1
        ].map { $0 * 0.1667 }
        let v_height = vImagePixelCount(height)
        let v_width = vImagePixelCount(width)
        let row_bytes = width * MemoryLayout<Float>.stride
        
        kernel.withUnsafeBufferPointer { kernel_ptr in
            for i in 0..<chem_cols.count {
                src[i].withUnsafeMutableBufferPointer { src_ptr in
                    dst[i].withUnsafeMutableBufferPointer { dst_ptr in
                        var src_buffer = vImage_Buffer(
                            data: src_ptr.baseAddress!,
                            height: v_height,
                            width: v_width,
                            rowBytes: row_bytes
                        )
                        
                        var dst_buffer = vImage_Buffer(
                            data: dst_ptr.baseAddress!,
                            height: v_height,
                            width: v_width,
                            rowBytes: row_bytes
                        )
                        
                        let _ = vImageConvolve_PlanarF(&src_buffer, &dst_buffer, nil, 0, 0, kernel_ptr.baseAddress!, 3, 3, 0, vImage_Flags(kvImageEdgeExtend)
                        )
                    }
                }
            }
        }
        
        var newGrid = Grid(height: height, width: width, num_chems: chem_cols.count)
        for y in 0..<height {
            let yw = y * width
            for x in 0..<width {
                let key = yw + x
                for i in 0..<chem_cols.count {
                    newGrid[x, y].concs[i] = max(0.0, Num(src[i][key] + dst[i][key] * Ddt[i]))
                }
            }
        }
        
        return newGrid
    }

    
    func diffusionOLD() -> Grid {
        let zeros = [Num](repeating: 0.0, count: chem_cols.count)
        var new_values = values
        var lap = zeros
        let Ddt = diffusion_consts.map {$0 * dt}
        
        for y in 1 ..< height-1 { // ignore the edges
            for x in 1 ..< width-1 {
                
                // Laplacian, using h = 1
                lap = zeros
                for i in 0..<chem_cols.count {
                    // kernel https://math.stackexchange.com/questions/3464125/how-was-the-2d-discrete-laplacian-matrix-calculated
                    lap[i] = 0.1666 * ( 4 * (values[x-1,y].concs[i] + values[x+1,y].concs[i] + values[x,y-1].concs[i] + values[x,y+1].concs[i]) + (values[x-1,y-1].concs[i] + values[x+1,y+1].concs[i] + values[x+1,y-1].concs[i] + values[x-1,y+1].concs[i]) - 20 * values[x,y].concs[i] )
                }
                
                for i in 0..<chem_cols.count {
                    new_values[x,y].concs[i] += lap[i] * Ddt[i]
                    if new_values[x,y].concs[i] < 0 {
                        print("WARNING, DIFFUSION WOULD GIVE NEGATIVE \(new_values[x,y].concs[i]-lap[i] * Ddt[i]) + \(lap[i]) * \(Ddt[i])")
                        new_values[x,y].concs[i] = 0
                    }
                }
            }
        }
        return new_values
    }
    
    
    // Reaction functions
    
    func reaction() -> Grid {
        var new_values = values
        var results = [Num].init(repeating: 0.0, count: chem_cols.count)
        
        
        for (f_i, f) in reaction_funcs.enumerated() {
            // Test for which chems f(x)=0 so those can be skipped:
            let chem_idxs = chem_idxs_all[f_i] // skip chemicals where LHS coeff = RHS coeff.
            if chem_idxs.isEmpty { continue } // if rate=0, f(x)=0 so no reactions/changes needed
            
            for x in 0 ..< width {
                for y in 0 ..< height {
                    let concs = values[x,y].concs
                    let f_val = f(concs)
                    var is_positive = true
                    results = new_values[x,y].concs
                    for i in chem_idxs {
                        results[i] += f_val[i] * dt
                        if results[i] < 0 {
                            is_positive = false
                            break // can't react if it would make a negative so skip the reaction.
                        }
                    }
                    if is_positive {
                        new_values[x,y].concs = results
                    }
                }
            }
        }
        return new_values
    }
    
    
    func reactionHARDCODED() -> Grid {
        let rates: [Num] = [0.5, 0.03, 0.1]
        func expr1(_ a: Num, _ b: Num, _ p: Num) -> Num { return -rates[0] * a*b*b + rates[1] * pow(b, 3) }
        func expr2(_ a: Num, _ b: Num, _ p: Num) -> Num { return -rates[2] * b }
        var new_values = values
        var concs: [Num]
        var val1: Num
        var val2: Num
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
    
    @inlinable
    subscript(x: Int, y: Int) -> Cell {
        get { return values[(y * width) + x] }
        set { values[(y * width) + x] = newValue }
    }
    
    init(height: Int, width: Int, num_chems: Int) {
        let cell = Cell(concs: [Num](repeating: 0.0, count: num_chems))
        self.values = [Cell](repeating: cell, count: Int(height * width))
        self.height = height
        self.width = width
    }
}

struct Cell {
    var concs: [Num]
}

typealias Num = Double
