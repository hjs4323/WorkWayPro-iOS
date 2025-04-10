//
//  AttachMuscle.swift
//  WorkwayVer2
//
//  Created by loyH on 8/8/24.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct AttachMuscle{
    @Reducer(state: .equatable)
    enum Destination {
        case clip(AttachClip)
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        var endBottomSheetShown: Bool = false
        var tabIndex: Int = 0
        
        var attachMuscle: MuscleDTO
        var testType: TestType
        var isLeft: Bool = true
        
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        
        case setAttachMuscle(MuscleDTO)
        case goToClip
        case delegate(Delegate)
        
        case destination(PresentationAction<Destination.Action>)
        enum Delegate: Equatable {
            case goToMain
            case goToMainList
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce {state, action in
            switch action {
            case .binding:
                return .none
                
            case .toggleEndBottomSheetShown:
                state.endBottomSheetShown.toggle()
                return .none
                
            case let .setAttachMuscle(muscle):
                state.attachMuscle = muscle
                return .none
                
            case .goToClip:
                state.destination = .clip(.init(
                    attachMuscle: state.attachMuscle,
                    testType: state.testType,
                    isLeft: false
                ))
                return .none
                
            case let .destination(.presented(.clip(.delegate(delegateAction)))):
                guard case let .clip(detailState) = state.destination else { return .none }
                switch delegateAction {
                case .goToMain:
                    return .send(.delegate(.goToMain))
                case .goToMainList:
                    return .send(.delegate(.goToMainList))
                }
                
            case .destination:
                return .none
            case .delegate:
                return .none
           
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}


struct AttachMuscleView: View {
    @Perception.Bindable var store: StoreOf<AttachMuscle>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    
    var body: some View {
        GeometryReader { fullGeometry in
            WithPerceptionTracking{
                VStack(alignment: .leading, spacing: 0){
                    let muscle: MuscleDTO? = ExerciseRepository.shared.getMusclesById(mid: (store.attachMuscle.id) + (store.isLeft ? 0 : 1))
                    
                    VStack(alignment: .leading){
                        Spacer()
                        HStack(spacing: 0){
                            Text((muscle?.isLeft == true ? "왼쪽 " : "오른쪽 ") ?? "오류")
                                .font(.s_20())
                                .foregroundColor(.mainBlue)
                            Text(muscle?.name ?? "오류")
                                .font(.s_20())
                                .foregroundColor(.mainBlue)
                            Text("에 기기를 부착해주세요")
                                .font(.s_20())
                                .foregroundColor(.lightBlack)
                        }
                        Spacer().frame(height: 12)
                        Text("아래 그림의 노란색 X 지점에 기기를 부착해주세요")
                            .font(.m_16())
                            .foregroundColor(.lightGraySet)
                        
                        Spacer().frame(height: 40)
                        
                        HStack{
                            Spacer()
                            Image("attach/\(store.attachMuscle.id)")
                                .resizable()
                                .frame(width: 250, height: 250)
                            Spacer()
                        }
                        .frame(height: 250)
                        
                        Spacer()
                        HStack{
                            Spacer()
                            HStack(spacing: 0) {
                                Spacer().frame(width: 10)
                                Image("clip")
                                    .resizable()
                                    .aspectRatio(62/70, contentMode: .fit)
                                    .frame(height: 43)
                                    .padding(.vertical, 20)
                                Spacer().frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\(bluetoothManager.clips.count + 1)개 연결 중")
                                        .font(.r_16())
                                    let battery = bluetoothManager.tempClip?.battery
                                    BatteryView(battery: battery)
                                }
                                
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 20)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow2()
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding([.leading, .trailing], 10)
                    
                    
                    okButton(
                        name: "다음",
                        action: {
                            if bluetoothManager.tempClip != nil {
                                print("clip: \(bluetoothManager.tempClip!.macAddress)")
                                bluetoothManager.tempClip?.muscleId = muscle?.id ?? 0
                                bluetoothManager.addClip()
                            }
                            store.send(store.isLeft ? .goToClip : .delegate(.goToMain))
                        }
                    )
                    
                    Spacer().frame(height: 19)
                } //최외곽 vstack
                .basicToolbar(
                    title: "부착 위치 설정",
                    closeButtonAction: {
                        store.send(.toggleEndBottomSheetShown)
                    }
                )
                .navigationDestination(item: $store.scope(state: \.destination?.clip, action: \.destination.clip)) { store in
                    AttachClipView(store: store)
                }
                .onAppear{
                    if bluetoothManager.tempClip == nil {
                        bluetoothManager.removeClip()
                    }
                }
                .sheet(isPresented: $store.endBottomSheetShown, content: {
                    WithPerceptionTracking{
                        MainEndBottomSheet(
                            testType: store.testType,
                            cancel: {
                                store.send(.toggleEndBottomSheetShown)
                            },
                            end: {
                                store.send(.delegate(.goToMainList))
                            })
                        .presentationDetents([.height(230)])
                    }
                })
            }
            .padding(.horizontal, 16)
        }
    }
}
