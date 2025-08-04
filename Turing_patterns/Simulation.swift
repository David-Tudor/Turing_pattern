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
    let image_scale: Double
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
    var equation_list: [String]
    var rate_list: [[Double]]
    var chem_targets_flat: [Double]
    var chem_idxs_all: [[Int]]
    let can_use_hardcoded_reaction: Bool
    let reaction_method_general: Reaction_method
    
    // kernel https://math.stackexchange.com/questions/3464125/how-was-the-2d-discrete-laplacian-matrix-calculated
    let laplacian_kernel: [Float] = [
        1,  4,  1,
        4, -20, 4,
        1,  4,  1
    ].map { $0 * 0.1667 }
    
    init(height: Int, width: Int, chem_cols: [Colour], dt: Double, background_col_enum: Colour_enum, chems: [String], equation_list: [String], rate_list: [[Double]], chem_targets: [[Double]]) {
        self.height = height
        self.width = width
        self.dt = dt
        let preset = Preset()
        self.values = Grid(height: height, width: width, num_chems: chem_cols.count, init_concs: preset.init_concs)
        self.background_col = rgb_for(col: background_col_enum)
        self.chem_cols = []
        self.reaction_funcs = make_reaction_functions(chems: chems, equation_list: equation_list, rate_list: rate_list)
        self.num_chems = chems.count
        self.eqn_coeffs_list = make_eqn_coeffs_list(chems: chems, equation_list: equation_list)
        self.equation_list = equation_list
        self.rate_list = rate_list
        self.chem_targets_flat = chem_targets.flatMap{$0}
        self.chem_idxs_all = calc_chem_idxs_all(num_chems: num_chems, reaction_funcs: reaction_funcs)
        self.image_scale = preset.image_scale
        self.can_use_hardcoded_reaction = (preset.reaction_method == .normal_or_hardcoded || preset.reaction_method == .SIMD_or_hardcoded)
        self.reaction_method_general = (preset.reaction_method == .SIMD || preset.reaction_method == .SIMD_or_hardcoded) ? .SIMD : .normal
    }
    
    
    mutating func time_step() {
        let my_dt = 1.0
        let should_use_hardcoded_reaction =
        can_use_hardcoded_reaction &&
        (equation_list.count == 1) &&
        (equation_list.first?.replacingOccurrences(of: " ", with: "") == "A+2B->3B") && (rate_list[0][1] == 0.0)
        
//        let steps_per_call = should_use_hardcoded_reaction ? 6 : 4
        let steps_per_call = 8
        
        for _ in 0..<steps_per_call {
            let start_vals = values
            values = diffusion(values, my_dt) // calc FIRST so start_values not needed.
            if sources != [:] { values = source_calc(values, start_vals) }
            
            if should_use_hardcoded_reaction {
                values = reactionHARDCODED(values, start_vals, my_dt) // This INCLUDES its own targets_calc
            } else {
                if reaction_method_general == .SIMD { values = reactionSIMD(values, start_vals, my_dt) }
                else { values = reaction(values, start_vals, my_dt) }
                
                values = targets_calc(values, start_vals, my_dt)
            }
        }
    }
    
    func export_to_view() -> some View {
        let background_pixel = make_PixelData(rgb: background_col)
        var pixel_data = [PixelData](repeating: background_pixel, count: Int(height * width))
        
        for xy in 0 ..< width*height {
            if values[xy].allSatisfy({$0 == 0.0}) {
                pixel_data[xy] = background_pixel
                
            } else if num_chems <= 3 {
                pixel_data[xy] = make_PixelData(rgb: concs_to_colours(concs: values[xy]))
                
            } else {
                // show most concentrated chemical
                guard let i = find_idx_of_max(of: values[xy]) else {
                    continue // pixel is left as background if all concs are zero
                }
                pixel_data[xy] = make_PixelData(rgb: chem_cols[i])
            }
            
        }
        
        let cgimage = pixeldata_to_image(pixels: pixel_data, width: width, height: height)
        return Image(cgimage, scale: 1, label: Text("")).scaleEffect(image_scale)
    }
    
    func concs_to_colours(concs: [Double]) -> Colour {
        // returns a rgb or cym Colour. concs of different chemicals change independent channels (so assumes <= 3 concs)
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
            let c = concs[i]
            // let dbl = 255 * c/(c+0.1)
            let dbl = min(255, 255 * c) // TODO MULT 2nd 255 by 1.1 breaks it?
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
        let preset = Preset()
        values = Grid(height: height, width: width, num_chems: chem_cols.count, init_concs: preset.init_concs)
    }
    
    // Diffusion function
    
    func diffusion(_ my_values: Grid, _ my_dt: Double) -> Grid {
        var src = [[Float]].init(repeating: [Float].init(repeating: 0.0, count: height*width), count: num_chems)
        var dst = src
        for i in 0..<num_chems {
            for xy in 0 ..< width*height {
                src[i][xy] = Float(my_values[xy][i])
            }
        }
        
        let v_height = vImagePixelCount(height)
        let v_width = vImagePixelCount(width)
        let row_bytes = width * MemoryLayout<Float>.stride
        
        laplacian_kernel.withUnsafeBufferPointer { kernel_ptr in
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
        for i in 0..<num_chems {
            let s = src[i]
            let d = dst[i]
            let Ddt = Float(diffusion_consts[i] * my_dt)
            for xy in 0 ..< width*height {
                new_values[xy][i] = max(0.0, Double(s[xy] + d[xy] * Ddt))
            }
        }
        return new_values
    }
    
    // Reaction functions
    
    func reaction(_ my_values: Grid, _ start_values: Grid, _ my_dt: Double) -> Grid {
        // AWKWARD TO MAKE RK4 GIVEN SOME REACTIONS DONT HAPPEN IF NEGATIVE, run reaction per functions? - main problem is then i need to return changes not results.
        var new_values = my_values
        var results = [Double].init(repeating: 0.0, count: num_chems)
        
        for (f_i, f) in reaction_funcs.enumerated() {
            // Test for which chems f(x)=0 so those can be skipped:
            let chem_idxs = chem_idxs_all[f_i] // skip chemicals where LHS coeff = RHS coeff.
            if chem_idxs.isEmpty { continue } // if rate=0, f(x)=0 so no reactions/changes needed
            for xy in 0 ..< width*height {
                let concs = start_values[xy]
                let f_val = f(concs)
                var is_positive = true
                
                results = new_values[xy]
                for i in chem_idxs {
                    results[i] += f_val[i] * my_dt
                    if results[i] < 0 {
                        is_positive = false
                        break // can't react if it would make a negative so skip the reaction.
                    }
                }
                if is_positive {
                    new_values[xy] = results
                }
            }
        }
        return new_values
    }
    
    func expr1_reactionHard(_ a: Double, _ b: Double) -> Double { return -rate_list[0][0]*a*b*b }
    func expr2_reactionHard(_ a: Double) -> Double { return chem_targets_flat[1] * (chem_targets_flat[0]-a) }
    func expr3_reactionHard(_ b: Double) -> Double { return chem_targets_flat[3] * (chem_targets_flat[2]-b) }
    
    func reactionHARDCODED(_ my_values: Grid, _ start_values: Grid, _ my_dt: Double) -> Grid {
        // reaction is hardcoded (A+2B->3B), but coeffs can still be changed
        
        var new_values = my_values
        var concs: [Double]
        for xy in 0 ..< width*height {
            concs = start_values[xy]
            
            let val1 = expr1_reactionHard(concs[0], concs[1]) * my_dt
            let val2 = expr2_reactionHard(concs[0]) * my_dt
            let val3 = expr3_reactionHard(concs[1]) * my_dt
            if new_values[xy][0] > -val1 && new_values[xy][1] > val1 { // only react if concs will stay positive
                new_values[xy][0] +=  val1
                new_values[xy][1] += -val1
            }
            
            // expr2 and expr3 are targets of each chem.
            if new_values[xy][0] > -val2 {
                new_values[xy][0] +=  val2
            }
            if new_values[xy][1] > -val3 {
                new_values[xy][1] +=  val3
            }
        }
        return new_values
    }

    func reactionSIMD(_ my_values: Grid, _ start_values: Grid, _ my_dt: Double) -> Grid {
        var new_values = my_values
        let num_cells = width*height
        let stride = 64
        let zero_chems = [Double].init(repeating: 0.0, count: num_chems)
        let zero_vec = SIMD64(repeating: 0.0)
        let zero_vecs = [SIMD64<Double>].init(repeating: zero_vec, count: num_chems)
        var vec_store = zero_vecs
        
        //  loop through all cells, finding change from each func per one.
        var cell_i = 0
        while cell_i < num_cells {
            let cell_range = 0..<min(stride, (num_cells-cell_i) )
            
            // fill vec_store with 64 concs per chemical
            for chem_i in 0..<num_chems {
                var vec = zero_vec
                    for i in cell_range {
                        vec[i] = start_values[cell_i+i][chem_i]
                    }
                vec_store[chem_i] = vec
            }
            
            var changes = zero_vecs
            for (eqn_i, eqn_coeffs) in eqn_coeffs_list.enumerated() {
                let lhs_coeffs = eqn_coeffs[0]
                let rhs_coeffs = eqn_coeffs[1]
                let ks = rate_list[eqn_i]
                let term = calc_reaction_termSIMD(vec_store, lhs_coeffs, ks[0]*my_dt) - calc_reaction_termSIMD(vec_store, rhs_coeffs, ks[1]*my_dt)
                
                let diffs = zip(lhs_coeffs, rhs_coeffs).map{Double($1-$0)}
                for chem_i in 0..<num_chems {
                    changes[chem_i] += diffs[chem_i] * term
                }
            }
            
            for i in cell_range {
                var is_positive_reaction = true
                var results = zero_chems
                for chem_i in 0..<num_chems {
                    results[chem_i] = new_values[cell_i+i][chem_i] + Double(changes[chem_i][i])
                    if results[chem_i] < 0 {
                        is_positive_reaction = false
                        break
                    }
                }
                if is_positive_reaction {
                    new_values[cell_i+i] = results
                }
            }
            cell_i += stride
        }
        return new_values
    }
    
    func calc_reaction_termSIMD(_ vec_store: [SIMD64<Double>], _ coeffs: [Int], _ kdt: Double) -> SIMD64<Double> {
        if kdt == 0.0 { return SIMD64<Double>.init(repeating: 0.0) }
        var term = SIMD64<Double>.init(repeating: kdt)
        for chem_i in 0..<num_chems {
            term *= powSIMD(vec_store[chem_i], coeffs[chem_i])
        }
        return term
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
    
    // Painting
    
    mutating func paint(chemical chem_i: Int?, around position: [Int], diameter: Double, amount: Double, shape: Brush_shape, is_source: Bool, brush_density: Double) {
        // if chem_i is nil, sponge up chemicals, else add the chosen one.
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
                    values[x, y][chemical] += (shape != .gaussian) ? amount : amount * exp(-Double(xy[0]*xy[0] + xy[1]*xy[1])/d2) // add chemical
                } else {
                    values[x, y] = [Double](repeating: 0.0, count: num_chems) // sponge
                }
                
                // option to also make a source/sink
                if is_source {
                    // run this 'if' block on each valid coordinate
                    let pos = [x,y]
                    if let chemical = chem_i {
                        if let _ = sources[pos] {} else { // create a zero entry if key isn't in the dict already
                            sources[pos] = zeros
                        }
                        
                        if !is_source_pos_already_a_sink(sources[pos]!) {
                            sources[pos]![chemical] += (shape != .gaussian) ? amount : amount * exp(-Double(xy[0]*xy[0] + xy[1]*xy[1])/d2) // force unwrap as we checked key exists and val exists
                        }
                    } else { sources[pos] = negatives }
                }
            }
        }
    }
    
    func is_source_pos_already_a_sink(_ source_val: [Double]) -> Bool {
        // assumes the key exists!
        (source_val.first! < 0.0) // if a sink, all entries would be negative
    }
    
    func source_calc(_ my_values: Grid, _ start_values: Grid) -> Grid {
        // adds a set amout of chemical at the source positions, or sponges it all up.
        let zeros = [Double](repeating: 0.0, count: num_chems)
        var new_values = my_values
        
        for (pos, amt) in sources {
            let x = pos[0]
            let y = pos[1]
            if !is_source_pos_already_a_sink(amt) {
                new_values[x,y] = zip(start_values[x,y], amt).map(+)
            } else {
                new_values[x,y] = zeros
            }
        }
        return new_values
    }
    
    func targets_calc(_ my_values: Grid, _ start_values: Grid, _ my_dt: Double) -> Grid {
        // each chemical 'x' tends towards a target 't' at a rate 'k': dx/dt = k(t-x)
        var new_values = my_values
        for xy in 0 ..< width*height {
            for chem_i in 0..<num_chems {
                let two_chem_i = 2*chem_i
                let change = chem_targets_flat[two_chem_i+1] * (chem_targets_flat[two_chem_i] - start_values[xy][chem_i]) * my_dt
                if new_values[xy][chem_i] > -change {
                    new_values[xy][chem_i] += change
                }
            }
        }
        return new_values
    }
    
}

struct Grid {
    var values: [[Double]]
    let height: Int
    let width: Int
    
    @inlinable
    subscript(x: Int, y: Int) -> [Double] {
        get { return values[(y * width) + x] }
        set { values[(y * width) + x] = newValue }
    }
    
    subscript(x: Int) -> [Double] {
        get { return values[x] }
        set { values[x] = newValue }
    }
    
    init(height: Int, width: Int, num_chems: Int, init_concs: [Double]? = nil) {
        self.values = [[Double]](repeating: (init_concs ?? [Double](repeating: 0.0, count: num_chems)), count: Int(height * width))
        self.height = height
        self.width = width
    }
}

enum Reaction_method {
    // normal/SIMD take general equations whereas hardcoded looks for A+2B->3B
    // normal loops through each x,y whereas SIMD calculates blocks of 64.
    case normal_or_hardcoded
    case SIMD_or_hardcoded
    case normal
    case SIMD
}
