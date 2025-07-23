//
//  Reaction_func.swift
//  Turing_patterns
//
//  Created by David Tudor on 23/07/2025.
//

import Foundation

func make_eqn_coeffs_list(chems: [String], equation_list: [String]) -> [[[Int]]] {
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

func my_pow(_ x: Num, _ n: Int) -> Num {
    switch n {
    case 0: return 1
    case 1: return x
    case 2: return x * x
    case 3: return x * x * x
    case 4: let x2 = x * x; return x2 * x2
    default:
        var ans: Num = 1.0
        for _ in 0..<n { ans *= x }
        return ans
    }
}

func make_reaction_func(k: Num, lhs_chem_coeffs: [Int], rhs_chem_coeffs: [Int]) -> ([Num]) -> [Num] {
    // given an equation, returns: a function of the chem concs which returns the d/dt of each chemical
    let coeff_diffs = zip(lhs_chem_coeffs, rhs_chem_coeffs).map { (l,r) in Num(r-l) }
    
    return { concs in
        var term = k
        for (i, conc) in concs.enumerated() {
            term *= my_pow(conc, lhs_chem_coeffs[i])
        }
        return coeff_diffs.map { diff in diff * term }
    }
}

func make_reaction_functions(chems: [String], equation_list: [String], rate_list: [[Num]]) -> [ ([Num]) -> [Num] ] {
    // eqn_coeffs_list is [ [eqn1 LHS coeffs, eqn1 RHS coeffs], [eqn2 LHS coeffs, eqn2 RHS coeffs], ...]
    // based on N equations, returns 2N (-> and <- reactions) lists of funcs. These lists contain the funcs for the ith chemical.
    var reaction_funcs: [ ([Num]) -> [Num] ] = []
    let eqn_coeffs_list = make_eqn_coeffs_list(chems: chems, equation_list: equation_list)
    
    for eqn_i in 0..<eqn_coeffs_list.count {
        let ks = rate_list[eqn_i]
        let coeffs = eqn_coeffs_list[eqn_i]
        
        reaction_funcs.append(make_reaction_func(k: ks[0], lhs_chem_coeffs: coeffs[0], rhs_chem_coeffs: coeffs[1])) // '->' reaction
        reaction_funcs.append(make_reaction_func(k: ks[1], lhs_chem_coeffs: coeffs[1], rhs_chem_coeffs: coeffs[0])) // '<-' reaction
    }
    return reaction_funcs
}
