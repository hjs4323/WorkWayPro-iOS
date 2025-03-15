//
//  mainEndBottomSheet.swift
//  WorkwayVer2
//
//  Created by loyH on 8/30/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct MainEndBottomSheet: View {
    let testType: TestType
    let cancel: () -> Void
    let end: () -> Void
    
    var body: some View {
        GeometryReader{ geometry in
            VStack(alignment: .leading, spacing: 50){
                VStack(alignment: .leading, spacing: 20){
                    HStack(spacing: 0){
                        Text(testType.rawValue)
                            .font(.s_18())
                            .foregroundStyle(.mainBlue)
                        Text("를 종료하시겠습니까?")
                            .font(.s_18())
                            .foregroundStyle(.lightBlack)
                    }
                    Text("완료되지 않은 측정은 기록되지 않습니다.")
                        .font(.m_16())
                        .foregroundStyle(.lightGraySet)
                }
                .padding(.horizontal, 20)
                
                twoButton(geometry: geometry, leftName: "취소", leftAction: cancel, rightName: "종료하기", rightAction: end)
            }
            .padding(.horizontal, 20)
            .padding(.top, 45)
        }
    }
}
