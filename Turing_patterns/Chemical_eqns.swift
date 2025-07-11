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
    // add another @Publisher for the rates
    @Published var are_equations_valid: [Bool] = [true, true]
    var chems: [String] = ["A", "B", "P"]
    var chem_cols: [Colour] = [rgb_for(col: .blue), rgb_for(col: .red), rgb_for(col: .green)]
    
    func update_chems() {
        chems = []
        var mem = ""
        for str in equation_list {
            for c in str {
                if c.isLetter { // add character to memory
                    mem += String(c)
                } else if mem != "" && !chems.contains(mem) { // chemical finished, try apppend it
                    chems.append(mem)
                    mem = ""
                }
            }
        }
    }
    
    func update_chem_cols() {
        switch chem_cols.count {
        case 0: chem_cols = []
        case 1: chem_cols = [rgb_for(col: .blue)]
        case 2: chem_cols = [rgb_for(col: .blue), rgb_for(col: .red)]
        case 3: chem_cols = [rgb_for(col: .blue), rgb_for(col: .red), rgb_for(col: .green)]
        default:
            chem_cols = []
            print("CURRENTLY 3 COLS AVAILABLE") // XXX todo
        }
    }
    
    func update_eqns_valid() {
        are_equations_valid = [Bool](repeating: true, count: equation_list.count) // XXX todo
    }
    
    func update_all() {
        update_chems()
        update_chem_cols()
        update_eqns_valid()
    }
    
}


struct Equation_view: View {
    @EnvironmentObject var chemicals: Chemical_eqns
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    _ = chemicals.equation_list.popLast()
                    chemicals.update_all()
                }, label: {Image(systemName: "minus")})
                
                Button(action: {
                    chemicals.equation_list.append("")
                    chemicals.update_all()
                }, label: {Image(systemName: "plus")})
            }
            .padding(.bottom, 10)
            
            ForEach(0..<chemicals.equation_list.count, id: \.self) { i in
                HStack {
                    TextField("Equation", text: $chemicals.equation_list[i])
                    Image(systemName: chemicals.are_equations_valid[i] ? "checkmark" : "xmark")
                }
            }
        }
        .frame(width: 250)
        .padding(.vertical, 30)
        .onChange(of: chemicals.equation_list) { oldValue, newValue in
            chemicals.update_all()
        }
    }
}
