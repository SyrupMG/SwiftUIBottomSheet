//
//  BottomSheetModifier.swift
//  MasterMind
//
//  Created by Anna Sidorova on 23.07.2021.
//

import Foundation
import SwiftUI
import Combine

public extension UIColor {
    static var bottomSheetOverlay: UIColor = .init {
        if $0.userInterfaceStyle == .dark {
            return .white
        } else {
            return .black
        }
    }
}

public struct BottomSheetConfig {

    public init(maxHeight: CGFloat = 600,
                kind: Kind = .interactiveDismiss,
                overlayColor: Color = .init(.bottomSheetOverlay),
                shadow: Color? = .init(.black).opacity(0.4),
                background: Color = .init(.systemBackground),
                handleColor: Color = .init(.lightGray),
                handlePosition: HandlePosition = .inside,
                topBarCornerRadius: CGFloat? = nil,
                sizeChangeRequest: Binding<CGFloat> = .constant(0)) {
        self.maxHeight = maxHeight
        self.kind = kind
        self.overlayColor = overlayColor
        self.shadow = shadow
        self.background = background
        self.handleColor = handleColor
        self.handlePosition = handlePosition
        self.topBarCornerRadius = topBarCornerRadius
        self.sizeChangeRequest = sizeChangeRequest
    }

    public enum Kind: Int, CaseIterable, Equatable {
        case `static`
        case tapDismiss

        case resizable
        case interactiveDismiss
    }

    public enum HandlePosition: Int {
        case inside
        case outside
    }

    public var maxHeight: CGFloat
    public var kind: Kind
    public var overlayColor: Color
    public var shadow: Color?
    public var background: Color
    public var handleColor: Color
    public var handlePosition: HandlePosition
    public var topBarCornerRadius: CGFloat?
    public var sizeChangeRequest: Binding<CGFloat>
}

public extension BottomSheetConfig {
    func feedback(into binding: Binding<CGFloat>) -> Self {
        var copy = self
        copy.sizeChangeRequest = binding
        return copy
    }
}

public extension View {

    func bottomSheet<Content: View>(isPresented: Binding<Bool>,
                                    config: BottomSheetConfig,
                                    @ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(BottomSheetModifier(isSheetPresented: isPresented,
                                     config: config,
                                     sheetContent: content))
    }

    func bottomSheet<Content: View>(isPresented: Binding<Bool>,
                                    maxHeight: CGFloat = 600,
                                    useGesture: Bool = true,
                                    @ViewBuilder content: @escaping () -> Content) -> some View {

        bottomSheet(isPresented: isPresented,
                    config: .init(maxHeight: maxHeight,
                                  kind: useGesture ? .interactiveDismiss : .static),
                    content: content)
    }

    func bottomSheet<Content: View, T>(item: Binding<T?>,
                                       config: BottomSheetConfig,
                                       @ViewBuilder content: @escaping (T) -> Content) -> some View {
        modifier(
            BottomSheetModifier(
                isSheetPresented: item.asBool(),
                config: config,
                sheetContent: {
                    if let value = item.wrappedValue {
                        content(value)
                    } else {
                        EmptyView()
                    }
                }
            )
        )
    }

    func bottomSheet<Content: View, T>(item: Binding<T?>,
                                       maxHeight: CGFloat = 600,
                                       useGesture: Bool = true,
                                       @ViewBuilder content: @escaping (T) -> Content) -> some View {
        bottomSheet(item: item,
                    config: .init(maxHeight: maxHeight,
                                  kind: useGesture ? .interactiveDismiss : .static),
                    content: content)
    }
}

private let animationFakeDelay: DispatchTimeInterval = .milliseconds(250)

private struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding fileprivate var isSheetPresented: Bool

    let config: BottomSheetConfig
    @ViewBuilder fileprivate let sheetContent: () -> SheetContent

    @State private var modal = false
    @State private var sheet = false
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .modal(isPresenting: $modal,
                   config: .init(style: .overlay, transition: .fade, animated: false)) {

                _BottomSheetContent(isPresented: $sheet,
                                    config: config,
                                    onCLose: close,
                                    sheetContent: sheetContent)
            }
                   .onReceive(Just(isSheetPresented)) {
                       if $0 && !modal {
                           modal = true
                           sheet = true
                       }
                       if !$0 && sheet {
                           sheet = false
                       }
                   }
    }

    func close() {
        isSheetPresented = false
        sheet = false
        modal = false
    }
}

private struct _BottomSheetContent<Content: View>: View {
    @Binding var isPresented: Bool

    let config: BottomSheetConfig
    let onCLose: () -> Void
    @ViewBuilder var sheetContent: () -> Content

    @State private var size: CGSize = .zero
    @State private var height: CGFloat = 0

    private func hide() {
        isPresented = false
    }

    private var contentHeight: CGFloat {
        min(height, config.maxHeight)
    }

    var body: some View {
        GeometryReader { g in
            BottomSheetContainer(isPresented: $isPresented,
                                 height: contentHeight,
                                 config: config,
                                 onClose: onCLose) {
                sheetContent()
                    .fixedSize(horizontal: false, vertical: true)
                    .geometryFetch(size: $size)
                    .onReceive(Just(size)) {
                        let height = $0.height

                        guard height > 0, self.height != height else { return }

                        self.height = height
                    }
            }
        }
    }
}

private struct BottomSheetContainer<Content: View>: View {

    private var dragToDismissThreshold: CGFloat { min(100, max(0, height - 50)) }
    private var grayBackgroundOpacity: Double { isPresented ? 0.4 : 0 }

