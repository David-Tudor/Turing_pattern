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
    var num_chems: Int
    var values: Grid
    var is_running = false
    var background_col: Colour // if white (255,...), cym used, else rgb or specified colours
    var dt: Double
    var diffusion_consts: [Double] = []
    var reaction_funcs: [ ([Double]) -> [Double] ]
    var sources: [[Int]:[Double]] = [:] // dict with coord keys and chem change values. sponge if negative (impossible value)
    var eqn_coeffs_list: [[[Int]]]
    var rate_list: [[Double]]
    
    
    var test_concs: [Double] {
        [Double].init(repeating: 1.0, count: num_chems)
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
            for j in 0..<num_chems where test_results_all[i][j] {
                ans[i].append(j)
            }
        }
        return ans
    }
    
    init(height: Int, width: Int, chem_cols: [Colour], dt: Double, background_col_enum: Colour_enum, chems: [String], equation_list: [String], rate_list: [[Double]]) {
        self.height = height
        self.width = width
        self.dt = dt
        self.values = Grid(height: height, width: width, num_chems: chem_cols.count)
        self.background_col = rgb_for(col: background_col_enum)
        self.chem_cols = []
        self.reaction_funcs = make_reaction_functions(chems: chems, equation_list: equation_list, rate_list: rate_list)
        self.num_chems = chem_cols.count
        self.eqn_coeffs_list = make_eqn_coeffs_list(chems: chems, equation_list: equation_list)
        self.rate_list = rate_list
    }
    
    mutating func time_step() {
//        values = diffusion(values)
//        values = reaction(values)
        values = reactionSIMD(values)
        if sources != [:] { values = source_calc() }
    }
    
    func export_to_view() -> some View {
        let background_pixel = make_PixelData(rgb: background_col)
        var pixel_data = [PixelData](repeating: background_pixel, count: Int(height * width))
        
        for x in 0 ..< width {
            for y in 0 ..< height {
                if values[x,y].concs.allSatisfy({$0 == 0.0}) {
                    pixel_data[(y * width) + x] = background_pixel
                    
                } else if num_chems <= 3 {
                    pixel_data[(y * width) + x] = make_PixelData(rgb: concs_to_colours(concs: values[x,y].concs))
                    
                } else {
                    // show most concentrated chemical
                    guard let i = find_idx_of_max(of: values[x,y].concs) else {
                        continue // pixel is left as background if all concs are zero
                    }
                    pixel_data[(y * width) + x] = make_PixelData(rgb: chem_cols[i])
                }
            }
        }
        
        let cgimage = pixeldata_to_image(pixels: pixel_data, width: width, height: height)
        return Image(cgimage, scale: 1, label: Text(""))
    }
    
    func concs_to_colours(concs: [Double]) -> Colour {
        // returns a rgb or cym Colour. concs of different chemicals change independent channels (so assumes <= 3 concs)
        var c: Double = 0.0
        
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
            let dbl = 255 * c/(c+0.1)
            let b = dbl.isNaN
            col[i] += sign * (b ? 1 : Int(dbl))
            if b {print("ERROR INF COLOUR: c was \(c)")}
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
        sources = [:]
        values = Grid(height: height, width: width, num_chems: num_chems)
        
    }
    
    // Diffusion functions
    
    func diffusion(_ my_values: Grid) -> Grid {
        let Ddts = diffusion_consts.map{Float($0 * dt)}
        var src = [[Float]].init(repeating: [Float].init(repeating: 0.0, count: height*width), count: num_chems)
        var dst = src
        for i in 0..<num_chems {
            var key = 0
            for y in 0 ..< height {
                for x in 0 ..< width {
                    src[i][key] = Float(my_values[x,y].concs[i])
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
            for i in 0..<num_chems {
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
        
        var new_values = Grid(height: height, width: width, num_chems: num_chems)
        for y in 0..<height {
            let yw = y * width
            for x in 0..<width {
                let key = yw + x
                for i in 0..<num_chems {
                    new_values[x, y].concs[i] = max(0.0, Double(src[i][key] + dst[i][key] * Ddts[i]))
                }
            }
        }
    
        return new_values
    }

    
    func diffusionOLD(_ my_values: Grid) -> Grid {
//        let zeros = [Double](repeating: 0.0, count: num_chems)
        var new_values = my_values
//        var lap = zeros
        let Ddts = diffusion_consts.map{$0 * dt}
        
        for y in 1 ..< height-1 { // ignore the edges
            for x in 1 ..< width-1 {
                
                // Laplacian, using h = 1
//                lap = zeros
                for i in 0..<num_chems {
                    // kernel https://math.stackexchange.com/questions/3464125/how-was-the-2d-discrete-laplacian-matrix-calculated
                    let lap = 0.1666 * ( 4 * (my_values[x-1,y].concs[i] + my_values[x+1,y].concs[i] + my_values[x,y-1].concs[i] + my_values[x,y+1].concs[i]) + (my_values[x-1,y-1].concs[i] + my_values[x+1,y+1].concs[i] + my_values[x+1,y-1].concs[i] + my_values[x-1,y+1].concs[i]) - 20 * my_values[x,y].concs[i] )
                    
                    new_values[x,y].concs[i] = max(0.0, new_values[x,y].concs[i] + lap * Ddts[i])
                }
            }
        }
        return new_values
    }
    
    
    // Reaction functions
    
    func reaction(_ my_values: Grid) -> Grid {
        // AWKWARD TO MAKE RK4 GIVEN SOME REACTIONS DONT HAPPEN IF NEGATIVE, run reaction per functions?
        var new_values = my_values
        var results = [Double].init(repeating: 0.0, count: num_chems)
        
        for (f_i, f) in reaction_funcs.enumerated() {
            // Test for which chems f(x)=0 so those can be skipped:
            let chem_idxs = chem_idxs_all[f_i] // skip chemicals where LHS coeff = RHS coeff.
            if chem_idxs.isEmpty { continue } // if rate=0, f(x)=0 so no reactions/changes needed
            
            for x in 0 ..< width {
                for y in 0 ..< height {
                    let concs = my_values[x,y].concs
                    let f_val = f(concs)
                    var is_positive = true
                    
                    results = new_values[x,y].concs
                    for i in chem_idxs {
                        results[i] += f_val[i] * dt / (1+concs[i]*concs[i])
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
    
    
    func reactionHARDCODED(_ my_values: Grid) -> Grid {
        let rates: [Double] = [0.5, 0.03, 0.1]
        func expr1(_ a: Double, _ b: Double, _ p: Double) -> Double { return -rates[0] * a*b*b + rates[1] * b*b*b }
        func expr2(_ a: Double, _ b: Double, _ p: Double) -> Double { return -rates[2] * b }
        var new_values = values
        var concs: [Double]
        var val1: Double
        var val2: Double
        for x in 0 ..< width {
            for y in 0 ..< height { // can't use a matrix as not linear e.g. in b. what else?
                concs = my_values[x,y].concs
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
    
    func powSIMD(_ x: SIMD64<Double>, _ n: Int) -> SIMD64<Double> {
        switch n {
        case 0: return SIMD64(repeating: 1.0)
        case 1: return x
        case 2: return x * x
        case 3: return x * x * x
        case 4: let x2 = x * x; return x2 * x2
        default:
            var ans = x
            for _ in 0..<n-1 { ans *= x }
            return ans
        }
    }
    
    func reactionSIMD(_ my_values: Grid) -> Grid {
        var new_values = my_values
        
        for (eqn_i, eqn_coeffs) in eqn_coeffs_list.enumerated() {
            new_values = react(new_values, eqn_coeffs[0], eqn_coeffs[1], rate_list[eqn_i][0])
            new_values = react(new_values, eqn_coeffs[1], eqn_coeffs[0], rate_list[eqn_i][1])
        }
        print("there are \(eqn_coeffs_list.count * 2) calls")
        return new_values
    }
    
    func react(_ my_values: Grid, _ lhs_coeffs: [Int], _ rhs_coeffs: [Int], _ k: Double) -> Grid {
        if k == 0.0 { return my_values } // test if skip available
        
        var new_values = my_values
        let num_cells = width*height
        let diffs = zip(lhs_coeffs, rhs_coeffs).map{Double($1-$0)}
        let stride = 64

        let val_init = k * dt
        let V_init = SIMD64(repeating: val_init)
        let zero_vec = SIMD64(repeating: 0.0)
        let zero_vecs = [SIMD64<Double>].init(repeating: zero_vec, count: num_chems)
        
        let clock = ContinuousClock()
        var time: Duration = .seconds(0)
        
        var cell_i = 0
        while cell_i < num_cells {
            var vec_store = zero_vecs
            let is_not_near_end = (cell_i+stride-1 < num_cells)
            
            var term = V_init
            for chem_i in 0..<num_chems {
                // get concs and ensure they exist, else 0.
                
                    var vec = zero_vec
                    if is_not_near_end {
                        for i in 0..<stride {
                            vec[i] = my_values[cell_i+i].concs[chem_i]
                        }
                    } else {
                        for i in 0..<(num_cells-cell_i) {
                            vec[i] = my_values[cell_i+i].concs[chem_i]
                        } // relies on temp init'd to zero
                    }
                    
                    vec_store[chem_i] = vec
                    term *= powSIMD(vec, lhs_coeffs[chem_i])
            }
            
            time += clock.measure {
                for chem_i in 0..<num_chems {
                    let new_values_V = vec_store[chem_i] + diffs[chem_i] * term // vec_store should be newvals? div by 1+c^2?
                    if new_values_V.min() < 0 { continue }
                    
                    if is_not_near_end {
                        for i in 0..<stride {
                            new_values[cell_i+i].concs[chem_i] = Double(new_values_V[i])
                        }
                    } else {
                        for i in 0..<(num_cells-cell_i) {
                            new_values[cell_i+i].concs[chem_i] = Double(new_values_V[i])
                        }
                    }
                }
            }
            cell_i += stride
        }
        print(duration_to_dbl(time))
        return new_values
    }
    
    // Painting
    
    mutating func paint(chemical chem_i: Int?, around position: [Int], diameter: Double, amount: Double, shape: Brush_shape, is_source: Bool, brush_density: Double) {
        // if chem_i == nil, sponge up chemicals, else add the chosen one.
        let coords = get_coords(diameter: diameter, ring_fraction: 0.8, shape: shape, density: brush_density)
        let d2 = (diameter*diameter)*0.1
        let zeros = [Double].init(repeating: 0.0, count: num_chems)
        let negatives = [Double].init(repeating: -1.0, count: num_chems) // a negative source will be a sponge sink
        
        for xy in coords {
            let x = xy[0] + position[0]
            let y = xy[1] + position[1]
            if is_point_valid(x, y) {
                // add to value directly
                if let chemical = chem_i  {
                    values[x, y].concs[chemical] += (shape != .gaussian) ? amount : amount * exp(-Double(xy[0]*xy[0] + xy[1]*xy[1])/d2) // add chemical
                } else {
                    values[x, y].concs = [Double](repeating: 0.0, count: num_chems) // sponge
                }
                
                // option to also make a source/sink
                if is_source {
                    // run this 'if' block on each valid coordinate
                    let pos = [x,y]
                    if let chemical = chem_i {
                        // ensure dict key exists
                        if let _ = sources[pos] {} else {
                            sources[pos] = zeros
                        }

                        if (sources[pos]!.first! >= 0.0) {
                            sources[pos]![chemical] += (shape != .gaussian) ? amount : amount * exp(-Double(xy[0]*xy[0] + xy[1]*xy[1])/d2) // '!!' as we checked key exists and val exists
                        }
                    } else { sources[pos] = negatives }
                }
            }
        }
    }
    
    func source_calc() -> Grid {
        let zeros = [Double](repeating: 0.0, count: num_chems)
        var new_values = values
        
        for (pos, amt) in sources {
            let x = pos[0]
            let y = pos[1]
            if amt.first! >= 0.0 {
                new_values[x,y].concs = zip(new_values[x,y].concs, amt).map(+)
            } else {
                new_values[x,y].concs = zeros
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
    
    subscript(x: Int) -> Cell { // TODO USE THIS MORE
        get { return values[x] }
        set { values[x] = newValue }
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

typealias Num = Double
