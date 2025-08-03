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
    
    let sim_size: [Int]
    let dt_default: Double
    
    var brush_size: Double
    var is_sponge: Bool
    var brush_density: Double
    var brush_amount: Double
    var brush_shape: Brush_shape
    var is_source: Bool
    
    var brush_chem_i_dbl: Double
    var brush_chem_i: Int? {
        if is_sponge { return nil }
        else { return Int(brush_chem_i_dbl) }
    }
    var dt_str: String
    var dt: Double {
        let d = Double(dt_str.trimmingCharacters(in: .whitespacesAndNewlines))
        if d != nil && d! > 0 {
            return d!
        } else {
            return dt_default
        }
    }
    
    init(drag_location: CoreFoundation.CGPoint = CGPoint.zero, brush_size: Double, brush_chem_i_dbl: Double, background_col_enum: Colour_enum, chem_cols: [Colour], dt_str: String, is_sponge: Bool, chems: [String], equation_list: [String], rate_list: [[Double]], brush_density: Double, brush_shape: Brush_shape, is_source: Bool, brush_amount: Double, chem_targets: [[Double]]) {
        
        let preset = Preset()
        self.sim_size = preset.sim_size
        self.dt_default = preset.dt_default
        self.simulation = Simulation(height: sim_size[0], width: sim_size[1], chem_cols: chem_cols, dt: dt_default, background_col_enum: background_col_enum, chems: chems, equation_list: equation_list, rate_list: rate_list, chem_targets: chem_targets)
        self.drag_location = drag_location
        self.brush_size = brush_size
        self.brush_chem_i_dbl = brush_chem_i_dbl
        self.dt_str = dt_str
        self.is_sponge = is_sponge
        self.brush_density = brush_density
        self.brush_shape = brush_shape
        self.is_source = is_source
        self.brush_amount = brush_amount
    }
    
    var body: some View {
        VStack {
        
            simulation.export_to_view()
                .coordinateSpace(name: "space")
                .gesture(drag)
            
            // chemical brush:
                .onChange(of: drag_location) { oldValue, newValue in
                    simulation.paint(chemical: brush_chem_i, around: [Int(newValue.x), Int(newValue.y)], diameter: brush_size, amount: brush_amount, shape: brush_shape, is_source: is_source, brush_density: brush_density)
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
                .onChange(of: chemicals.chem_cols.count, {simulation.values = Grid(height: sim_size[0], width: sim_size[1], num_chems: chemicals.chem_cols.count); simulation.num_chems = chemicals.chem_cols.count})
                .onChange(of: chemicals.equation_list, {simulation.reaction_funcs = make_reaction_functions(chems: chemicals.chems, equation_list: chemicals.equation_list, rate_list: chemicals.rate_list)})
                .onChange(of: chemicals.rate_list, {
                    simulation.reaction_funcs = make_reaction_functions(chems: chemicals.chems, equation_list: chemicals.equation_list, rate_list: chemicals.rate_list)
                    simulation.rate_list = chemicals.rate_list
                })
                .onChange(of: chemicals.chem_targets, {simulation.chem_targets_flat = chemicals.chem_targets.flatMap{$0}})
            
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
            simulation.chem_cols = chemicals.chem_cols
            simulation.diffusion_consts = chemicals.diffusion_consts
            simulation.chem_targets_flat = chemicals.chem_targets.flatMap{$0}
        }
    }
}

