//
//  Equation_view.swift
//  Turing_patterns
//
//  Created by David Tudor on 12/07/2025.
//

import Foundation
import SwiftUI

struct Equation_view: View {
    @EnvironmentObject var chemicals: Chemical_eqns
    
    @State var rate_str_list: [[String]]
    @State var eqn_list_local: [String] = []
    @State var are_equations_valid: [Bool]
    @State var are_rates_valid: [Bool]
    @State var has_excess_chemicals = false
    
    var are_values_invalid: Bool {
        are_equations_valid.contains(false) || are_rates_valid.contains(false)
    }

    let eqn_field_length: CGFloat = 150
    let eqn_length: CGFloat = 300
    let max_chems = 8 // disabled. Enable in update_eqns_valid()
    
    init() {
        let preset = Preset()
        self.rate_str_list = [[String]].init(repeating: ["0.0", "0.0"], count: preset.num_eqns)
        self.are_equations_valid = [Bool].init(repeating: true, count: preset.num_eqns)
        self.are_rates_valid = [Bool].init(repeating: true, count: preset.num_eqns)
    }
    
    func update_eqns_valid() {
// Max number of chems is currently disabled:
//        if get_chems_from_eqns(from: eqn_list_local).count > max_chems {
//            chemicals.are_eqns_up_to_date = false
//            has_excess_chemicals = true
//        } else { has_excess_chemicals = false }
        
        let eqn_regex = /(?i)^\s*(((\d*[a-z]+)\s*\+\s*)*(\d*[a-z]+))\s*->\s*(((\d*[a-z]+)\s*\+\s*)*(\d*[a-z]+))\s*$/
        for (i, eqn) in eqn_list_local.enumerated() {
            if let _ = try? eqn_regex.wholeMatch(in: eqn) {
                are_equations_valid[i] = true
            } else { are_equations_valid[i] = false }
        }
    }
    
    func update_rates_valid() {
        for i in 0..<rate_str_list.count {
            guard let d0 = Double(rate_str_list[i][0]), let d1 = Double(rate_str_list[i][1]) else {
                are_rates_valid[i] = false
                return
            }
            if d0 >= 0.0 && d1 >= 0.0 { are_rates_valid[i] = true
            } else { are_rates_valid[i] = false }
        }
    }
    
    func enter_eqns_and_rates() {
        update_eqns_valid()
        update_rates_valid()
        
        if !are_values_invalid {
            var new_rates = [[Double]].init(repeating: [0.0, 0.0], count: rate_str_list.count)
            for i in 0..<rate_str_list.count {
                new_rates[i] = [Double(rate_str_list[i][0]) ?? 0.0,Double(rate_str_list[i][1]) ?? 0.0]
            }
            chemicals.equation_list = eqn_list_local
            chemicals.rate_list = new_rates
            
            chemicals.are_eqns_up_to_date = true
            chemicals.update_all()
        }
    }
    
    func rate_list_to_strs() -> [[String]] {
        var ans: [[String]] = []
        for kpm in chemicals.rate_list {
            ans.append([kpm[0].description, kpm[1].description])
        }
        return ans
    }
    
    func pull_data_from_chemicals() {
        rate_str_list = rate_list_to_strs()
        eqn_list_local = chemicals.equation_list
        DispatchQueue.main.async {
            chemicals.are_eqns_up_to_date = true
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Equations and forwards and backwards rates")
                .disabledAppearance(if: chemicals.is_sim_running)
            HStack {
                Button(action: {
                    _ = eqn_list_local.popLast()
                    _ = rate_str_list.popLast()
                    _ = are_equations_valid.popLast()
                    _ = are_rates_valid.popLast()
                }, label: {Image(systemName: "minus")})
                .disabled(eqn_list_local.count == 1)
                
                Button(action: {
                    eqn_list_local.append("")
                    rate_str_list.append(["0.0", "0.0"])
                    are_equations_valid.append(false)
                    are_rates_valid.append(true)
                }, label: {Image(systemName: "plus")})
            }
            .padding(.bottom, 10)
            
            ForEach(0..<eqn_list_local.count, id: \.self) { i in
                HStack {
                    TextField("Equation", text: $eqn_list_local[i])
                        .frame(width: eqn_field_length)
                    Image(systemName: are_equations_valid[i] ? "checkmark" : "xmark")
                        .disabledAppearance(if: chemicals.is_sim_running)
                    Spacer()
                    HStack {
                        TextField("k₊", text: $rate_str_list[i][0])
                        TextField("k₋", text: $rate_str_list[i][1])
                        Image(systemName: are_rates_valid[i] ? "checkmark" : "xmark")
                            .disabledAppearance(if: chemicals.is_sim_running)
                    }
                }
            }
            
            HStack {
                Button("Enter equations") {
                    enter_eqns_and_rates()
                }
                .disabled(has_excess_chemicals)
                VStack(alignment: .leading) {
                    if !chemicals.are_eqns_up_to_date {
                        Text("Equations \(are_values_invalid ? "invalid" : "outdated")")
                            .foregroundStyle(.red)
                    }
                    if has_excess_chemicals {
                        Text("Maximum number of chemicals is \(max_chems)")
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.top, 15)
        }
        .frame(width: 300)
        .padding(.vertical, 30)
        .onChange(of: eqn_list_local, { _, _ in
            chemicals.are_eqns_up_to_date = false
            update_eqns_valid()
        })
        .onChange(of: rate_str_list, { _, _ in
            chemicals.are_eqns_up_to_date = false
            update_rates_valid()
        })
        
        // init local arrays
        .onAppear {
            pull_data_from_chemicals()
        }
    }
}
