//
//  Helper_funcs.swift
//  Turing_patterns
//
//  Created by David Tudor on 05/07/2025.
//

import Foundation


func find_idx_of_max(of a: [Num]) -> Int? {
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

func get_coords(diameter: Double, ring_fraction: Double, shape: Brush_shape, density: Double) -> [[Int]] {
    let radius = diameter/2
    let r2 = radius * radius
    let range = -Int(radius) ... Int(radius)
    var ans: [[Int]] = []
    
    switch shape {
    case .circle, .gaussian:
        for x in range {
            let x2 = x*x
            for y in range {
                if (Double.random(in: 0...1) < density) && Double(x2 + y*y) < r2 { ans.append([x,y]) }
            }
        }
        
    case .square:
        for x in range {
            for y in range {
                if (Double.random(in: 0...1) < density) { ans.append([x,y]) }
            }
        }
        
    case .ring:
        let r_min2 = ring_fraction * ring_fraction * r2
        for x in range {
            for y in range {
                let x2y2 = Double(x*x + y*y)
                if (Double.random(in: 0...1) < density) && x2y2 < r2 && x2y2 >= r_min2 { ans.append([x,y]) }
            }
        }
    
    }
    return ans
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

func duration_to_dbl(_ duration: Duration) -> Double {
    Double(duration.components.attoseconds) * 1e-18 + Double(duration.components.seconds)
}
