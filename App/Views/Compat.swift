import SwiftUI

// macOS 12 (and Xcode 14 / Swift 5.7, the newest that runs there) stand-ins for what Vikey uses from macOS 13.

extension MainActor {
    /// MainActor.assumeIsolated (Swift 5.9); Swift 5.7 has no way to say it, so the closure is called as is.
    static func assumeIsolatedCompat(_ body: @MainActor () -> Void) {
        #if compiler(>=5.9)
        MainActor.assumeIsolated(body)
        #else
        dispatchPrecondition(condition: .onQueue(.main))
        withoutActuallyEscaping(body) { unsafeBitCast($0, to: (() -> Void).self)() }
        #endif
    }
}

/// LabeledContent; on macOS 12 the label on the left, the control on the right.
struct Row<Content: View, Label: View>: View {
    @ViewBuilder let content: () -> Content
    @ViewBuilder let label: () -> Label

    var body: some View {
        if #available(macOS 13.0, *) {
            LabeledContent(content: content, label: label)
        } else {
            HStack {
                label()
                Spacer()
                content()
            }
        }
    }
}

extension View {
    /// The settings form: grouped and not scrolling (macOS 13); macOS 12 has neither, it gets padding.
    @ViewBuilder func settingsFormStyle() -> some View {
        if #available(macOS 13.0, *) {
            formStyle(.grouped).scrollDisabled(true)
        } else {
            padding(.horizontal, 20).padding(.top, 12)
        }
    }

    /// lineLimit(2, reservesSpace: true): always two lines tall.
    @ViewBuilder func twoLinesReserved() -> some View {
        if #available(macOS 13.0, *) {
            lineLimit(2, reservesSpace: true)
        } else {
            ZStack(alignment: .topLeading) {
                Text("A\nA").hidden()
                lineLimit(2)
            }
        }
    }
}
