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
// make UI better and disables.
// conc to colour sensitivity
// ! make UI not crash with 0 chems, add buffer and submission. work out source of truth for when chemicals are up to date
// why does refresh time = calc time + dt?

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
    @State private var is_sim_running_publish_buffer: Bool? // changed on Spacebar pressed, then value given to publisher, then reset to nil
    
    let slider_length = 250
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading) {
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
                
                VStack {
                    // Time step
                    Text("Time step (s)")
                        .foregroundColor(chemicals.is_sim_running ? .gray : .primary)
                        .opacity(chemicals.is_sim_running ? 0.6 : 1.0)
                    TextField("dt", text: $dt_str)
                        .frame(width: CGFloat(slider_length))
                    
                    // Dark mode
                    Toggle("Dark mode", isOn: $is_darkmode)
                        .onChange(of: is_darkmode) { oldValue, newValue in
                            switch newValue {
                            case true:  chemicals.background_col_enum = .black
                            case false: chemicals.background_col_enum = .white
                            }
                            chemicals.update_chem_cols()
                        }
                    
                     
                    // Chemical equations
                    Equation_view()
                    Colour_picker_view()
                        .foregroundColor(chemicals.is_sim_running ? .gray : .primary)
                        .opacity(chemicals.is_sim_running ? 0.6 : 1.0)
                }
                .disabled(chemicals.is_sim_running)
                
                // Play/pause simulation button
                Button {
                    chemicals.is_sim_running = !chemicals.is_sim_running
                    is_focused = true
                } label: {
                    Image(systemName: chemicals.is_sim_running ? "pause.fill" : "play.fill")
                        .font(.system(size: 40))
                }
                .focusable()
                .focused($is_focused)
                .focusEffectDisabled()
                .onKeyPress(.space) {
                    is_sim_running_publish_buffer = !chemicals.is_sim_running
                    return .handled
                }
                .onAppear {
                    is_focused = true
                }
                
                Spacer()
            }
            .onChange(of: is_sim_running_publish_buffer) { oldValue, newValue in
                guard let new = is_sim_running_publish_buffer else { return }
                chemicals.is_sim_running = new
                is_sim_running_publish_buffer = nil
            }
            
            VStack {
                Simulation_container(brush_size: brush_size, brush_chem_i_dbl: brush_chem_i_dbl, background_col_enum: chemicals.background_col_enum, chem_cols: chemicals.chem_cols, dt_str: dt_str)
                
            } // end of 2nd column VStack

        } // end of top HStack
        .padding(20)
        .environmentObject(chemicals)
    } // end of body
}

