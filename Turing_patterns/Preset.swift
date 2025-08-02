//
//  Preset.swift
//  Turing_patterns
//
//  Created by David Tudor on 02/08/2025.
//

import Foundation

struct Preset {
    // Note, these values must be consistent
    let equation_list: [String] = ["A + 2B -> 3B"]
    let rate_list: [[Double]] = [[1.0, 0.1]]
    let diffusion_consts: [Double] = [0.16, 0.08]
    let chem_targets: [[Double]] = [[1.0, 0.03], [0.0, 0.09]]
    let chem_cols = [rgb_for(col: .red), rgb_for(col: .green)]
    
    // rate_list contains 2 rates of reaction for each equation - forwards rate and backwards rate.
    // chem_targets contains 2 values for each chemical - the target concentration, and the rate it is approached at.
    // chem_cols contains [Int] rgb values for each chemical
    
    let background_col_enum: Colour_enum = .black
    let sim_size = [150, 150]
    let dt_default: Double = 0.1
    
    var chems: [String] {
        get_chems_from_eqns(from: equation_list)
    }
    
    var num_chems: Int {
        chems.count
    }
    
    var num_eqns: Int {
        equation_list.count
    }
    
}
