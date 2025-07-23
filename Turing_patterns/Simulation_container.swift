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
    @State private var start_time: ContinuousClock.Instant?
    private let clock = ContinuousClock()
    
    var drag: some Gesture {
        DragGesture(coordinateSpace: .named("space"))
            .onChanged { info in drag_location = info.location }
    }
    
    var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: TimeInterval(dt), on: .main, in: .common).autoconnect()
        }
    
    var brush_size: Double
    var is_sponge: Bool
    var brush_chem_i_dbl: Double
    var brush_chem_i: Int? {
        if is_sponge { return nil }
        else { return Int(brush_chem_i_dbl) }
    }
    var dt_str: String
    var dt: Num {
        let d = Num(dt_str.trimmingCharacters(in: .whitespacesAndNewlines))
        if d != nil && d! > 0 {
            return d!
        } else {
            return dt_default
        }
    }
    
    let sim_size = [250, 250]
    let dt_default: Num = 0.1

    
    init(drag_location: CoreFoundation.CGPoint = CGPoint.zero, brush_size: Double, brush_chem_i_dbl: Double, background_col_enum: Colour_enum, chem_cols: [Colour], dt_str: String, is_sponge: Bool, chems: [String], equation_list: [String], rate_list: [[Num]]) {
        
        self.simulation = Simulation(height: sim_size[0], width: sim_size[1], chem_cols: chem_cols, dt: 0.1, background_col_enum: background_col_enum, chems: chems, equation_list: equation_list, rate_list: rate_list)
        self.drag_location = drag_location
        self.brush_size = brush_size
        self.brush_chem_i_dbl = brush_chem_i_dbl
        self.dt_str = dt_str
        self.is_sponge = is_sponge
    }
    
    var body: some View {
        VStack {
        
            simulation.export_to_view()
                .coordinateSpace(name: "space")
                .gesture(drag)
            
            // chemical brush:
                .onChange(of: drag_location) { oldValue, newValue in
                    simulation.create_circle(of: brush_chem_i, around: [Int(newValue.x), Int(newValue.y)], diameter: brush_size, amount: 1.0)
                }
            
            // time stepper:
                .onReceive(timer) { time in
                    if simulation.is_running {

                        let current_time = clock.now
                        let step_time: Double
                        if let previous = start_time {
                            step_time = duration_to_dbl(previous.duration(to: current_time))
                        } else { step_time = 1.0}
                        start_time = current_time
                        
                        let elapsed = clock.measure {
                            simulation.time_step()
                        }

                        print(String(format: "Time OF step: %.3f | CALCULATE step %.3f | EFF. %.3f",
                                     step_time, duration_to_dbl(elapsed), Double(dt)/step_time))
                    }
                }
            
            // update simulation properties when they are changed elsewhere
                .onChange(of: dt, {simulation.dt = dt})
                .onChange(of: chemicals.diffusion_consts, {simulation.diffusion_consts = chemicals.diffusion_consts})
                .onChange(of: chemicals.background_col_enum, {simulation.background_col = rgb_for(col: chemicals.background_col_enum)})
                .onChange(of: chemicals.chem_cols, {simulation.chem_cols = chemicals.chem_cols})
                .onChange(of: chemicals.is_sim_running, {simulation.is_running = chemicals.is_sim_running})
                .onChange(of: chemicals.chem_cols.count, {simulation.values = Grid(height: sim_size[0], width: sim_size[1], num_chems: chemicals.chem_cols.count)})
                .onChange(of: chemicals.equation_list, {simulation.reaction_funcs = make_reaction_functions(chems: chemicals.chems, equation_list: chemicals.equation_list, rate_list: chemicals.rate_list)})
                .onChange(of: chemicals.rate_list, {simulation.reaction_funcs = make_reaction_functions(chems: chemicals.chems, equation_list: chemicals.equation_list, rate_list: chemicals.rate_list)})
            
            HStack {
                // Clear simulation button
                Button {
                    simulation.clear_values()
                } label: {
                    Image(systemName: "trash.fill")
                }
                
            }
        }
        .onAppear {
            simulation.chem_cols = chemicals.chem_cols // NEEDED?
            simulation.diffusion_consts = chemicals.diffusion_consts
        }
    }
}

