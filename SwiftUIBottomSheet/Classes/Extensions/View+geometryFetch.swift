//  View+geometryFetch.swift
//  MasterMind
//
//  Created by Anna Sidorova on 24.07.2021.
//

import Foundation
import SwiftUI

public extension View {
    @ViewBuilder
    func geometryFetch(size: Binding<CGSize>) -> some View {
        modifier(GeometryGetterMod(size: size))
    }
}

private struct GeometryGetterMod: ViewModifier {
    @Binding var size: CGSize

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { g in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: g.size.roundedToScale)
                }
                .onPreferenceChange(SizePreferenceKey.self) { preferences in
                    if size != preferences {
                        size = preferences
                    }
                }
            )
    }
}

private struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize

    static var defaultValue: Value = .zero

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

extension CGFloat {
    var roundedToScale: Self {
        let scale = UIScreen.main.scale
        return (self * scale).rounded() / scale
    }
}

extension CGSize {
    var roundedToScale: Self {
        .init(width: width.roundedToScale,
              height: height.roundedToScale)
    }
}
