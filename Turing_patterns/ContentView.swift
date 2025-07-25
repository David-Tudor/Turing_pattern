//
//  ContentView.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//

// TODO
// currently, some thing init'd assuming the default chemical equations.
// prevent negative colours
// SIMD?
// conc to colour sensitivity
// why does refresh time = calc time + dt?
// could make a non real time one.
// maybe look at metal
// make RK4, not Euler method. prio timer bug. run time step on a single non-main core?
// single vs double - no effect!!? <- in readme, make a list of stuff ive done but isnt in the final code.
// Make diffusion act many times per step, RK4 option, increase chem scale amount so diffusion goes further and colour sensitivity
// remove Cell


// NEXT test simd


import SwiftUI
import SwiftData

enum Brush_shape {
    case circle
    case square
    case ring
    case gaussian
}

struct ContentView: View {
    @StateObject var chemicals = Chemical_eqns()
    @FocusState private var is_focused: Bool
    
    @State private var brush_size = 40.0
    @State private var brush_density = 1.0
    @State private var brush_amount: Num = 1.0
    @State private var brush_shape = Brush_shape.circle
    @State private var is_sponge = false
    @State private var is_source = false
    @State private var brush_chem_i_dbl = 0.0
    var brush_chem_i: Int {
        Int(brush_chem_i_dbl)
    }
    @State private var dt_str = "0.1"
    @State private var is_darkmode = true
    
    
    let slider_length = 250
    let longer_length = 300
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading) {
                // Slider for brush size
                Text("Brush size")
                Slider(value: $brush_size, in: 1...70)
                    .frame(width: CGFloat(slider_length))
                
                // Slider for brush density
                Text("Brush density")
                Slider(value: $brush_density, in: 0...1.0)
                    .frame(width: CGFloat(slider_length))
                
                // Slider for brush amount
                Text("Brush amount")
                Slider(value: $brush_amount, in: 0...5.0)
                    .frame(width: CGFloat(slider_length))
                
                HStack {
                    Picker("Brush shape", selection: $brush_shape) {
                        Text("Circle").tag(Brush_shape.circle)
                        Text("Square").tag(Brush_shape.square)
                        Text("Ring").tag(Brush_shape.ring)
                        Text("Gaussian").tag(Brush_shape.gaussian)
                    }
                }.frame(width: CGFloat(slider_length))
                
                
                // Slider for brush type
                HStack {
                    Text("Brush type")
                    Coloured_square(size: CGFloat(10), rgb: is_sponge ? rgb_for(col: chemicals.background_col_enum) : chemicals.chem_cols[(brush_chem_i < chemicals.chem_cols.count) ? brush_chem_i : 0])
                    Divider()
                    Toggle("Use sponge", isOn: $is_sponge)
                    Divider()
                    Toggle("Make source", isOn: $is_source)
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
                Simulation_container(brush_size: brush_size, brush_chem_i_dbl: brush_chem_i_dbl, background_col_enum: chemicals.background_col_enum, chem_cols: chemicals.chem_cols, dt_str: dt_str, is_sponge: is_sponge, chems: chemicals.chems, equation_list: chemicals.equation_list, rate_list: chemicals.rate_list, brush_density: brush_density, brush_shape: brush_shape, is_source: is_source, brush_amount: brush_amount)
                
            } // end of 2nd column VStack

        } // end of top HStack
        .padding(20)
        .environmentObject(chemicals)
    } // end of body
}




