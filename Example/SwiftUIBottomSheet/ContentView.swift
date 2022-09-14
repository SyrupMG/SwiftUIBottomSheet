//
//  ContentView.swift
//  SwiftUIBottomSheet_Example
//
//  Created by Anna Sidorova on 23.12.2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import SwiftUI
import SwiftUIBottomSheet

struct ContentView: View {
    @State private var isShown = false
    @State private var height: CGFloat = 200
    @State private var requestedSize: CGFloat = 200
    @State private var sheetType: BottomSheetConfig.Kind = .resizable

    @State private var overgrowContent = false

    var config: BottomSheetConfig {
        .init(kind: sheetType, handlePosition: outsideHandle ? .outside : .inside)
    }

    @State var outsideHandle = false

    var body: some View {
        VStack(spacing: 20) {
            Button("static") {
                overgrowContent = false
                sheetType = .static
                isShown = true
            }
            Button("tap") {
                overgrowContent = false
                sheetType = .tapDismiss
                isShown = true
            }
            Button("resizable") {
                overgrowContent = false
                sheetType = .resizable
                isShown = true
            }
            Button("interactive") {
                overgrowContent = false
                sheetType = .interactiveDismiss
                isShown = true
            }
            Button("static + timer") {
                overgrowContent = false
                sheetType = .static
                isShown = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    isShown = false
                }
            }

            Button("interactive + timer") {
                overgrowContent = false
                sheetType = .interactiveDismiss
                isShown = true

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    isShown = false
                }
            }

            Button("fast show hide") {
                overgrowContent = false
                sheetType = .interactiveDismiss
                isShown = true

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    isShown = false
                }
            }

            Button("overgrow") {
                overgrowContent = true
                sheetType = .interactiveDismiss
                isShown = true
            }

            changeHandleButton
        }
        .bottomSheet(isPresented: $isShown, config: config.feedback(into: $requestedSize)) {
            sheetContent
        }
        .onValueChange(requestedSize) { sz in
//            height = min(600.0, max(200.0, sz))
            if height < 220 && sz > 220 {
                height = 600
            } else if height > 580 && sz < 580 {
                height = 200
            }
        }
    }

    var changeHandleButton: some View {
        Button("Change handle position") {
            outsideHandle.toggle()
        }
    }

    @ViewBuilder var sheetContent: some View {
        if overgrowContent {
            VStack {
                OvergrowScrollView(maxHeight: 400) {
                    VStack(alignment: .trailing) {
                        Color.red
                            .frame(width: 300, height: height)
                    }
                    .frame(maxWidth: .infinity)
                }

                Color.blue
                    .frame(height: 100)
            }
        } else {
            ZStack(alignment: .top) {
                Color.yellow
                    .frame(height: height, alignment: .top)

                VStack(spacing: 20) {
                    Button("Dismiss") {
                        isShown = false
                    }
                    .padding()

                    changeHandleButton
                }
            }
            .frame(height: height, alignment: .top)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
