//
//  Chemical_eqns.swift
//  Turing_patterns
//
//  Created by David Tudor on 06/07/2025.
//

import Foundation
import SwiftUI

class Chemical_eqns: ObservableObject {
    @Published var equation_list: [String]
    @Published var rate_list: [[Double]]
    @Published var target_strs: [[String]]
    @Published var chems: [String]
    @Published var D_strs: [String]
    @Published var chem_cols: [Colour]
    @Published var chem_cols_picker: [Colour] = []
    @Published var background_col_enum: Colour_enum
    @Published var is_sim_running = false
    @Published var are_eqns_up_to_date = true
    
    
    let D_default: Double = 0.1
    var diffusion_consts: [Double] {
        var ans: [Double] = []
        for s in D_strs {
            let d = Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
            ans.append(d ?? D_default)
        }
        return ans
    }
    
    let target_default = 0.0
    var chem_targets: [[Double]] { // TODO print in here shows it's called every timestep??
        var ans: [[Double]] = []
        for ss in target_strs {
            let d0 = Double(ss[0].trimmingCharacters(in: .whitespacesAndNewlines)) ?? target_default
            let d1 = parse_target_rate(ss[1])
            print("from \(ss), appending \([d0,d1])")
            ans.append([d0,d1])
        }
        return ans
    }
    
    func parse_target_rate(_ s: String) -> Double {
        if s.contains("+") {
            return s.split(separator: "+").reduce(0.0) { partialResult, ss in
                partialResult + (Double(ss.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0)
            }
        } else {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines)) ?? target_default
        }
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
        self.target_strs = preset.chem_targets.map{[$0[0].description, $0[1].description]}
        self.chems = preset.chems
        self.chem_cols = preset.chem_cols
        self.D_strs = preset.diffusion_consts.map{$0.description}
        self.background_col_enum = preset.background_col_enum
    }
}

