//
//  Chemical_params_view.swift
//  Turing_patterns
//
//  Created by David Tudor on 12/07/2025.
//

import Foundation
import SwiftUI

struct Chemical_params_view: View {
    @EnvironmentObject var chemicals: Chemical_eqns
    
    @State private var picker_displayed_cols = [Color].init(repeating: Color(.sRGB, red: 0.0, green: 0.0, blue: 0.0), count: 3)
    let col1_width: CGFloat = 125
    let col1_frac = 0.6
    let col2_width: CGFloat = 120
    let col3_width: CGFloat = 150
    let col3_frac = 0.5
    
    private var picker_cols: [Colour] {
        picker_displayed_cols.map { color in
            return color_to_rgb(for: color) // Convert UI Colors to Colours
        }
    }
    
    private var chem_range: Range<Int> {
        0 ..< min(picker_displayed_cols.count,chemicals.chems.count)
    }
    
    private let rgb_purple = rgb_for(col: .purple)
    private var default_chem_color: Color {
        rgb_to_color(for: rgb_purple)
    }
    
    func update_chem_cols() {
        if chemicals.chems.count <= 3 {
            let default_cols = (chemicals.background_col_enum == .white) ?
            [rgb_for(col: .cyan), rgb_for(col: .yellow), rgb_for(col: .magenta)] :  // cym
            [rgb_for(col: .red), rgb_for(col: .green), rgb_for(col: .blue)]         // rgb
            picker_displayed_cols = Array(default_cols[0...chemicals.chems.count-1]).map({ rgb in
                rgb_to_color(for: rgb)
            })

        } else { // > 3 colours so take from colour picker
            while picker_displayed_cols.count < chemicals.chems.count {
                picker_displayed_cols.append(default_chem_color)
            }
            
        }
        chemicals.chem_cols = picker_cols
        
        while chemicals.D_strs.count < chemicals.chems.count {
            chemicals.D_strs.append(chemicals.D_default.description)
        }
        while chemicals.target_strs.count < chemicals.chems.count {
            chemicals.target_strs.append([chemicals.target_default.description, chemicals.target_default.description])
        }
    }
    
    func color_to_rgb(for color: Color) -> Colour {
        guard let nsColor: NSColor = NSColor(color).usingColorSpace(.sRGB) else {
            return rgb_purple // return purple on failing
        }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) // fills these variables
        return [Int(red * 255), Int(green * 255), Int(blue * 255)]
    }
    
    func rgb_to_color(for rgb: Colour) -> Color {
        Color(.sRGB, red: Double(rgb[0])/255, green: Double(rgb[1])/255, blue: Double(rgb[2])/255)
    }
    
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Colour selection")
                    .frame(width: col1_width)
                Text("Diffusion constants")
                    .frame(width: col2_width)
                Text("Target concs and rates")
                    .frame(width: col3_width)
            }
            ForEach(chem_range, id: \.self) { i in
                    HStack {
                        Text("Chemical \(chemicals.chems[i])")
                            .frame(width: col1_width*col1_frac)
                        ZStack {
                            ColorPicker("", selection: $picker_displayed_cols[i])
                                .disabled(chemicals.chems.count <= 3)
                            if (chemicals.chems.count <= 3) {Image(systemName: "lock.fill")}
                        }
                        .frame(width: col1_width*(1-col1_frac))

                        TextField("Diffusion const", text: $chemicals.D_strs[i])
                            .frame(width: col2_width)
                        Group {
                            TextField("Concentration", text: $chemicals.target_strs[i][0])
                                .frame(width: col3_width*col3_frac)
                            TextField("Rate", text: $chemicals.target_strs[i][1])
                                .frame(width: col3_width*(1-col3_frac))
                        }
                        
                    }
            }
        }
        .padding(.vertical, 30)
        .onAppear {
            picker_displayed_cols = chemicals.chem_cols.map({ rgb in
                rgb_to_color(for: rgb)
            })
        }
        // TODO merge 3 into 1?
        .onChange(of: chemicals.chems.count) { _, newValue in
            update_chem_cols()
        }
        .onChange(of: chemicals.background_col_enum) { _, newValue in
            update_chem_cols()
        }
        .onChange(of: picker_displayed_cols) { _, newValue in
            update_chem_cols()
        }
    }
}




