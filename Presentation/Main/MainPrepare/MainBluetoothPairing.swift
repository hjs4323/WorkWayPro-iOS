//
//  HubConnect.swift
//  WorkwayVer2
//
//  Created by loyH on 7/12/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import CoreBluetooth

@Reducer
struct MainBluetoothPairing {
    @ObservableState
    struct State: Equatable {
        var testType: TestType?
        var endBottomSheetShown: Bool = false
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        case delegate(Delegate)
        enum Delegate: Equatable {
            case goToStartTest
            case goToMainList
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce {state, action in
            switch action {
            case .toggleEndBottomSheetShown:
                state.endBottomSheetShown.toggle()
                return .none
                
            case .delegate:
                return .none
            case .binding:
                return .none
            }
        }
    }
    
}

struct MainBluetoothPairingView: View {
    @Perception.Bindable var store: StoreOf<MainBluetoothPairing>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    @State var selectedPeripheral: CBPeripheral? = nil
    
    var body: some View {
        GeometryReader{ geometry in
            WithPerceptionTracking {
                VStack{
                    VStack(alignment: .leading, spacing:0){
                        
                        Spacer().frame(height: 20)
                        
                        Text("허브를 연결해주세요")
                            .font(.s_20())
                            .foregroundColor(.lightBlack)
                        Spacer().frame(height: 30)
                        HStack{
                            Spacer()
                            Image("hub")
                                .resizable()
                                .aspectRatio(206/216, contentMode: .fit)
                                .frame(width: geometry.size.width * 206/393)
                            Spacer()
                        }
                        Spacer().frame(height: 50)
                        
                        HStack{
                            Text("기기 목록")
                                .font(.m_16())
                                .foregroundColor(.lightBlack)
                            if(!bluetoothManager.discoveredPeripherals.isEmpty){
                                if(bluetoothManager.scanTimer != nil){
                                    ProgressView()
                                        .frame(width: 15, height: 15)
                                }
                                else{
                                    Button{
                                        bluetoothManager.startScan(withDuration: 30)
                                    } label:{
                                        Image(systemName: "arrow.clockwise")
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            }
                        }
                        
                        if(bluetoothManager.discoveredPeripherals.isEmpty){
                            VStack{
                                Spacer()
                                HStack{
                                    Spacer()
                                    ProgressView()
                                        .frame(height: 50)
                                    Spacer()
                                }
                                Spacer()
                            }
                        } else{
                            ScrollView{
                                Spacer().frame(height:27)
                                ForEach(bluetoothManager.discoveredPeripherals, id: \.name){ peripheral in
                                    Button {
                                        selectedPeripheral = peripheral
                                    } label: {
                                        HStack(spacing:0){
                                            Text(peripheral.name ?? "이름 오류")
                                            Spacer()
                                            Image(systemName: selectedPeripheral == peripheral ? "checkmark.circle.fill" : "circle")
                                                .frame(width: 20, height: 20)
                                                .foregroundStyle(selectedPeripheral == peripheral ? .deepDarkGray : .mediumGray)
                                        }
                                        .padding([.leading, .trailing], 30)
                                        .padding([.top, .bottom], 25)
                                        .background(.white)
                                        .cornerRadius(5)
                                        .shadow2()
                                        .overlay{
                                            if(selectedPeripheral == peripheral){
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(.lightGraySet, lineWidth: 1)
                                            }
                                        }
                                    }
                                    Spacer().frame(height: 16)
                                }
                            }
                            Spacer()
                        }
                        
                        
                    }
                    .padding([.leading, .trailing], 10)
                    
                    okButton(action: {
                        bluetoothManager.connectToPeripheral(selectedPeripheral!)
                        store.send(.delegate(store.testType == nil ? .goToMainList : .goToStartTest))
                    }, enable: selectedPeripheral != nil)
                }
                .padding(20)
                .basicToolbar(
                    title: "기기 연결",
                    swipeBack: store.testType == nil,
                    closeButtonAction: store.testType == nil ? nil : {store.send(.toggleEndBottomSheetShown)}
                )
                .onAppear{
                    if bluetoothManager.connectedPeripheral != nil {
                        Task{
                            await bluetoothManager.refreshAll()
                        }
                    }
                    bluetoothManager.startScan(withDuration: 30.0)
                }
                .sheet(isPresented: $store.endBottomSheetShown, content: {
                    WithPerceptionTracking{
                        MainEndBottomSheet(
                            testType: store.testType!,
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
        }
    }
    
}
