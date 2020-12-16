//
//  ConfigView.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/14/20.
//

import SwiftUI

struct ConfigView: View {
    @Binding var selectedSize: GIFDimensions
    @Binding var selectedFPS: FPS

    var body: some View {
        HStack {
            Picker("Dimensions", selection: $selectedSize) {
                ForEach(GIFDimensions.allCases) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .frame(width: 165)
            Spacer()
            Picker("FPS", selection: $selectedFPS) {
                ForEach(FPS.allCases) { fps in
                    Text("\(fps.value)").tag(fps)
                }
            }
            .frame(width: 100)
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(selectedSize: .constant(.small), selectedFPS: .constant(.low))
    }
}
