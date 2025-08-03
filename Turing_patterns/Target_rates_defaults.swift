//
//  Target_rates_defaults.swift
//  Turing_patterns
//
//  Created by David Tudor on 03/08/2025.
//

import Foundation

class Target_rates_defaults {
    // values from https://www.youtube.com/watch?v=nIGgK9wv_eg
    private let data: [Target_rates_obj] = [
        Target_rates_obj(name: "coral", k: 0.062, f: 0.055),
        Target_rates_obj(name: "mitosis", k: 0.058, f: 0.021),
        Target_rates_obj(name: "1pulse", k:0.05542, f:0.01887),
    ]

    var i: Int = 0
    var idx: Int {i % data.count}
    var name: String {data[idx].name}
    var a_rate: Double {data[idx].f}
    var b_rate: Double {data[idx].f + data[idx].k}
}

private struct Target_rates_obj {
    let name: String
    let k: Double
    let f: Double
}
