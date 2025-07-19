//
//  ContentView.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//

// TODO
// prevent negative colours
// make diffusion act fast - higher fps?
// make permanent chem sources?
// how to measure lag?
// SIMD early-ish
// make chem equations to simulation better

// 3 in Equation_view, local rate_str_list not init'd onAppear before view crashes (so currently hardcoded)


import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject var chemicals = Chemical_eqns()
    
    @State private var brush_size = 20.0
    @State private var brush_chem_i_dbl = 0.0
    var brush_chem_i: Int {
        Int(brush_chem_i_dbl)
    }
    @State private var dt_str = "0.1"
    var dt: Double {
        return Double(dt_str) ?? 0.1
    }
    
    @State private var is_darkmode = true
    let slider_length = 250
    
    
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading) {
                Text("Time step (s)")
                TextField("dt", text: $dt_str)
                    .frame(width: CGFloat(slider_length))
                
                // Slider for brush size
                Text("Brush size")
                Slider(value: $brush_size, in: 1...50)
                    .frame(width: CGFloat(slider_length))
                
                // Slider for brush chemical
                HStack {
                    let is_chem = !(brush_chem_i == chemicals.chems.count)
                    Text("Brush: \(is_chem ? "chemical" : "sponge")")
                    let rgb = is_chem ? chemicals.chem_cols[brush_chem_i] : rgb_for(col: chemicals.background_col_enum) // sponge not chemical if false
                    Coloured_square(size: CGFloat(10), rgb: rgb)

                }
                Slider(value: $brush_chem_i_dbl, in: 0...Double(chemicals.chems.count), step: 1)
                    .frame(width: CGFloat(slider_length))
                
                
                Divider()
                
                Toggle("Dark mode", isOn: $is_darkmode)
                    .onChange(of: is_darkmode) { oldValue, newValue in
                        switch newValue {
                        case true: chemicals.background_col_enum = .black
                        case false:chemicals.background_col_enum = .white
                        }
                    }
                
                
                // Chemical equations
                Equation_view()
                Colour_selection_view()
                
                
                Spacer()
            }
            
            VStack {
                
                Text("background is \(chemicals.background_col_enum)")
                
                // TODO xxx how is SIMULATE button going to work
                Simulation_container(brush_size: brush_size, brush_chem_i_dbl: brush_chem_i_dbl, background_col_enum: chemicals.background_col_enum, chem_cols: chemicals.chem_cols, dt_str: dt_str)
                
            } // end of 2nd column VStack

        } // end of top HStack
        .padding(20)
        .environmentObject(chemicals)
    } // end of body
}

