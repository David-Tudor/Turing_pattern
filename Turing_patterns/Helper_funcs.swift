//
//  Helper_funcs.swift
//  Turing_patterns
//
//  Created by David Tudor on 05/07/2025.
//

import Foundation


func find_idx_of_max<T: Comparable>(of a: [T]) -> Int? {
    assert(a.count >= 1)
    if a.allSatisfy({$0 == a.first}) { return nil } // nil if all elements are equal
    
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

//func difference(a: [Double])
