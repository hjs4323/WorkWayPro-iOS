//
//  AlertButton.swift
//  WorkwayVer2
//
//  Created by loyH on 8/9/24.
//


import Foundation
import SwiftUI
import UIKit

enum AlertButtonType {
    case CHANGEHUB
    case CHANGE
    case SETTING
    case CLOSE
    case CONFIRM
    case CANCEL
    case DELETE
    case RETRY
    case CONNECT
    case CONNECTDISABLE
    case EXIT
    case ATTACHMODIFY
    case DELETEMODIFY
    case EXITEXERCISE
    case CONFIRMRED
    case UPDATE
    case DELETEMODULE
}

struct AlertButtonView: View {
    
    typealias Action = () -> ()
    
    @Binding var isPresented: Bool
    
    let btnText: String
    let btnColor: Color
    let textColor: Color
    let font: Font
    var disable: Bool = false
    let action: Action
    
    init(type: AlertButtonType, isPresented: Binding<Bool>, action: @escaping Action) {
        self._isPresented = isPresented
        
        switch type {
        case .CHANGEHUB:
            self.btnColor = .whiteGray
            self.textColor = .mediumGray
            self.font = .s_16()
            self.btnText = "기기 변경"
            
        case .CHANGE:
            self.btnColor = .mainRed
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "교체하기"
            
        case .SETTING:
            self.btnColor = .deepDarkGray
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "설정"
            
        case .CLOSE:
            self.btnColor = .whiteGray
            self.textColor = .mediumGray
            self.font = .s_16()
            self.btnText = "닫기"
            
        case .CANCEL:
            self.btnColor = .whiteGray
            self.textColor = .mediumGray
            self.font = .s_16()
            self.btnText = "취소"
            
        case .CONFIRM:
            self.btnColor = .deepDarkGray
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "확인"
            
        case .DELETE:
            self.btnColor = .deepDarkGray
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "삭제"
            
        case .RETRY:
            self.btnColor = .deepDarkGray
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "재시도"
            
        case .CONNECT:
            self.btnColor = .deepDarkGray
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "연결"
            
        case .CONNECTDISABLE:
            self.btnColor = .whiteGray
            self.textColor = .mediumGray
            self.font = .s_16()
            self.btnText = "연결"
            self.disable = true
            
        case .EXIT:
            self.btnColor = .deepDarkGray
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "종료"
            
        case .ATTACHMODIFY:
            self.btnColor = .deepDarkGray
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "수정"
            
        case .DELETEMODIFY:
            self.btnColor = .deepDarkGray
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "제거"
            
        case .EXITEXERCISE:
            self.btnColor = .mainRed
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "운동 종료하기"
            
        case .CONFIRMRED:
            self.btnColor = .mainRed
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "확인"
            
        case .UPDATE:
            self.btnColor = .deepDarkGray
            self.textColor = .white
            self.font = .s_16()
            self.btnText = "업데이트"
            
        case .DELETEMODULE:
            self.btnColor = .whiteGray
            self.textColor = .mediumGray
            self.font = .s_16()
            self.btnText = "클립 제거하기"
        }
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 2)
                .foregroundStyle(self.btnColor)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                .overlay {
                    Text(btnText)
                        .font(.s_16())
                        .foregroundStyle(textColor)
                }
            
        }.disabled(disable)

    }
}
