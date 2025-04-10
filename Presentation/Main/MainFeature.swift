//
//  MeasurementFeature.swift
//  WorkwayVer2
//
//  Created by loyH on 7/12/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct MainFeature{
    @Reducer(state: .equatable)
    enum Path {
        case traineeList(TraineeList)
        case bluetoothPairing(MainBluetoothPairing)
        case addTraineeNumber(AddTraineeNumber)
        case mainList(MainList)
        
        case traineeSearch(TraineeSearch)
    }
    
    @ObservableState
    struct State: Equatable{
        var path = StackState<Path.State>()
        var home = MainHome.State()
        
        var startTime: Int?
        var selectedTest: TestType?
        var number: String = ""
        var stReports: [ReportST?] = []
        var ftReports: [ReportFTDTO?] = []
        var etReports: [ReportETDTO] = []
        var btReports: [ReportBTDTO] = []
    }
    
    enum Action{
        case delegate(Delegate)
        
        case path(StackActionOf<Path>)
        case home(MainHome.Action)
        
        enum Delegate {
            case gotoLog(String)
        }
    }
    
    var body: some ReducerOf<Self>{
        Scope(state: \.home, action: \.home){
            MainHome()
        }
        Reduce {state, action in
            switch action{
            case let .path(.element(id: id, action: .traineeList(.delegate(delegateAction)))):
                switch delegateAction{
                case .goToHubConnect:
                    print("hubConnect")
                    state.path.append(.bluetoothPairing(MainBluetoothPairing.State()))
                    return .none
                }
                
            case let .path(.element(id: id, action: .addTraineeNumber(.delegate(delegateAction)))):
                guard case let .some(.addTraineeNumber(detailState)) = state.path[id: id] else { return .none }
                switch delegateAction{
                case .goToHubConnect:
                    state.number = detailState.number
                    state.path.append(.bluetoothPairing(MainBluetoothPairing.State()))
                    return .none
                }
                
            case let .path(.element(id: id, action: .bluetoothPairing(.delegate(delegateAction)))):
                switch delegateAction{
                case .goToMainList:
                    switch state.selectedTest{
                    case .SPINE:
                        state.stReports = [nil]
                    case .FUNC:
                        state.ftReports = [nil]
                    case .EXER:
                        break
                    case .BRIEF:
                        break
                    case .none:
                        return .none
                    }
                    state.startTime = Int(Date().timeIntervalSince1970)
                    state.path.append(.mainList(.init(
                        destination: state.selectedTest == .EXER ? .addTestBottomSheet(.init()) : nil,
                        who: state.number,
                        startTime: state.startTime!,
                        stReports: state.stReports,
                        ftReports: state.ftReports,
                        etReports: state.etReports,
                        btReports: state.btReports
                    )))
                    return .none
                case .goToStartTest:
                    return .none
                }
                
            case let .path(.element(id: id, action: .mainList(.delegate(delegateAction)))):
                switch delegateAction{
                case .goToRecentLog:
                    return .send(.delegate(.gotoLog(state.number)))
                case .goToHome:
                    state.path.removeAll()
                    state.stReports.removeAll()
                    state.ftReports.removeAll()
                    state.etReports.removeAll()
                    return .none
                }
                
            case .path:
                return .none
                
            case let .home(.delegate(delegateAction)):
                switch delegateAction{
                case .goToTraineeList:
                    state.path.append(.traineeList(TraineeList.State()))
                    return .none
                case let .startTest(testType):
                    state.selectedTest = testType
                    state.path.append(.addTraineeNumber(AddTraineeNumber.State()))
                    return .none
                case .goToTraineeSearch:
                    state.path.append(.traineeSearch(TraineeSearch.State()))
                    return .none
                }
                
            case .home:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

struct MainNavigation: View {
    
    @Perception.Bindable var store: StoreOf<MainFeature>
    
    @StateObject var bluetoothManager: BluetoothManager = .init()
    
    var body: some View {
        WithPerceptionTracking{
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                WithPerceptionTracking {
                    MainHomeView(store: self.store.scope(state: \.home, action: \.home))
                }
            } destination: { store in
                WithPerceptionTracking {
                    switch store.case {
                    case let .traineeList(store):
                        TraineeListView(store: store)
                    case let .addTraineeNumber(store):
                        AddTraineeNumberView(store: store)
                    case let .bluetoothPairing(store):
                        MainBluetoothPairingView(store: store)
                    case let .mainList(store):
                        MainListView(store: store)
                    case let .traineeSearch(store):
                        TraineeSearchView(store: store)
                    }
                }
            }
            .environmentObject(bluetoothManager)
        }
        
    }
    
        
}
