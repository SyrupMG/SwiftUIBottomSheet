# SwiftUIBottomSheet

[![Version](https://img.shields.io/cocoapods/v/SwiftUIBottomSheet.svg?style=flat)](https://cocoapods.org/pods/SwiftUIBottomSheet)
[![Version](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg?style=flat)](https://github.com/apple/swift-package-manager)

## About
Simple in use library for showing popular UI control - bottom sheet. 
Main difference from SwiftUI's `.sheet` is that uses not full screen space but only bottom part and can be interactively closed and/or change it's size. 
Second case looks like UIKit's `UISheetPresentationController` but more flexible and customizable (with some caveats).
One of BottomSheets' features is updating it's size to wrap content without blank spaces realtime.

## Getting started
Fastest way to show bottom sheet is:
```swift
.bottomSheet(isPresented: $isShown) {
    // sheet content
}
```
Where `isPresented` controls visibility of sheet.

Also you can use optional based variant:
```swift
.bottomSheet(item: $optionalModel) {
    // sheet content
}
```
Sheet is hidden when `optionalModel == nil` and shown otherwise.

## Usage
SwiftUIBottomSheet also provides much more control via configuration:
```swift
struct BottomSheetConfig {
    enum Kind {
        case `static` // bottom sheet is static and can not be resized or dismissed by user's gestures
        case tapDismiss // bottom sheet can be dismissed by tapping outside of it

        case resizable // can not be dismissed but has ability to be resized - drag handle is drawn at top of bottom sheet
        case interactiveDismiss // bottom sheet can be dismissed by tapping outside of it or swiped down with drag handle
    }
    
    enum HandlePosition {
        case inside // drag handle drawn inside bottomsheet adding padding to content
        case outside // drag handle drawn outside
    }

    var maxHeight: CGFloat // max height of sheet to prevent overgrow outside of screen, default is 600
    var kind: Kind // type of sheet behavior, default is .interactiveDismiss
    var overlayColor: Color // color of area outside of sheet covering content, default id `.black` or `.white` depending on current color sheme
    var shadow: Color? // color of shadow around sheet, shadow is absent when set to nil
    var background: Color // color of sheet background, default is system background color
    var handleColor: Color // color of drag handle, default is gray
    var handlePosition: HandlePosition // position of drag handle when it visible - inside or outside bottomsheet
    var topBarCornerRadius: CGFloat? // radius of top corners of sheet, default is nil wich equals to 15 
    var sizeChangeRequest: Binding<CGFloat> // binding wich changed when user changed size of sheet by dragging it's handle (see more info below)
}
```

`sizeChangeRequest` property gives you ability to control height of content caused by user. Here is example of `UISheetPresentationController`-like behavior:
```swift
struct ContentView: View {
    @State private var isShown = false
    @State private var height: CGFloat = 200
    @State private var requestedSize: CGFloat = 200

    var body: some View {
            Button("show") {
                isShown = true
            }
        }
        .bottomSheet(isPresented: $isShown, config: .init(sizeChangeRequest: $requestedSize)) {
            Color.yellow
              .frame(height: height)
        }
        .onValueChange(requestedSize) { sz in
            if height < 220 && sz > 220 {
                height = 600
            } else if height > 580 && sz < 580 {
                height = 200
            }
        }
    }
```

For cases where you have predefined config (for setting up colors etc.) there is method `.feedback(into: Binding<CGFloat>)` provided by library:
```swift
  .bottomSheet(isPresented: $isShown, config: config.feedback(into: $requestedSize)) { // where `config` is predefined shared configuration
      ...
  }
```

That's all, folks :-)

## Bonus

### .modal

Also SwiftUIBottomSheet provides `.modal()` method because it used to present viewcontroller on wich bottom sheet is drawn. You can use it same way as SwiftUI  `.sheet` method. Main difference is that it shown over full screen instead of being sheet.

```swift
.modal(isPresenting: $isPresenting) {
  ...
}

// or

.modal(item: $optionalModel) {
  ...
}
```

More details you can find in it's code:
```swift
struct PresentationConfig {
    var style: Style = .overlay
    var transition: Transition = .slide
    var animated = true // animated transition or not

    enum Style {
        case fullscreen // nontransparent background
        case overlay // transparent background, content under it is visible
    }

    enum Transition {
        case fade // changes opacity
        case slide // slide from bottom
    }
}
```

### OvergrowScrollView
This view can help organize bottomsheet content when it's height can be dynamically changed and become too large. 
This view becomes scrollview when it's content exeeds vertical size:

```swift
struct SomeView: View {
    @Statу private var height: CGFloat = 200
    
    var body: some View {
        OvergrowScrollView(maxHeight: 300) {
            Color.green.frame(height: height)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline .now() + .seconds(5)) {
                height = 500 // view become scrollable after 5 seconds
            }
        }
    }
}
```

## Installation

### Cocoapods

```ruby
pod 'SwiftUIBottomSheet'
```

Includes Example: `pod try SwiftUIBottomSheet`

### Swift Package Manager

```
https://github.com/SyrupMG/SwiftUIBottomSheet
```

## Author

horovodovodo4ka, xbitstream@gmail.com

## License

SwiftUIBottomSheet is available under the MIT license. See the LICENSE file for more info.
