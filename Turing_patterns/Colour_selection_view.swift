//
//  Colour_selection_view.swift
//  Turing_patterns
//
//  Created by David Tudor on 12/07/2025.
//

import Foundation
import SwiftUI

struct Colour_selection_view: View {
    @EnvironmentObject var chemicals: Chemical_eqns
    
    @State private var bgColor =
            Color(.sRGB, red: 0.98, green: 0.9, blue: 0.2)
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Chemical colour selection")
            
            ForEach(0..<chemicals.chems.count, id: \.self) { i in
                HStack {
                    Text("Chemical \(chemicals.chems[i])")
                    ZStack {
                        ColorPicker("", selection: $bgColor) // TODO XXX properly reference some data.
                            .disabled(chemicals.chems.count <= 3)
                        if (chemicals.chems.count <= 3) {Image(systemName: "lock.fill")}
                    }
                }
            }
        }
        .frame(width: 250)
        .padding(.vertical, 30)
    }
}

