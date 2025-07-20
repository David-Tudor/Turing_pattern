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
        chems = []
        var mem = ""
        for str in equation_list {
            for c in str {
                if c.isLetter { // add character to memory
                    mem += String(c)
                } else if !mem.isEmpty { // chemical finished, try apppend it
                    if !chems.contains(mem) { chems.append(mem) }
                    mem = ""
                }
            }
            if !mem.isEmpty && !chems.contains(mem) { chems.append(mem) }
            mem = ""
        }
    }
    
    func update_chem_cols() {
        if chems.count <= 3 && background_col_enum == .white { // CYM
            let default_cols = [rgb_for(col: .cyan), rgb_for(col: .yellow), rgb_for(col: .magenta)]
            self.chem_cols = Array(default_cols[0...chems.count-1])
        } else if chems.count <= 3 && background_col_enum != .white { // RGB
            let default_cols = [rgb_for(col: .red), rgb_for(col: .green), rgb_for(col: .blue)]
            self.chem_cols = Array(default_cols[0...max(chems.count-1, 0)])
        } else { // > 3 colours so take from colour picker
            self.chem_cols = chem_cols_picker
        }
        
    }
    
    
    func update_all() {
        update_chems()
        update_chem_cols()
    }
    
    func make_time_stepped_reactions() -> [ ([Double]) -> Double] {
        var data: Dictionary<String, Int> = [:] // dict key format: "<l or r><eqn #>_<chem name>"
        var ans: [ ([Double]) -> Double] = []
        for (i, eqn) in equation_list.enumerated() {
            let eqn_sides = eqn.replacingOccurrences(of: " ", with: "").split(separator: "z->")
            var lhs_dict = parse_eqn_side_to_dict(side_str: String(eqn_sides[0]), side: "l", i: i)
            let rhs_dict = parse_eqn_side_to_dict(side_str: String(eqn_sides[1]), side: "r", i: i)// MOVE INTO SINGLE FUNC CALL
            data.merge(lhs_dict) { (current, _) in current }
            data.merge(rhs_dict) { (current, _) in current }
        }
        
        for chem_i in 0..<chems.count {
            var f: ([Double]) -> Double
            
//            ans.append(f)
        }
        
        return ans
    }
    
//    func f(args: [[]]) {
//
//    }
    
    func parse_eqn_side_to_dict(side_str: String, side: String, i: Int) -> Dictionary<String, Int> {
        var dict: Dictionary<String, Int> = [:]
        
        for elems in side_str.split(separator: "+") {
            let my_chem = elems.filter({$0.isLetter})
            let coeff = Int(elems.filter({$0.isNumber})) ?? 1 // omitted coeff means a 1.
            print("in side parser, chem, coeff are \(my_chem), \(coeff) <- from \(elems.filter({$0.isNumber}))")
            let key = get_dict_key(side: side, i: i, chem: my_chem)
            if let val = dict[key] {
                dict[key] = val + coeff
            } else { dict[key] = coeff }
            
        }
        return dict
    }
    
    func get_dict_key(side: String, i: Int, chem: String) -> String {
        "\(side)\(i)_\(chem)"
    }
    
}

