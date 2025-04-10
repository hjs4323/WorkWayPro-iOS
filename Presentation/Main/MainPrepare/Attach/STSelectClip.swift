//
//  STSelectClip.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 10/25/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import CoreBluetooth


@Reducer
struct STSelectClip{
    @ObservableState
    struct State: Equatable{
        var endBottomSheetShown: Bool = false
        
        var testType: TestType
        var order: Int = 1
        
        var maxAttached: Bool {
            if testType == .SPINE {
                return order >= 2
            }
            else {
                return order >= 8
            }
        }
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        
        case delegate(Delegate)
        enum Delegate: Equatable {
            case goToSelectClip
            case goToMainList
            case startSt
            case startBt
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.reportRepository) var reportRepository
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce {state, action in
            switch action {
            case .binding:
                return .none
                
            case .toggleEndBottomSheetShown:
                state.endBottomSheetShown.toggle()
                return .none
              
            case .delegate:
                return .none
            }
        }
    }
}

struct STSelectClipView: View {
    @Perception.Bindable var store: StoreOf<STSelectClip>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var muscleName: String {
        if store.testType == .SPINE {
            if store.order % 2 == 1 {
                return "왼쪽"
            }
            else {
                return "오른쪽"
            }
        }
        else {
            return "\(store.order)번"
        }
    }
    
    var body: some View {
        GeometryReader{ geometry in
            WithPerceptionTracking {
                VStack(spacing: 0){
                    VStack(alignment: .leading){
                        Spacer()
                        
                        HStack(spacing: 0){
                            Text("\(muscleName) 근육")
                                .font(.s_20())
                                .foregroundColor(.mainBlue)
                            Text("에")
                                .font(.s_20())
                                .foregroundColor(.lightBlack)
                        }
                        Spacer().frame(height: 12)
                        Text("사용할 클립의 버튼을 눌러주세요")
                            .font(.s_20())
                            .foregroundColor(.lightBlack)
                        
                        Spacer()
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Image(bluetoothManager.tempClip != nil ? "clip_background_connected" : "clip_background")
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
                        
                    }
                    .padding([.leading, .trailing], 10)
                    
                    
                    if store.testType == .SPINE {
                        okButton(name: "\(muscleName) 사용하기",
                                 action: {
                            if bluetoothManager.tempClip != nil {
                                print("clip: \(bluetoothManager.tempClip!.macAddress)")
                                bluetoothManager.addClip()
                                if store.maxAttached {
                                    store.send(.delegate(.startSt))
                                    bluetoothManager.setIsAttachingClip(false)
                                } else {
                                    store.send(.delegate(.goToSelectClip))
                                }
                            }
                        }, enable: bluetoothManager.tempClip != nil)
                    }
                    else {
                        twoButton(
                            geometry: geometry,
                            leftName: "추가 부착",
                            leftAction: {
                                bluetoothManager.addClip()
                                store.send(.delegate(.goToSelectClip))
                            },
                            rightName: "부착 완료",
                            rightAction: {
                                bluetoothManager.addClip()
                                store.send(.delegate(.startBt))
                                bluetoothManager.setIsAttachingClip(false)
                            },
                            enable: bluetoothManager.tempClip != nil
                        )
                    }
                }
                .padding(20)
                .onAppear {
                    Task {
                        bluetoothManager.setIsAttachingClip(true)
                        if bluetoothManager.tempClip != nil{
                            await bluetoothManager.clearTemp()
                            try? await Task.sleep(nanoseconds: 300_000_000)
                        }
                        while bluetoothManager.clips.count >= store.order{
                            print("removedclip")
                            bluetoothManager.removeClip(getTemp: false)
                        }
                    }
                }
                .basicToolbar(
                    title: "부착 위치 설정",
                    swipeBack: store.order != 1,
                    closeButtonAction: {
                        store.send(.toggleEndBottomSheetShown)
                    }
                )
                .sheet(isPresented: $store.endBottomSheetShown, content: {
                    MainEndBottomSheet(
                        testType: store.testType == .SPINE ? .SPINE: .EXER,
                        cancel: {
                            store.send(.toggleEndBottomSheetShown)
                        },
                        end: {
                            Task {
                                await bluetoothManager.refreshAll()
                            }
                            bluetoothManager.setIsAttachingClip(false)
                            store.send(.delegate(.goToMainList))
                        })
                    .presentationDetents([.height(230)])
                })
            }
        }
    }
}
