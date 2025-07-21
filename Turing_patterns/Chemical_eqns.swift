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
    
    func toggle_sim_running() {
        DispatchQueue.main.async { self.is_sim_running = !self.is_sim_running }
    }
    
    func update_chems() {
        chems = get_chems_from_eqns(from: equation_list)
    }

    func update_all() {
        update_chems()
    }
    
    func make_eqn_coeffs_list() -> [[[Int]]] {
        // returns [ [eqn1 LHS coeffs, eqn1 RHS coeffs], [eqn2 LHS coeffs, eqn2 RHS coeffs], ...]
        // Size: #equations x 2 x #chemicals
        
        var eqn_coeffs_list = [[[Int]]].init(repeating: [[Int]].init(repeating: [Int].init(repeating: 0, count: chems.count), count: 2), count: equation_list.count)
        
        for (eqn_i, eqn) in equation_list.enumerated() {
            let eqn_sides = eqn.replacingOccurrences(of: " ", with: "").split(separator: "->") // removes white space and splits over "->"
            for side_i in 0...1 {
                for elem in eqn_sides[side_i].split(separator: "+") {
                    let my_chem = elem.filter({$0.isLetter})
                    let coeff = Int(elem.filter({$0.isNumber})) ?? 1 // omitted coeff means a 1.
                    if let chem_i = chems.firstIndex(of: my_chem) {
                        eqn_coeffs_list[eqn_i][side_i][chem_i] += coeff
                    } else { print("chemical \(my_chem) not found") }
                }
            }
        }
        return eqn_coeffs_list
    }
    
//    func make_reaction_functions() -> [([Double]) -> Double] {
//        // returns a list of functions, each giving the d/dt for each chemical. So yet to *dt
//        // !! SPLIT DIFFERENTLY TO BEWARE OF CHEMICALS
//        // THINK OF SIMD EARLY?
//
//    }
//    
}

