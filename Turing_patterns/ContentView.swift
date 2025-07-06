//
//  ContentView.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//


///
/// Bitmap to store an image.
///


import SwiftUI
import SwiftData

struct ContentView: View {
    @State var simulation = Simulation(height: 200, width: 200, chem_cols: [.blue, .red])
    @State private var location = CGPoint.zero
    
    @State private var brush_size = 10.0
    @State private var brush_chem_i_dbl = 0.0
    var brush_chem_i: Int {
        Int(brush_chem_i_dbl)
    }
    
    let slider_length = 250
    let timer = Timer.publish(every: TimeInterval(1/10), on: .main, in: .common).autoconnect() // XXX how do i extract an interval?
    
    var drag: some Gesture {
        DragGesture(coordinateSpace: .named("space"))
            .onChanged { info in location = info.location }
    }
    

    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading) {
                Text("Brush size")
                Slider(value: $brush_size, in: 1...30)
                    .frame(width: CGFloat(slider_length))
                
                Divider()
                
                HStack {
                    Text("Brush chemical")
                    let rgb = colour_rgb(col: simulation.chem_cols[brush_chem_i])
                    Rectangle()
                        .frame(width: CGFloat(10), height: CGFloat(10))
                        .foregroundColor(Color(red: Double(rgb[0])/255, green: Double(rgb[1])/255, blue: Double(rgb[2])/255))

                }
                Slider(value: $brush_chem_i_dbl, in: 0...Double(simulation.chem_cols.count-1), step: 1)
                    .frame(width: CGFloat(slider_length))
                
                Button {
                    simulation.clear_values()
                } label: {
                    Text("Clear simulation")
                }

            }
            VStack {
                simulation.export_to_view()
                    .coordinateSpace(name: "space")
                    .gesture(drag)
                    .onChange(of: location) { oldValue, newValue in
                        simulation.create_circle(of: brush_chem_i, around: [Int(newValue.y), Int(newValue.x)], diameter: brush_size, amount: 1.0) // note: to agree with the screen, newvalue.x and .y are swapped
                    }
                    .onReceive(timer) { time in
                        simulation.time_step()
                    }
            }
            
            
            
            
        } // end of top HStack
        .padding(20)
    } // end of body
}

