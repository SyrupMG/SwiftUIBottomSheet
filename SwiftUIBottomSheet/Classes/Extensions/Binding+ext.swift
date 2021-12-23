//
//  Binding+ext.swift
//  Chip
//
//  Created by Anna Sidorova on 02.12.2021.
//

import Foundation
import SwiftUI

extension Binding {
    func asBool<Tag: Equatable>(with tag: Tag) -> Binding<Bool> where Value == Tag? {
        Binding<Bool> {
            self.wrappedValue == tag
        } set: {
            guard !$0 else { return }
            self.wrappedValue = nil
        }
    }

    func asBool<Input>() -> Binding<Bool> where Value == Input? {
        Binding<Bool> {
            self.wrappedValue != nil
        } set: {
            guard !$0 else { return }
            self.wrappedValue = nil
        }
    }
}

extension Binding {
    func map<OutType>(get: @escaping () -> OutType, set: @escaping (OutType) -> Void) -> Binding<OutType> {
        Binding<OutType>(get: get, set: set)
    }

    func map<OutType>(get: @escaping () -> OutType, set: @escaping (OutType, Transaction) -> Void) -> Binding<OutType> {
        Binding<OutType>(get: get, set: set)
    }
}
