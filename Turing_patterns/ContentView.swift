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
// SIMD early-ish - or try map, research convolution, design both as rgb <= 3 <= 4
// make chem equations to simulation better
// conc to colour sensitivity
// why does refresh time = calc time + dt?

// NEXT make new eqn source work and update properly, colour picker

// 3 in Equation_view, local rate_str_list not init'd onAppear before view crashes (so currently hardcoded)


import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject var chemicals = Chemical_eqns()
    @FocusState private var is_focused: Bool
    
    @State private var brush_size = 20.0
    @State private var brush_chem_i_dbl = 0.0
    var brush_chem_i: Int {
        Int(brush_chem_i_dbl)
    }
    @State private var dt_str = "0.1"
    @State private var is_darkmode = true
    @State private var is_sponge = false
    
    let slider_length = 250
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading) {
                // Slider for brush size
                Text("Brush size")
                Slider(value: $brush_size, in: 1...50)
                    .frame(width: CGFloat(slider_length))
                
                // Slider for brush type
                HStack {
                    Text("Brush type")
//                    if let colour = chemicals.chem_cols[brush_chem_i] {
//                    } else {
//                        let colour = chemicals.chem_cols.first
//
//                    }
                    Coloured_square(size: CGFloat(10), rgb: is_sponge ? rgb_for(col: chemicals.background_col_enum) : chemicals.chem_cols[(brush_chem_i < chemicals.chem_cols.count) ? brush_chem_i : 0])
                    Divider()
                    Toggle("Use sponge", isOn: $is_sponge)
                }
                .frame(height: 20)
                .onChange(of: chemicals.chem_cols.count) { _, newValue in
                    if brush_chem_i >= newValue { brush_chem_i_dbl = 0.0}
                }
                
                if chemicals.chems.count >= 2 { // else nothing to slide
                    Slider(value: $brush_chem_i_dbl, in: 0...Double(chemicals.chems.count-1), step: 1)
                        .frame(width: CGFloat(slider_length))
                        .disabled(is_sponge)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    // Time step
                    HStack {
                        Text("Time step")
                            .disabledAppearance(if: chemicals.is_sim_running)
                        TextField("dt (secs)", text: $dt_str)
                            
                    }
                    .frame(width: CGFloat(slider_length))
                    
                    // Dark mode
                    Toggle("Dark mode", isOn: $is_darkmode)
                        .onChange(of: is_darkmode) { oldValue, newValue in
                            switch newValue {
                            case true:  chemicals.background_col_enum = .black
                            case false: chemicals.background_col_enum = .white
                            }
                        }
                    
                     
                    // Chemical equations
                    Equation_view()
                    // Chemical colour picker
                    Colour_picker_view()
                        .disabledAppearance(if: chemicals.is_sim_running)
                }
                .disabled(chemicals.is_sim_running)
                
                // Play/pause simulation button
                Button {
                    chemicals.toggle_sim_running()
                    is_focused = true
                } label: {
                    Image(systemName: chemicals.is_sim_running ? "pause.fill" : "play.fill")
                        .font(.system(size: 40))
                }
                .focusable()
                .focused($is_focused)
                .focusEffectDisabled()
                .onKeyPress(.space) {
                    chemicals.toggle_sim_running()
                    return .handled
                }
                .onAppear {
                    is_focused = true
                }
                .disabled(!chemicals.are_eqns_up_to_date)
                
                Spacer()
            }
            
            VStack {
                Simulation_container(brush_size: brush_size, brush_chem_i_dbl: brush_chem_i_dbl, background_col_enum: chemicals.background_col_enum, chem_cols: chemicals.chem_cols, dt_str: dt_str)
                
            } // end of 2nd column VStack

        } // end of top HStack
        .padding(20)
        .environmentObject(chemicals)
    } // end of body
}




