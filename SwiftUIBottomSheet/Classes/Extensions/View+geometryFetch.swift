//  View+geometryFetch.swift
//  MasterMind
//
//  Created by Anna Sidorova on 24.07.2021.
//

import Foundation
import SwiftUI

extension View {
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
                        .preference(key: SizePreferenceKey.self, value: g.frame(in: .global).size)
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
