//
//  InputView.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/14/20.
//

import SwiftUI

struct InputView: View {
    var inputString: String?
    var outputString: String?
    var openFile: (() -> Void)?
    var saveFile: (() -> Void)?

    var clearInput: (() -> Void)?
    var clearOutput: (() -> Void)?

    var body: some View {
        VStack {
            HStack {
                Text("Input:")
                Text(inputString ?? "")
                    .minimumScaleFactor(0.1)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        openFile?()
                    }
                if inputString != nil {
                    Button(action: {
                        clearInput?()
                    }, label: {
                        Image(systemName: "xmark")
                    })
                } else {
                    Button(action: {
                        openFile?()
                    }, label: {
                        Text("...")
                    })
                }
            }.padding(EdgeInsets(top: 1, leading: 16, bottom: 4, trailing: 16))
            HStack {
                Text("Output:")
                Text(outputString ?? "")
                    .minimumScaleFactor(0.1)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        saveFile?()
                    }
                if outputString != nil {
                    Button(action: {
                        clearOutput?()
                    }, label: {
                        Image(systemName: "xmark")
                    })
                } else {
                    Button(action: {
                        saveFile?()
                    }, label: {
                        Text("...")
                    })
                }
            }.padding(EdgeInsets(top: 4, leading: 16, bottom: 1, trailing: 16))
        }
    }
}

struct InputView_Previews: PreviewProvider {
    static var previews: some View {
        InputView(inputString: nil, outputString: nil)
            .frame(width: 200)
    }
}