    @State private var draggedOffset: CGFloat = 0

    @Binding var isPresented: Bool
    private let height: CGFloat
    private let config: BottomSheetConfig
    private let onCLose: () -> Void

    private let content: Content

    private let topBarHeight: CGFloat = 30
    private let topBarCornerRadius: CGFloat

    @State private var shown = false

    var canDrag: Bool {
        config.kind == .interactiveDismiss || config.kind == .resizable
    }

    var canDismiss: Bool {
        config.kind == .tapDismiss || config.kind == .interactiveDismiss
    }

    public init(
        isPresented: Binding<Bool>,
        height: CGFloat,
        config: BottomSheetConfig,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented

        self.config = config
        self.onCLose = onClose

        self.height = height + topBarHeight

        if let topBarCornerRadius = config.topBarCornerRadius {
            self.topBarCornerRadius = topBarCornerRadius
        } else {
            self.topBarCornerRadius = topBarHeight / 2
        }
        self.content = content()
    }

    public var body: some View {
        // animations must be disabled while calculating content size
        let animated = shown && dragStart == nil

        GeometryReader { geometry in
            ZStack(alignment: .bottom) {

                fullScreenLightGrayOverlay()

                sheetContentContainer(geometry: geometry)
            }
        }
        .modifier(AnimatableModifierDouble(bindedValue: isPresented ? 1.0 : 0.0) {
            if !isPresented {
                shown = false
                onCLose()
            }
        })
        .animation(animated ? .interactiveSpring() : nil)
        .onReceive(Just(isPresented)) {
            if $0 && !shown {
                shown = true
            }
        }
    }

    fileprivate func fullScreenLightGrayOverlay() -> some View {
        config.overlayColor
            .opacity(isPresented && shown ? grayBackgroundOpacity : 0)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                guard canDismiss else { return }

                isPresented = false
            }
    }

    @ViewBuilder func sheetContentContainer(geometry: GeometryProxy) -> some View {
        let offset = isPresented
        ? draggedOffset
        : (height + geometry.safeAreaInsets.bottom + 10) // 10 is for shadows

        Group {
            if let shadowColor = config.shadow {
                sheetContent(geometry: geometry)
                    .background(
                        RoundedCorner(radius: topBarCornerRadius, corners: [.topLeft, .topRight])
                            .foregroundColor(config.background)
                            .edgesIgnoringSafeArea(.bottom)
                            .shadow(color: shadowColor, radius: 10, x: 0, y: 0)
                    )
            } else {
                sheetContent(geometry: geometry)
            }
        }
        .offset(y: offset)
    }

    @ViewBuilder
    func sheetContent(geometry: GeometryProxy) -> some View {
        let shift = config.handlePosition == .inside && canDrag ? 0 : topBarHeight

        let clipShape = RoundedCorner(radius: topBarCornerRadius, corners: [.topLeft, .topRight])

        let sheetHeight = max(0, height - shift)

        ZStack(alignment: .top) {
            content
                .padding(.top, topBarHeight - shift)
                .clipShape(clipShape)
                .frame(height: sheetHeight, alignment: .top)

            topBar(geometry: geometry)
                .padding(.top, -shift)
                .frame(height: sheetHeight, alignment: .top)
        }
        .background(
            config.background
                .frame(height: sheetHeight + 6000, alignment: .top)
                .clipShape(clipShape)
            , alignment: .top
        )
    }

    @State private var dragStart: CGFloat?

    @ViewBuilder
    fileprivate func topBar(geometry: GeometryProxy) -> some View {
        if canDrag {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.lightGray))
                    .frame(width: 40, height: 6)
            }
            .frame(width: geometry.size.width, height: topBarHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        let offsetY = value.translation.height
                        if let dragStart = dragStart {
                            self.draggedOffset = offsetY - dragStart
                        } else {
                            dragStart = offsetY
                        }
                    }
                    .onEnded { value in
                        if canDismiss && draggedOffset > dragToDismissThreshold {
                            isPresented = false
                        } else {
                            config.sizeChangeRequest.wrappedValue = height - topBarHeight - draggedOffset
                        }

                        draggedOffset = 0
                        dragStart = nil
                    }
            )
        } else {
            ZStack { }
            .frame(width: geometry.size.width, height: topBarHeight)
            .contentShape(Rectangle())
        }
    }
}


public struct BottomSheet_Preview: PreviewProvider {

    public struct Preview: View {
        @State var isShown = false
        @State var height: Double = 100.0

        public init() {}

        public var body: some View {
            ZStack {
                Color.yellow
                Button("Booo") {
                    height = height == 100.0 ? 400.0 : 100.0
                    isShown = true
                }
            }
            .bottomSheet(isPresented: $isShown) {
                VStack {
                    OvergrowScrollView(maxHeight: 400) {
                        ZStack {
                            Color.red
                        }
                        .frame(width: 300, height: height)
                    }

                    Color.blue
                        .frame(height: 100)
                }
            }
        }
    }

    public static var previews: some View {
        Preview()
    }
}

struct AnimatableModifierDouble: AnimatableModifier {

    var targetValue: Double

    var animatableData: Double {
        didSet {
            checkIfFinished()
        }
    }

    var completion: () -> ()

    init(bindedValue: Double, completion: @escaping () -> ()) {
        self.completion = completion
        self.animatableData = bindedValue
        targetValue = bindedValue
    }

    func checkIfFinished() -> () {
        if (animatableData == targetValue) {
            DispatchQueue.main.async {
                self.completion()
            }
        }
    }

    func body(content: Content) -> some View {
        content
    }
}
