//
//  DisclosureButton.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/15/20.
//

import SwiftUI

struct DisclosureButton: View {
    let title: String
    @Binding var isOpen: Bool
    var body: some View {
        VStack {
            Button(action: {
                isOpen.toggle()
            }, label: {
                HStack {
                    Image(systemName: isOpen ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                    Text(title)
                    Spacer()
                }
        }).buttonStyle(PlainButtonStyle()).frame(maxWidth: .infinity)
            Divider()
        }
    }
}

struct DisclosureButton_Previews: PreviewProvider {
    static var previews: some View {
        DisclosureButton(title: "Toggle", isOpen: .constant(false))
    }
}
