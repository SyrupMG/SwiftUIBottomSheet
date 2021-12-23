//
//  View+onChange.swift
//  SwiftUIBottomSheet
//
//  Created by Anna Sidorova on 23.12.2021.
//

import SwiftUI

struct ChangeObserver<Content: View, Value: Equatable>: View {
    let content: Content
    let value: Value
    let action: (Value) -> Void

    init(value: Value, action: @escaping (Value) -> Void, content: @escaping () -> Content) {
        self.value = value
        self.action = action
        self.content = content()
        _oldValue = State(initialValue: value)
    }

    @State private var oldValue: Value

    var body: some View {
        if oldValue != value {
            DispatchQueue.main.async {
                oldValue = value
                self.action(self.value)
            }
        }
        return content
    }
}

public extension View {
    @ViewBuilder func onValueChange<Value: Equatable>(_ value: Value, perform action: @escaping (_ newValue: Value) -> Void) -> some View {
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            self.onChange(of: value, perform: action)
        } else {
            ChangeObserver(value: value, action: action) {
                self
            }
        }
    }
}
