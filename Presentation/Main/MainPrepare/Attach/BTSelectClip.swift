//
//  BTSelectClip.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 10/25/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import CoreBluetooth


@Reducer
struct BTSelectClip{
    @Reducer(state: .equatable)
    enum Destination {
        case edit(BTEditMuscleName)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        
        let setIndex: Int
        var originalNames: [String]
        var muscleName: [String]
        var endBottomSheetShown: Bool = false
        var order: Int = 0
        
        var maxAttached: Bool {
            return order >= 7
        }
        
        init(setIndex: Int, muscleName: [String], originalNames: [String], order: Int = 0) {
            self.setIndex = setIndex
            self.originalNames = originalNames
            self.muscleName = muscleName
            if muscleName.count <= order {
                self.muscleName.append("\(muscleName.count + 1)번 근육")
            }
            self.order = order
        }
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        case goToEdit
        case startBt
        
        case destination(PresentationAction<Destination.Action>)
        
        case delegate(Delegate)
        enum Delegate: Equatable {
            case goToSelectClip
            case goToMainList
            case startBt([String])
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
                
            case .goToEdit:
                state.destination = .edit(.init(name: state.muscleName[state.order]))
                return .none
                
            case .startBt:
                state.muscleName = Array(state.muscleName.prefix(state.order + 1))

                return .send(.delegate(.startBt(state.muscleName)))
                
            case let .destination(.presented(.edit(.delegate(delegateAction)))):
                switch delegateAction {
                case let .editMuscleName(muscleName):
                    state.destination = nil
                    state.muscleName[state.order] = muscleName
                    return .none
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

struct BTSelectClipView: View {
    @Perception.Bindable var store: StoreOf<BTSelectClip>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        GeometryReader{ geometry in
            WithPerceptionTracking {
                VStack(spacing: 0){
                    VStack(alignment: .leading){
                        Spacer().frame(height: geometry.size.height * 80 / 858)
                        
                        HStack(spacing: 0){
                            Text(store.muscleName[store.order])
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
                        
                        Spacer().frame(height: geometry.size.height * 100 / 858)
                        
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
                    }
                    .padding([.leading, .trailing], 10)
                    
                    if bluetoothManager.tempClip != nil {
                        VStack(spacing: 0){
                            HStack{
                                Spacer()
                                Button(action: {
                                    store.send(.goToEdit)
                                }, label: {
                                    HStack(spacing: 10){
                                        Image(systemName: "pencil")
                                            .resizable()
                                            .frame(width: 14, height: 14)
                                            .foregroundStyle(.whiteLightGray)
                                        Text("부위명 수정")
                                            .font(.m_16())
                                            .foregroundStyle(.darkGraySet)
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 15)
                                    .background(.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 30))
                                    .shadow2()
                                })
                                Spacer()
                            }
                            
                            Spacer().frame(height: 30)
                            if store.setIndex == 0 { //첫 부착이면
                                if store.order != 7{
                                    twoButton(
                                        geometry: geometry,
                                        leftName: "부착 완료",
                                        leftAction: {
                                            bluetoothManager.addClip()
                                            store.send(.startBt)
                                            bluetoothManager.setIsAttachingClip(false)
                                        },
                                        rightName: "추가 부착하기",
                                        rightAction: {
                                            bluetoothManager.addClip()
                                            store.send(.delegate(.goToSelectClip))
                                        }
                                    )
                                } else {
                                    okButton(
                                        name: "부착 완료",
                                        action: {
                                            bluetoothManager.addClip()
                                            store.send(.startBt)
                                            bluetoothManager.setIsAttachingClip(false)
                                        }
                                    )
                                }
                            } else {
                                if store.order + 1 < store.originalNames.count {
                                    okButton(
                                        name: "추가 부착하기",
                                        action: {
                                            bluetoothManager.addClip()
                                            store.send(.delegate(.goToSelectClip))
                                        }
                                    )
                                } else {
                                    okButton(
                                        name: "부착 완료",
                                        action: {
                                            bluetoothManager.addClip()
                                            store.send(.startBt)
                                            bluetoothManager.setIsAttachingClip(false)
                                        }
                                    )
                                }
                            }
                        }
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
                        while bluetoothManager.clips.count > store.order{
                            print("removedclip")
                            bluetoothManager.removeClip(getTemp: false)
                        }
                    }
                }
                .basicToolbar(
                    title: "부착 위치 설정",
                    swipeBack: store.order != 0,
                    closeButtonAction: {
                        store.send(.toggleEndBottomSheetShown)
                    }
                )
                .fullScreenCover(item: $store.scope(state: \.destination?.edit, action: \.destination.edit), content: { store in
                    NavigationStack {
                        WithPerceptionTracking {
                            BTEditMuscleNameView(store: store)
                        }
                    }
                })
                .sheet(isPresented: $store.endBottomSheetShown, content: {
                    MainEndBottomSheet(
                        testType: .EXER,
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
