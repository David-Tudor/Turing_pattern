//
//  Chemical_eqns.swift
//  Turing_patterns
//
//  Created by David Tudor on 06/07/2025.
//

import Foundation
import SwiftUI

class Chemical_eqns: ObservableObject {
    @Published var equation_list: [String] = []
    @Published var rate_list: [[Double]] = []
    @Published var chems: [String] = []
    @Published var chem_cols: [Colour] = []
    @Published var chem_cols_picker: [Colour] = []
    @Published var D_strs: [String] = []
    @Published var background_col_enum: Colour_enum
    @Published var is_sim_running = false
    @Published var are_eqns_up_to_date = true
    
    
    let D_default: Double = 1.0
    var diffusion_consts: [Double] {
        var ans: [Double] = []
        for s in D_strs {
            let d = Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
            ans.append(d ?? D_default)
        }
        return ans
    }
    
    func toggle_sim_running() {
        DispatchQueue.main.async { self.is_sim_running = !self.is_sim_running } // delays - prevents a view update while resolving modifiers.
    }
    
    func update_chems() {
        chems = get_chems_from_eqns(from: equation_list)
    }

    func update_all() { // change
        update_chems()
    }
    
    init() {
        let preset = Preset()
        self.equation_list = preset.equation_list
        self.rate_list = preset.rate_list
        self.chems = preset.chems
        self.chem_cols = preset.chem_cols
        self.D_strs = preset.diffusion_consts.map{$0.description}
        self.background_col_enum = preset.background_col_enum
    }
}

