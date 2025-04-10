//
//  EtAttaceClip.swift
//  WorkwayVer2
//
//  Created by loyH on 8/8/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct AttachClip{
    @Reducer(state: .equatable)
    enum Destination {
        case muscle(AttachMuscle)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        var endBottomSheetShown: Bool = false
        
        var attachMuscle: MuscleDTO
        var testType: TestType
        var isLeft: Bool = true
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        
        case movePrev
        case goToMuscle
        
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)
        enum Delegate: Equatable {
            case goToMain
            case goToMainList
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .toggleEndBottomSheetShown:
                state.endBottomSheetShown.toggle()
                return .none
                
            case .goToMuscle:
                state.destination = .muscle(.init(
                    attachMuscle: state.attachMuscle,
                    testType: state.testType,
                    isLeft: state.isLeft
                ))
                return .none
                
            case .movePrev:
                return .run { _ in
                    await self.dismiss()
                }
                
            case let .destination(.presented(.muscle(.delegate(delegateAction)))):
                guard case let .muscle(detailState) = state.destination else { return .none }
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


struct AttachClipView: View {
    @Perception.Bindable var store: StoreOf<AttachClip>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                Text("사용할 클립의 버튼을 눌러주세요")
                    .font(.s_20())
                    .foregroundColor(.lightBlack)
                Spacer().frame(height: 12)
                Text("버튼을 누르면 자동으로 연결됩니다")
                    .font(.m_16())
                    .foregroundColor(.lightGraySet)
                
                Spacer()
                Spacer()
                
                HStack {
                    Spacer()
                    Image("clip_background_connected")
                        .resizable()
                        .frame(width: geometry.size.width * 233/393, height: geometry.size.width * 233/393)
                        .overlay{
                            Image("clip")
                                .resizable()
                                .aspectRatio(140/150, contentMode: .fit)
                                .frame(width: geometry.size.width * 140/393)
                        }
                    Spacer()
                }
                Spacer()
                Spacer()
                Spacer()
                
            }//최외곽 VStack
            .padding(.horizontal, 16)
            .basicToolbar(
                title: "부착 위치 설정",
                closeButtonAction: {
                    store.send(.toggleEndBottomSheetShown)
                }
            )
            .onChange(of: bluetoothManager.tempClip) { newValue in
                if newValue != nil {
                    store.send(.goToMuscle)
                }
            }
            .task {
                bluetoothManager.setIsAttachingClip(true)
                await bluetoothManager.clearTemp()
            }
            .onDisappear(perform: {
                bluetoothManager.setIsAttachingClip(false)
            })
            .navigationDestination(item: $store.scope(state: \.destination?.muscle, action: \.destination.muscle)) { store in
                AttachMuscleView(store: store)
            }
            .sheet(isPresented: $store.endBottomSheetShown, content: {
                MainEndBottomSheet(
                    testType: store.testType,
                    cancel: {
                        store.send(.toggleEndBottomSheetShown)
                    },
                    end: {
                        store.send(.delegate(.goToMainList))
                    })
                .presentationDetents([.height(230)])
            })
            
        }
    }
    
}
