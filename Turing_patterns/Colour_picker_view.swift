//
//  Colour_selection_view.swift
//  Turing_patterns
//
//  Created by David Tudor on 12/07/2025.
//

import Foundation
import SwiftUI

struct Colour_picker_view: View {
    @EnvironmentObject var chemicals: Chemical_eqns
    
    @State private var picker_displayed_cols = [Color].init(repeating: Color(.sRGB, red: 0.98, green: 0.9, blue: 0.2), count: 3)
    
    // chemicals.chem_cols is actually used in the simulation
    // chemicals.chem_cols_picker contains the last picked cols, default to .chem_cols
    // local @State should contain the displayer picker colours
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Chemical colour selection")
            
            ForEach(0..<chemicals.chems.count, id: \.self) { i in
                HStack {
                    Text("Chemical \(chemicals.chems[i])")
                    ZStack {
                        ColorPicker("", selection: $picker_displayed_cols[i])
                            .disabled(chemicals.chems.count <= 3)
                        if (chemicals.chems.count <= 3) {Image(systemName: "lock.fill")}
                    }
                }
            }
        }
        .frame(width: 250)
        .padding(.vertical, 30)
        .onAppear {
            picker_displayed_cols = chemicals.chem_cols.map({ rgb in
                Color(.sRGB, red: Double(rgb[0])/255, green: Double(rgb[1])/255, blue: Double(rgb[2])/255)
            })
        }
    }
}

