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
// make diffusion act fast - higher fps?
// make permanent chem sources?

// 1 Published chemical not working - works for its own view, just not for Simulation - mix of struct and View with a weird lifetime?
// 3 in Equation_view, local rate_str_list not init'd onAppear before view crashes (so currently hardcoded)
// 4 How to set an fps that the timer will use, but trouble at defined on init?


import SwiftUI
import SwiftData

struct Simulation_container: View {
    @State var simulation: Simulation
    @State private var drag_location = CGPoint.zero
    
    var drag: some Gesture {
        DragGesture(coordinateSpace: .named("space"))
            .onChanged { info in drag_location = info.location }
    }
    
    let timer = Timer.publish(every: TimeInterval(1/10), on: .main, in: .common).autoconnect()
    var brush_size: Double
    var brush_chem_i_dbl: Double
    var brush_chem_i: Int {
        Int(brush_chem_i_dbl)
    }
    
    @FocusState private var is_focused: Bool
    
    init(drag_location: CoreFoundation.CGPoint = CGPoint.zero, brush_size: Double, brush_chem_i_dbl: Double, background_col_enum: Colour_enum) {
        self.simulation = Simulation(height: 200, width: 200, chem_cols: [rgb_for(col: .red), rgb_for(col: .green), rgb_for(col: .blue)], background_col_enum: background_col_enum)
        self.drag_location = drag_location
        self.brush_size = brush_size
        self.brush_chem_i_dbl = brush_chem_i_dbl
    }
    
    var body: some View {
        VStack {
            simulation.export_to_view()
                .coordinateSpace(name: "space")
                .gesture(drag)
            
            // chemical brush:
                .onChange(of: drag_location) { oldValue, newValue in
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
        }
    }
}

struct ContentView: View {
    
    @StateObject var chemicals = Chemical_eqns()
    
    
    
    @State private var brush_size = 20.0
    @State private var brush_chem_i_dbl = 0.0
    var brush_chem_i: Int {
        Int(brush_chem_i_dbl)
    }
    
    let slider_length = 250
    let background_col_enum: Colour_enum = .black
    
    
    
    
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
                    let is_chem = !(brush_chem_i == chemicals.chems.count)
                    Text("Brush: \(is_chem ? "chemical" : "sponge")")
                    let rgb = is_chem ? chemicals.chem_cols[brush_chem_i] : rgb_for(col: background_col_enum) // sponge not chemical if false
                    Coloured_square(size: CGFloat(10), rgb: rgb)

                }
                Slider(value: $brush_chem_i_dbl, in: 0...Double(chemicals.chems.count), step: 1)
                    .frame(width: CGFloat(slider_length))
                
                
                // Chemical equations
                Equation_view()
                Colour_selection_view()
                
                Spacer()
            }
            
            VStack {
                
                Simulation_container(brush_size: brush_size, brush_chem_i_dbl: brush_chem_i_dbl, background_col_enum: background_col_enum)
                
                

            } // end of 2nd column VStack

        } // end of top HStack
        .padding(20)
        .environmentObject(chemicals)
    } // end of body
}

