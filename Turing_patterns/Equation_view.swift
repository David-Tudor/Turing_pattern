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
    
//    @State var rate_str_list: [[String]] = []
    @State var rate_str_list = [[String]].init(repeating: ["0.0", "0.0"], count: 2) // XXX TODO, make the 2 depend on chemicals.equation_list.count, would like this to be optional
    
    
    let eqn_field_length: CGFloat = 150
    let eqn_length: CGFloat = 300
    
    func rate_list_to_str() -> [[String]] {
        var ans: [[String]] = []
        for kpm in chemicals.rate_list {
            ans.append([kpm[0].description, kpm[1].description])
        }
        return ans
    }
    
    func enter_rates() {
        for i in 0..<rate_str_list.count {
            for j in 0...1 {
                guard let d = Double(rate_str_list[i][j]) else {
                    rate_str_list[i][j] = chemicals.rate_list[i][j].description // revert string
                    return
                }
                chemicals.rate_list[i][j] = d
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    _ = chemicals.equation_list.popLast()
                    _ = chemicals.rate_list.popLast()
                    _ = rate_str_list.popLast()
                    chemicals.update_all()
                }, label: {Image(systemName: "minus")})
                
                Button(action: {
                    chemicals.equation_list.append("")
                    chemicals.rate_list.append([0.0, 0.0])
                    rate_str_list.append(["0.0", "0.0"]) // TODO, better to have optional string and init to nil.
                    chemicals.update_all()
                }, label: {Image(systemName: "plus")})
                
                Button("Enter rates") {
                    // string list sets Doubles in chemical.rate_list, or reverts if bad input.
                    enter_rates()
                }
            }
            .padding(.bottom, 10)
            
            ForEach(0..<chemicals.equation_list.count, id: \.self) { i in
                HStack {
                    TextField("Equation", text: $chemicals.equation_list[i])
                        .frame(width: eqn_field_length)
                    Image(systemName: chemicals.are_equations_valid[i] ? "checkmark" : "xmark")
                    Spacer()
                    HStack {
                        TextField("k₊", text: $rate_str_list[i][0])
                        TextField("k₋", text: $rate_str_list[i][1])
                    }
                }
            }
        }
        .frame(width: 250)
        .padding(.vertical, 30)
        .onChange(of: chemicals.equation_list) { oldValue, newValue in
            chemicals.update_all()
        }
        .onAppear {
            rate_str_list = rate_list_to_str()
        }
    }
}
