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
    @Published var are_equations_valid: [Bool] = [true, true]
    @Published var chems: [String] = ["A", "B", "P"]
    @Published var chem_cols: [Colour] = [rgb_for(col: .blue), rgb_for(col: .red), rgb_for(col: .green)]
    
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
        // xxx todo will need changing since we have colour picker.
        switch chem_cols.count {
        case 0: chem_cols = []
        case 1: chem_cols = [rgb_for(col: .blue)]
        case 2: chem_cols = [rgb_for(col: .blue), rgb_for(col: .red)]
        case 3: chem_cols = [rgb_for(col: .blue), rgb_for(col: .red), rgb_for(col: .green)]
        default:
            chem_cols = []
            print("CURRENTLY 3 COLS AVAILABLE")
        }
    }
    
    func update_eqns_valid() {
        var b: Bool
        var got_arrow: Bool
        var state: Eqn_state
        var new_arr: [Bool] = []
        for eqn in equation_list {
            b = true
            got_arrow = false
            state = .neutral
            for c in eqn {
                if c.isWhitespace { continue }
                // for different state, check then next character is allowable, else give b=false
                switch state {
                case .neutral:
                    if c.isLetter { state = .chem }
                    else if c.isNumber { state = .neutral }
                    else { b = false }
                case .arrow:
                    if c == ">" { state = .neutral }
                    else { b = false }
                case .chem:
                    if c == "-" { state = .arrow; got_arrow = true }
                    else if c == "+" { state = .neutral }
                    else if c.isLetter { state = .chem }
                    else { b = false }
                }
            }
            if state != .chem || got_arrow == false { b = false } // eqn must end with a chem and contain an arrow
            new_arr.append(b) // todo, could allow A -> nothing etc.
        }
        are_equations_valid = new_arr
    }
    
    func update_all() {
        update_chems()
        update_chem_cols()
        update_eqns_valid()
    }
    
    func make_time_stepped_reactions() -> [ ([Double]) -> Double] {
        var data: Dictionary<String, Int> = [:] // keys: "<l or r><eqn #>_<chem name>"
        var ans: [ ([Double]) -> Double] = []
        for (i, eqn) in equation_list.enumerated() {
            let eqn_sides = eqn.replacingOccurrences(of: " ", with: "").split(separator: "z->")
            var lhs_dict = parse_eqn_side_to_dict(side_str: String(eqn_sides[0]), side: "l", i: i)
            let rhs_dict = parse_eqn_side_to_dict(side_str: String(eqn_sides[1]), side: "r", i: i)
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
            let coeff = Int(elems.filter({$0.isNumber})) ?? 1
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

enum Eqn_state { // used for checking an inputed chemical equation is valid.
    case chem
    case arrow
    case neutral // can be number or letter
}

