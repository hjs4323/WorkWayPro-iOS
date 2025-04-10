//
//  UIExtensions.swift
//  WORKWAY
//
//  Created by 김성욱 on 6/12/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import UIKit

extension View {
    func shadow2(color: Color = .black) -> some View {
        return self
            .compositingGroup()
            .shadow(color: color.opacity(color == .black ? 0.1 : 0.3), radius: 6, x: 0, y: 0)
    }
    
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func dismissKeyboard() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
    
    func readHeight() -> some View {
        self
            .modifier(ReadHeightModifier())
    }
}

private struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged { _ in
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

private struct ReadHeightModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    }
    
    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

///extension calculate bottomsheet height
private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

extension UIWindow {
    static var current: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                if window.isKeyWindow { return window }
            }
        }
        return nil
    }
}


extension UIScreen {
    static var current: UIScreen? {
        UIWindow.current?.screen
    }
}

extension UIApplication {
    static var safeAreaInsets: UIEdgeInsets? {
        let connectedScene = UIApplication.shared.connectedScenes.first
        let windowScene = connectedScene as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.safeAreaInsets
    }
    static var statusBarHeight: CGFloat? {
        if #available(iOS 14.0, *) {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
            return scene.statusBarManager?.statusBarFrame.height
        } else {
            return UIApplication.shared.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height
        }
    }
}

extension View {
    func fixedFont() -> some View {
        self.environment(\.sizeCategory, .medium)
    }
}

extension UIApplication {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension View {
    func basicToolbar(
        title: String,
        swipeBack: Bool = true,
        closeButtonAction: (() -> Void)? = nil,
        darkToolBar: Bool = false
    ) -> some View {
        self.toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.s_16())
                    .foregroundStyle(darkToolBar ? .white : .lightBlack )
            }
            
            if let closeButtonAction = closeButtonAction {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        closeButtonAction()
                    }, label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 20, height: 20)
                    })
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!swipeBack)
        .toolbarBackground(darkToolBar ? .lightBlack : .white)
    }
}



