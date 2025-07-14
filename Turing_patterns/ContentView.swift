//
//  ContentView.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//


// TODO
// Speed: add parallelism? add elements of lists efficiently? SIMD
// SIMD
// prevent negative colours

// How to set an fps that the timer will use, but trouble at defined on init?
// move some UI as they throttle - is there a View which wouldn't consume memory?
// Published chemical not working - works for its own view, just not for Simulation - mix of struct and View with a weird lifetime?
// in Equation_view, local rate_str_list not init'd onAppear before view crashes (so currently hardcoded)


import SwiftUI
import SwiftData

struct ContentView: View {
    @State var simulation = Simulation(height: 200, width: 200, chem_cols: [rgb_for(col: .red), rgb_for(col: .green), rgb_for(col: .blue)], background_col_enum: .black)
    @StateObject var chemicals = Chemical_eqns()
    
    @State private var location = CGPoint.zero
    
    @State private var brush_size = 20.0
    @State private var brush_chem_i_dbl = 0.0
    var brush_chem_i: Int {
        Int(brush_chem_i_dbl)
    }
    
    let slider_length = 250
    let timer = Timer.publish(every: TimeInterval(1/10), on: .main, in: .common).autoconnect()
    
    var drag: some Gesture {
        DragGesture(coordinateSpace: .named("space"))
            .onChanged { info in location = info.location }
    }
    @FocusState private var is_focused: Bool
    
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading) {
                // Slider for brush size
                Text("Brush size")
                Slider(value: $brush_size, in: 1...50)
                    .frame(width: CGFloat(slider_length))
                
                Divider()
                
                // Slider for brush chemical
                HStack {
                    let is_chem = !(brush_chem_i == simulation.chem_cols.count)
                    Text("Brush: \(is_chem ? "chemical" : "sponge")")
                    let rgb = is_chem ? simulation.chem_cols[brush_chem_i] : simulation.background_col // sponge not chemical if false
                    Coloured_square(size: CGFloat(10), rgb: rgb)

                }
                Slider(value: $brush_chem_i_dbl, in: 0...Double(simulation.chem_cols.count), step: 1)
                    .frame(width: CGFloat(slider_length))
                
                
                // Chemical equations
                Equation_view()
                Colour_selection_view()
                
                Spacer()
            }
            
            VStack {
                simulation.export_to_view()
                    .coordinateSpace(name: "space")
                    .gesture(drag)
                
                // chemical brush:
                    .onChange(of: location) { oldValue, newValue in
                        simulation.create_circle(of: brush_chem_i, around: [Int(newValue.y), Int(newValue.x)], diameter: brush_size, amount: 1.0) // note: to agree with the screen, newvalue.x and .y are swapped
                    }
                
                // time stepper:
                    .onReceive(timer) { time in
                        if simulation.is_running {
                            simulation.time_step()
                        }
                    }
                
                HStack {
                    // Clear simulation button
                    Button {
                        simulation.clear_values()
                    } label: {
                        Image(systemName: "trash.fill")
                    }
                    
                    // Play/pause simulation button
                    Button {
                        simulation.is_running = !simulation.is_running
                        is_focused = true
                    } label: {
                        simulation.is_running ? Image(systemName: "pause.fill") : Image(systemName: "play.fill")
                    
                    }
                    .focusable()
                    .focused($is_focused)
                    .focusEffectDisabled()
                    .onKeyPress(.space) {
                        simulation.is_running = !simulation.is_running
                        return .handled
                    }
                    .onAppear {
                        is_focused = true
                    }
                }

            } // end of 2nd column VStack

        } // end of top HStack
        .padding(20)
        .environmentObject(chemicals)
    } // end of body
}

