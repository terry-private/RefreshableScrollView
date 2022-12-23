import SwiftUI

public struct RefreshableScrollView<Content>: View where Content: View {
    // For ScrollView
    public let content: Content
    public let axes: Axis.Set
    public let showsIndicators: Bool
    
    // Refreshable Action
    private let action: (@Sendable () async -> Void)?
    
    // Layout
    @Namespace private var scroll
    @State private var isPull: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var scrollY: CGFloat = .zero
    @State private var progressScale: CGFloat = 1.5
    private var progressOffsY: CGFloat {
        if isPull || isRefreshing {
            return 0
        } else {
            return -max(0, min(60, 60 + scrollY)) // scrollY(0~-60)を-60~0に変換 & clip
        }
    }
    private var progressOpacity: Double {
        if isPull || isRefreshing {
            return 1
        } else {
            return min(1, max(0, -scrollY / 250)) // 0 ~ 0.25 100までで0.25
        }
    }
    private var dummySpacerHeight: CGFloat {
        if isPull || isRefreshing {
            return max(0, min(60, 60 + scrollY))
        } else {
            return 0
        }
    }
    // ボタン押下時の軽微な振動を追加する
    private let feedbackGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()
    
    // init
    public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: () -> Content, onRefresh: (@Sendable () async -> Void)? = nil) {
        self.content = content()
        self.axes = axes
        self.showsIndicators = showsIndicators
        action = onRefresh
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            ProgressView()
                .scaleEffect(x: progressScale, y: progressScale, anchor: .center)
                .padding(.vertical, 25)
                .offset(y: progressOffsY)
                .opacity(progressOpacity)
            
            ScrollView(axes, showsIndicators: showsIndicators) {
                VStack {
                    Spacer(minLength: dummySpacerHeight)
                    content
                }
                .background(GeometryReader { proxy -> Color in
                    guard action != nil else { return .clear }
                    Task { @MainActor in
                        // 現在のスクロール位置
                        scrollY = -proxy.frame(in: .named(scroll)).origin.y
                        if scrollY >= 0 {
                            if isPull {
                                Task {
                                    isRefreshing = true
                                    await action?()
                                    withAnimation {
                                        isRefreshing = false
                                    }
                                }
                                isPull = false
                            }
                        }
                        if !isPull && !isRefreshing && scrollY <= -100 {
                            feedbackGenerator.impactOccurred()
                            isPull = true
                            progressScale = 1.6 // コッという振動をanimationでも表現
                            withAnimation {
                                progressScale = 1.5
                            }
                        }
                        print(scrollY)
                    }
                    return .clear
                })
            }
            .coordinateSpace(name: scroll)
        }
        .clipped()
    }
}

struct RefreshableScrollView_Previews: PreviewProvider {
    static var previews: some View {
        RefreshableScrollView {
            LazyVStack {
                ForEach((0...100), id: \.self) { index in
                    Text(index.description)
                }
            }
        } onRefresh: {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
