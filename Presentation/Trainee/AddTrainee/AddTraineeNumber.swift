//
//  AddTraineeNumber.swift
//  WorkwayVer2
//
//  Created by loyH on 7/15/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct AddTraineeNumber{
    @ObservableState
    struct State: Equatable{
        var number: String = ""
        var errorMessage: String?
        var okBtnClickable: Bool = false
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case setNumber(String)
        
        case delegate(Delegate)
        enum Delegate: Equatable {
            case goToHubConnect
        }
    }
    
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action{
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
                
            case let .setNumber(newVal):
                state.number = newVal
                return .none
                
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

struct AddTraineeNumberView: View {
    @Perception.Bindable var store: StoreOf<AddTraineeNumber>
    

    @FocusState private var focused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            WithPerceptionTracking {
                VStack{
                    VStack(alignment: .leading, spacing:0){
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
                            .overlay{
                                if let errorMessage = store.errorMessage {
                                    HStack{
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
                                    store.send(.setNumber(""))
                                }
                                .foregroundStyle(.whiteLightGray)
                                .padding(.horizontal, 5)
                            }
                        Spacer()
                        
                    }
                    .padding([.leading, .trailing], 10)

                    okButton(action: {
                            store.send(.delegate(.goToHubConnect))
                        }, enable: store.okBtnClickable)
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
                .basicToolbar(title: "회원 추가")
            }
        }
    }
}

#Preview {
    AddTraineeNumberView(store: Store(initialState: AddTraineeNumber.State(), reducer:{
        AddTraineeNumber()
    }))}
