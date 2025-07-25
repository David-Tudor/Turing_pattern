//
//  Chemical_eqns.swift
//  Turing_patterns
//
//  Created by David Tudor on 06/07/2025.
//

import Foundation
import SwiftUI

class Chemical_eqns: ObservableObject {
    @Published var equation_list: [String] = ["A + 2B -> 3B", "B -> P"]
    @Published var rate_list: [[Double]] = [[1.0, 0.1], [0.4, 0.0]]
    @Published var chems: [String] = ["A", "B", "P"]
    @Published var chem_cols: [Colour] = [rgb_for(col: .red), rgb_for(col: .green), rgb_for(col: .blue)]
    @Published var chem_cols_picker: [Colour] = []
    @Published var background_col_enum: Colour_enum = .black
    @Published var is_sim_running = false
    @Published var are_eqns_up_to_date = true
    @Published var D_strs: [String] = [String].init(repeating: "1.0", count: 3)
    
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
}

