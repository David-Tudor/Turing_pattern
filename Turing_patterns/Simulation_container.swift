//
//  Simulation_container.swift
//  Turing_patterns
//
//  Created by David Tudor on 16/07/2025.
//

import Foundation
import SwiftUI
import Combine

struct Simulation_container: View {
    @EnvironmentObject var chemicals: Chemical_eqns
    @State var simulation: Simulation
    @State private var drag_location = CGPoint.zero
    
    var drag: some Gesture {
        DragGesture(coordinateSpace: .named("space"))
            .onChanged { info in drag_location = info.location }
    }
    
//    let timer = Timer.publish(every: TimeInterval(1/10), on: .main, in: .common).autoconnect()
    var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
            Timer.publish(every: dt, on: .main, in: .common).autoconnect()
        }
    
    var brush_size: Double
    var brush_chem_i_dbl: Double
    var brush_chem_i: Int {
        Int(brush_chem_i_dbl)
    }
    var dt_str: String
    var dt: Double {
        return Double(dt_str) ?? dt_default
    }
    
    
    let sim_size = [250, 250]
    let dt_default = 0.1
    
    @FocusState private var is_focused: Bool
    
    
    init(drag_location: CoreFoundation.CGPoint = CGPoint.zero, brush_size: Double, brush_chem_i_dbl: Double, background_col_enum: Colour_enum, chem_cols: [Colour], dt_str: String) {
        
        self.simulation = Simulation(height: sim_size[0], width: sim_size[1], chem_cols: chem_cols, dt: Double(dt_str) ?? dt_default, background_col_enum: background_col_enum)
        self.drag_location = drag_location
        self.brush_size = brush_size
        self.brush_chem_i_dbl = brush_chem_i_dbl
        self.dt_str = dt_str
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
                        simulation.background_col = rgb_for(col: chemicals.background_col_enum)
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

