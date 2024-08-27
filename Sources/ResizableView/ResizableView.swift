import SwiftUI

public struct ResizableView<Content: View>: View {
    init(size: Binding<CGFloat>, side: Side, onSizeChanged: ((CGFloat) -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        _size = size
        self.side = side
        self.content = content
        self.onSizeChanged = onSizeChanged
    }

    @State private var isPressed: Bool = false
    @Binding private var size: CGFloat

    private let side: Side
    private let content: () -> Content

    private let onSizeChanged: ((CGFloat) -> Void)?

    public var body: some View {
        side.size(withValue: size) {
            side.stretchContainer {
                GeometryReader { geo in
                    genericStack {
                        if side.shouldContentBeBeforeDivider {
                            side.stretchContent {
                                content()
                            }
                        }
                        Divider()
                            .onHover { perform in
                                guard !isPressed else { return }
                                if perform {
                                    side.setCursor()
                                } else {
                                    NSCursor.arrow.set()
                                }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                                    .onChanged { value in
                                        self.isPressed = true
                                        side.setCursor()

                                        if let newSize = side.calculateSize(from: value.location, in: geo) {
                                            self.size = newSize
                                        }
                                    }
                                    .onEnded { _ in
                                        self.isPressed = false

                                        if let onSizeChanged {
                                            onSizeChanged(size)
                                        }
                                    }
                            )

                        if !side.shouldContentBeBeforeDivider {
                            side.stretchContent {
                                content()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private func genericStack<BlockContent: View>(@ViewBuilder content: @escaping () -> BlockContent) -> some View {
        switch side {
        case .leading, .trailing:
            HStack(spacing: 0) {
                content()
            }
        case .top, .bottom:
            VStack(spacing: 0) {
                content()
            }
        }
    }

    public enum Side {
        case leading, trailing, top, bottom

        func setCursor() {
            switch self {
            case .leading, .trailing:
                NSCursor.resizeLeftRight.set()
            case .top, .bottom:
                NSCursor.resizeUpDown.set()
            }
        }

        var shouldContentBeBeforeDivider: Bool {
            switch self {
            case .trailing, .bottom:
                true
            case .leading, .top:
                false
            }
        }

        func calculateSize(from point: CGPoint, in geo: GeometryProxy) -> CGFloat? {
            switch self {
            case .leading:
                geo.frame(in: .global).maxX - point.x
            case .trailing:
                point.x > 20 ? point.x - geo.frame(in: .global).minX : nil
            case .top:
                geo.frame(in: .global).maxY - point.y
            case .bottom:
                point.y > 20 ? point.y - geo.frame(in: .global).minY : nil
            }
        }

        @ViewBuilder func size<SizeContent: View>(withValue size: CGFloat, @ViewBuilder content: @escaping () -> SizeContent) -> some View {
            switch self {
            case .leading, .trailing:
                content().frame(width: size)
            case .top, .bottom:
                content().frame(height: size)
            }
        }

        @ViewBuilder func stretchContent<SizeContent: View>(@ViewBuilder content: @escaping () -> SizeContent) -> some View {
            switch self {
            case .leading, .trailing:
                content().frame(maxWidth: .infinity)
            case .top, .bottom:
                content().frame(maxHeight: .infinity)
            }
        }

        @ViewBuilder func stretchContainer<SizeContent: View>(@ViewBuilder content: @escaping () -> SizeContent) -> some View {
            switch self {
            case .leading, .trailing:
                content().frame(maxHeight: .infinity)
            case .top, .bottom:
                content().frame(maxWidth: .infinity)
            }
        }
    }
}
