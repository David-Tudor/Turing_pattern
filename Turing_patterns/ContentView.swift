//
//  ContentView.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//


// TODO
// How to set an fps that the timer will use, but trouble at defined on init?
// Speed: add parallelism? add elements of lists efficiently?
// How to have n colour channels?
// More circular diffusion? - improve laplacian - bigger area, symmetry
// Saving system


import SwiftUI
import SwiftData

struct ContentView: View {
    @State var simulation = Simulation(height: 200, width: 200, chem_cols: [.blue, .red, .green])
    @StateObject var chemicals = Chemical_eqns()
    
    @State private var location = CGPoint.zero
    
    @State private var brush_size = 10.0
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
                    let rgb = colour_rgb(col: is_chem ? // sponge not chemical if false
                                         simulation.chem_cols[brush_chem_i] : simulation.background_col
                    )
                    Rectangle()
                        .frame(width: CGFloat(10), height: CGFloat(10))
                        .foregroundColor(Color(red: Double(rgb[0])/255, green: Double(rgb[1])/255, blue: Double(rgb[2])/255))

                }
                Slider(value: $brush_chem_i_dbl, in: 0...Double(simulation.chem_cols.count), step: 1)
                    .frame(width: CGFloat(slider_length))
                
                
                // Chemical equations
                Equation_view()
                
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

