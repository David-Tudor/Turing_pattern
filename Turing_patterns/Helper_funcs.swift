//
//  Helper_funcs.swift
//  Turing_patterns
//
//  Created by David Tudor on 05/07/2025.
//

import Foundation


func find_idx_of_max(of a: [Double]) -> Int? {
    assert(a.count >= 1)
    if a.allSatisfy({$0 == 0.0}) { return nil } // nil if all elements are zero
    
    var max = a[0]
    var maxi = 0
    for i in 0 ..< a.count {
        if a[i] > max {
            max = a[i]
            maxi = i
        }
    }
    return maxi
}

func get_integs_in_circle(diameter: Double) -> [[Int]] {
    let radius = diameter/2
    let r2 = radius * radius
    let range = -Int(radius) ... Int(radius)
    var coords: [[Int]] = []
    
    for x in range {
        for y in range {
            if Double(x*x + y*y) < r2 { coords.append([x,y]) }
        }
    }
    return coords
}

func get_integs_in_quarter_circle(radius: Double) -> [[Int]] {
    // positive quarter, and excludes (0,0)
    let r2 = radius * radius
    let range = 0 ... Int(radius)
    var coords: [[Int]] = []
    
    for x in range {
        for y in range {
            if x==0 && y==0 {continue}
            if Double(x*x + y*y) <= r2 { coords.append([x,y]) }
        }
    }
    return coords
}

func get_chems_from_eqns(from eqn_list: [String]) -> [String] {
    var chem_list: [String] = []
    var mem = ""
    for str in eqn_list {
        for c in str {
            if c.isLetter { // add character to memory
                mem += String(c)
            } else if !mem.isEmpty { // chemical finished, try apppend it
                if !chem_list.contains(mem) { chem_list.append(mem) }
                mem = ""
            }
        }
        if !mem.isEmpty && !chem_list.contains(mem) { chem_list.append(mem) }
        mem = ""
    }
    return chem_list
}
