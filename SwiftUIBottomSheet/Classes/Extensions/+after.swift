//
//  +after.swift
//  MasterMind
//
//  Created by Anna Sidorova on 24.07.2021.
//

import Foundation

func after(delay: DispatchTimeInterval, on queue: DispatchQueue = .main, _ do: @escaping () -> Void) {
    queue.asyncAfter(deadline: .now() + delay, execute: `do`)
}

func after(delay: TimeInterval, on queue: DispatchQueue = .main, _ do: @escaping () -> Void) {
    after(delay: .milliseconds(Int(delay * 1000)), on: queue, `do`)
}

func afterTransition(_ do: @escaping () -> Void) {
    after(delay: .milliseconds(300), `do`)
}
