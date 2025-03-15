//
//  LogTraineeNumber.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 8/21/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LogTraineeNumber {
    @ObservableState
    struct State: Equatable {
        var number: String = ""
        var errorMessage: String?
        var okBtnClickable: Bool = false
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case delegate(Delegate)
        
        case clearName
        
        enum Delegate: Equatable {
            case goToHome
        }
    }
    
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action{
                
            case .clearName:
                state.number = ""
                state.errorMessage = nil
                state.okBtnClickable = false
                return .none
                
            case .binding(\.number):
                let newNumber = state.number
                
                if newNumber.isEmpty {
                    state.errorMessage = nil
                    state.okBtnClickable = false
                } else if newNumber.prefix(3) != "010" || newNumber.count != 11 {
                    state.errorMessage = "정확한 핸드폰 번호를 입력해주세요"
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

struct LogTraineeNumberView: View {
    @Perception.Bindable var store: StoreOf<LogTraineeNumber>
    
    @FocusState private var focused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            WithPerceptionTracking {
                VStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        Text("회원의 핸드폰 번호를 입력해주세요")
                            .font(.m_20())
                        Spacer().frame(height: 12)
                        Text("아래의 번호는 회원 식별 및 분석 리포트 전송에 사용됩니다")
                            .font(.m_14())
                            .foregroundColor(.lightGraySet)
                        Spacer().frame(height: 32)
                        
                        TextField("핸드폰 번호", text: $store.number)
                            .padding(20)
                            .background(.whiteGray)
                            .foregroundStyle(.lightBlack)
                            .cornerRadius(10)
                            .autocorrectionDisabled()
                            .focused($focused)
                            .keyboardType(.numberPad)
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
                            store.send(.delegate(.goToHome))
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
                .background(Color.backgroundGray)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Image("workway_logo")
                            .resizable()
                            .frame(width: 136, height: 26)
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.lightBlack)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }
}
