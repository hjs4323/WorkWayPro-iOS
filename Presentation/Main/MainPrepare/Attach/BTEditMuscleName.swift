//
//  BTEditMuscleName.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 10/25/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct BTEditMuscleName {
    @ObservableState
    struct State: Equatable {
        var originalName: String
        var name: String
        var errorMessage: String?
        var okBtnClickable: Bool = false
        
        init(name: String) {
            self.originalName = name
            self.name = name
        }
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case delegate(Delegate)
        
        case dismiss
        case clearName
        
        enum Delegate: Equatable {
            case editMuscleName(String)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action{
            case .clearName:
                state.name = ""
                state.errorMessage = nil
                state.okBtnClickable = false
                return .none
            case .dismiss:
                return .run { _ in
                    await self.dismiss()
                }
            case .binding(\.name):
                let newName = state.name
                
                if newName.isEmpty {
                    state.errorMessage = nil
                    state.okBtnClickable = false
                } else if newName.contains(" ") && newName.map({$0 != " "}).isEmpty {
                    state.errorMessage = "공백 외 문자를 입력해주세요"
                    state.okBtnClickable = false
                } else {
                    state.errorMessage = nil
                    state.okBtnClickable = true
                }
                return .none
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

struct BTEditMuscleNameView: View {
    @Perception.Bindable var store: StoreOf<BTEditMuscleName>
    
    @FocusState private var focused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            WithPerceptionTracking {
                VStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        HStack(spacing: 0){
                            Text(store.originalName)
                                .font(.m_20())
                                .foregroundStyle(.mainBlue)
                            Text("의 부위명을 수정해주세요")
                                .font(.m_20())
                        }
                        Spacer().frame(height: 12)
                        Text("이후 모든 분석 리포트에 아래 설정한 부위명이 표시됩니다")
                            .font(.m_14())
                            .foregroundColor(.lightGraySet)
                        Spacer().frame(height: 32)
                        
                        TextField("", text: $store.name)
                            .padding(20)
                            .background(.whiteGray)
                            .foregroundStyle(.lightBlack)
                            .cornerRadius(10)
                            .autocorrectionDisabled()
                            .focused($focused)
                            .overlay {
                                if let errorMessage = store.errorMessage {
                                    HStack {
                                        Text(errorMessage)
                                            .foregroundStyle(.mainRed)
                                            .font(.bodyMedium())
                                        Spacer()
                                    }
                                    .offset(y: 50)
                                }
                            }
                            .overlay(alignment: .trailing) {
                                Button("", systemImage: "xmark.circle.fill") {
                                    store.send(.clearName)
                                }
                                .foregroundStyle(.whiteLightGray)
                                .padding(.horizontal, 5)
                            }
                        Spacer()
                    }
                    .padding([.leading, .trailing], 10)

                    if focused {
                        okButton(action: {
                            UIApplication.shared.hideKeyboard()
                            store.send(.delegate(.editMuscleName(store.name)))
                        }, enable: store.okBtnClickable)
                    }
                    Spacer()
                }
                .padding(20)
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.hideKeyboard()
                }
                .onAppear{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.focused = true
                        }
                }
                .basicToolbar(
                    title: "부착 위치 설정",
                    swipeBack: false,
                    closeButtonAction: {
                        store.send(.dismiss)
                    }
                )
            }
        }
    }
}
