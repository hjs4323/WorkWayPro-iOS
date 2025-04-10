//
//  ClearBackground.swift
//  LAYR
//
//  Created by 김성욱 on 1/6/24.
//

import Foundation
import SwiftUI
import UIKit

//https://iosangbong.tistory.com/5

struct BlackTransparentBackground: UIViewRepresentable {
    
    public func makeUIView(context: Context) -> UIView {
        
        let view = BlackTransparentBackgroundView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear/*UIColor.black.withAlphaComponent(0.7)*/
        }
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}

class BlackTransparentBackgroundView: UIView {
    open override func layoutSubviews() {
        guard let parentView = superview?.superview else {
            return
        }
        parentView.backgroundColor = .clear
    }
}
