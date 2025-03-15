//
//  AlertView.swift
//  WorkwayVer2
//
//  Created by loyH on 8/9/24.
//

import Foundation
import SwiftUI
import UIKit

struct DoubleBtnAlertView<Content: View>: View {
    @ViewBuilder let content: Content
    
    let leftBtn: AlertButtonView
    let rightBtn: AlertButtonView
    
    var body: some View {
        
        ZStack{
            Color.black.opacity(0.7)
                .background(BlackTransparentBackground())
                .ignoresSafeArea(.all)
            VStack(spacing: 20) {
                content
                HStack(spacing: 10) {
                    leftBtn
                    rightBtn
                }
            }
            .foregroundColor(.darkGraySet)
            .padding(30)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            
        }
    }
}

struct SingleBtnAlertView<Content: View>: View {
    
    @ViewBuilder let content: Content
    
    let button: AlertButtonView
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.7)
                .background(BlackTransparentBackground())
                .ignoresSafeArea(.all)
            VStack(spacing: 20) {
                content
                button
            }
            .padding(30)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
        }
    }
}

struct NoBtnAlertView<Content: View>: View {
    
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.7)
                .background(BlackTransparentBackground())
                .ignoresSafeArea(.all)
            VStack(spacing: 20) {
                content
            }
            .padding(30)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
        }
    }
}

struct AlertModifier<Alert: View>: ViewModifier {
    @Binding var isPresent: Bool
    
    let alert: Alert
    
    func body(content: Content) -> some View {
        content
            .transaction { transaction in
                transaction.disablesAnimations = false
            }
            .fullScreenCover(isPresented: $isPresent) {
                alert
            }
            .transaction { transaction in
                transaction.disablesAnimations = true
            }
    }
}

extension View {
    func doubleBtnAlert<Content: View>(isPresented: Binding<Bool>, alert: @escaping () -> DoubleBtnAlertView<Content>) -> some View {
        return modifier(AlertModifier(isPresent: isPresented, alert: alert()))
    }
    func singleBtnAlert<Content: View>(isPresented: Binding<Bool>, alert: @escaping () -> SingleBtnAlertView<Content>) -> some View {
        return modifier(AlertModifier(isPresent: isPresented, alert: alert()))
    }
    func noBtnAlert<Content: View>(isPresented: Binding<Bool>, alert: @escaping () -> NoBtnAlertView<Content>) -> some View {
        return modifier(AlertModifier(isPresent: isPresented, alert: alert()))
    }
}
