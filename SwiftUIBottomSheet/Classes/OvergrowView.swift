//
//  OvergrowView.swift
//  Chip
//
//  Created by Anna Sidorova on 22.12.2021.
//

import SwiftUI
import Combine

/// NOTE: disables animations inside of it. If animations are needed, they must be applied to content
public struct OvergrowScrollView<Content: View>: View {

    public init(maxHeight: CGFloat, content: @escaping () -> Content) {
        self.maxHeight = maxHeight
        self.content = content
    }

    public let maxHeight: CGFloat
    public let content: () -> Content

    @State private var size: CGSize = .zero
    @State private var height: CGFloat = 0

    public var body: some View {
        Group {
            if height > maxHeight {
                ScrollView {
                    mainContent
                }
            } else {
                mainContent
            }
        }
        .frame(height: contentHeight, alignment: .topLeading)
        .clipped()
    }

    private var contentHeight: CGFloat {
        min(height, maxHeight)
    }

    @ViewBuilder private var mainContent: some View {
        content()
            .geometryFetch(size: $size)
            .onReceive(Just(size)) {
                let height = $0.height

                guard height > 0, self.height != height else { return }

                self.height = height
            }
    }
}

struct OvergrowView_Previews: PreviewProvider {
    static var previews: some View {
        OvergrowScrollView(maxHeight: 300) {
            Color.green.frame(height: 500)
        }
    }
}
