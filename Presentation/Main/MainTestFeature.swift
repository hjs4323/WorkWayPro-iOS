//
//  MainTestFeature.swift
//  WorkwayVer2
//
//  Created by loyH on 8/13/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct MainTestFeature{
    @Reducer(state: .equatable)
    enum Path {
        case bluetoothPairing(MainBluetoothPairing)
        case attach(AttachMain)
        case selectST(STSelectClip)
        case selectBT(BTSelectClip)
        case spine(StMain)
        case functional(FtMain)
        case exercise(EtMain)
        case brief(BtMain)
    }
    
    @ObservableState
    struct State: Equatable{
        var path = StackState<Path.State>()
        var who: String
        let dashboardTime: Int
        
        let reportType: ReportType
        var setIndex: Int?
        
        var etReport: ReportETDTO?
        var selectedBTName: String?
        var selectedBT: ReportBTDTO {
            self.reportBTs.first(where: { $0.name == selectedBTName })!
        }
        
        var reportBTs: [ReportBTDTO]
        var reportBTsNotToday: [ReportBTDTO]?
        
        init(who: String, dashboardTime: Int, reportType: ReportType, etReport: ReportETDTO? = nil, selectedBTName: String, setIndex: Int?, hubEnable: Bool, reportBTs: [ReportBTDTO], reportBTsNotToday: [ReportBTDTO]?, skipAttach: Bool) {
            self.who = who
            self.dashboardTime = dashboardTime
            
            self.etReport = etReport
            self.reportBTs = reportBTs
            self.reportBTsNotToday = reportBTsNotToday
            
            self.reportType = reportType
            self.setIndex = setIndex
            self.selectedBTName = selectedBTName
            
            if hubEnable{
                switch reportType.testType {
                case .SPINE:
                    self.path.append(.selectST(.init(testType: .SPINE)))
                case .FUNC:
                    self.path.append(.attach(.init()))
                case .EXER:
                    self.path.append(.attach(.init(
                        exercise: ExerciseRepository.shared.getExercisesById(exerciseId: etReport!.exerciseId)
                    )))
                case .BRIEF:
                    if skipAttach {
                        if
                            let selectedBTIndex = reportBTs.firstIndex(where: { $0.name == selectedBTName })
                        {
                            let setIndex = reportBTs[selectedBTIndex].reportSets.firstIndex(where: { $0 == nil }) ?? 0
                            self.path.append(.brief(.init(who: who, dashboardTime: dashboardTime, selectedBTName: selectedBTName, setIndex: setIndex, todayReports: reportBTs, movePrevAvailable: false)))
                        }
                    } else {
                        self.path.append(.selectBT(.init(setIndex: setIndex ?? 0, muscleName: selectedBT.muscleName, originalNames: selectedBT.muscleName)))
                    }
                }
            }
            else{
                self.path.append(.bluetoothPairing(.init(testType: reportType.testType)))
            }
        }
    }
    
    enum Action{
        case path(StackActionOf<Path>)
        
        case goToMainList((any Report)?)
        case delegate(Delegate)
        @CasePathable
        enum Delegate{
            case setReportETId(Int, String)
            case setReportBT(ReportBTDTO)
            case setMuscleName(String, [String])
            case goToMainList((any Report)?, ReportType)
            case goToMainListBT(ReportBTDTO?)
            case setReportBTsNotToday([ReportBTDTO])
            case setLastTestAttach(ReportType)
        }
    }
    
    @Dependency(\.reportRepository) var reportRepository
    var body: some ReducerOf<Self>{
        Reduce {state, action in
            switch action{
            case let .goToMainList(report):
                return .send(.delegate(.goToMainList(report, state.reportType)))
            
            case let .path(.element(id: id, action: .bluetoothPairing(.delegate(delegateAction)))):
                guard case let .some(.bluetoothPairing(detailState)) = state.path[id: id] else { return .none }
                switch delegateAction{
                case .goToMainList:
                    return .send(.goToMainList(nil))
                case .goToStartTest:
                    switch state.reportType.testType {
                    case .SPINE:
                        state.path.append(.selectST(.init(testType: .SPINE)))
                        return .none
                    case .FUNC:
                        state.path.append(.attach(.init()))
                        return .none
                    case .EXER:
                        state.path.append(.attach(.init(
                            exercise: ExerciseRepository.shared.getExercisesById(exerciseId: state.etReport!.exerciseId)
                        )))
                        return .none
                    case .BRIEF:
                        state.path.append(.selectBT(.init(setIndex: state.setIndex ?? 0, muscleName: state.selectedBT.muscleName, originalNames: state.selectedBT.muscleName)))
                        return .none
                    }
                }
                
            case let .path(.element(id: id, action: .attach(.delegate(delegateAction)))):
                guard case let .some(.attach(detailState)) = state.path[id: id] else { return .none }
                switch delegateAction{
                case .goToMainList:
                    return .send(.goToMainList(nil))
                case .startFt:
                    state.path.append(.functional(.init(who: state.who, dashboardTime: state.dashboardTime, setIndex: state.setIndex!)))
                    return .send(.delegate(.setLastTestAttach(.init(testType: .FUNC, exid: 0, name: ""))))
                case .startEt:
                    state.path.append(.exercise(.init(who: state.who, report: state.etReport!, exercise: detailState.exercise)))
                    return .send(.delegate(.setLastTestAttach(.init(testType: .EXER, exid: detailState.exercise?.exerciseId ?? 0, name: detailState.exercise?.name ?? ""))))
                }
                
            case let .path(.element(id: id, action: .selectST(.delegate(delegateAction)))):
                guard case let .some(.selectST(detailState)) = state.path[id: id] else { return .none }
                switch delegateAction{
                case .goToSelectClip:
                    state.path.append(.selectST(.init(testType: state.reportType.testType, order: detailState.order + 1)))
                    return .none
                case .goToMainList:
                    return .send(.goToMainList(nil))
                case .startSt:
                    state.path.append(.spine(.init(who: state.who, dashboardTime: state.dashboardTime)))
                    return .none
                case .startBt:
                    return .none
                }
                
            case let .path(.element(id: id, action: .selectBT(.delegate(delegateAction)))):
                guard case let .some(.selectBT(detailState)) = state.path[id: id] else { return .none }
                switch delegateAction{
                case .goToSelectClip:
                    state.path.append(.selectBT(.init(setIndex: detailState.setIndex, muscleName: detailState.muscleName, originalNames: detailState.originalNames, order: detailState.order + 1)))
                    return .none
                case .goToMainList:
                    return .send(.goToMainList(nil))
                case let .startBt(muscleName):
                    if
                        let selectedBTIndex = state.reportBTs.firstIndex(where: { $0.name == state.selectedBTName }),
                            let selectedBTName = state.selectedBTName
                    {
                        state.reportBTs[selectedBTIndex].muscleName = muscleName
                        let setIndex = state.reportBTs[selectedBTIndex].reportSets.firstIndex(where: { $0 == nil }) ?? 0
                        state.path.append(.brief(.init(who: state.who, dashboardTime: state.dashboardTime, selectedBTName: selectedBTName, setIndex: setIndex, todayReports: state.reportBTs, movePrevAvailable: true)))
                    }
                    if detailState.originalNames != muscleName {
                        return .send(.delegate(.setMuscleName(state.selectedBT.name, muscleName)))
                    } else {
                        return .send(.delegate(.setLastTestAttach(.init(testType: .BRIEF, exid: 0, name: state.selectedBT.name))))
                    }
                }
            
                
            case let .path(.element(id: _, action: .spine(.delegate(delegateAction)))):
                switch delegateAction{
                case let .goToMainList(st):
                    return .send(.goToMainList(st))
                }
                
            case let .path(.element(id: _, action: .functional(.delegate(delegateAction)))):
                switch delegateAction{
                case let .goToMainList(ft):
                    return .send(.goToMainList(ft))
                }
                
            case let .path(.element(id: _, action: .exercise(.delegate(delegateAction)))):
                switch delegateAction{
                case let .setReportId(reportId):
                    state.etReport?.reportId = reportId
                    if let exid = state.etReport?.exerciseId {
                        return .send(.delegate(.setReportETId(exid, reportId)))
                    }
                    return .none
                    
                case let .goToMainList(et):
                    return .send(.goToMainList(et))
                }
                
            case let .path(.element(id: _, action: .brief(.delegate(delegateAction)))):
                switch delegateAction{
                case let .goToMainList(bt):
                    return .send(.delegate(.goToMainListBT(bt)))
                case let .setReport(rBT):
                    return .send(.delegate(.setReportBT(rBT)))
                case let .setReportBTsNotToday(bts):
                    return .send(.delegate(.setReportBTsNotToday(bts)))
                }
                
            case .path:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

struct MainTestNavigation: View {
    @Perception.Bindable var store: StoreOf<MainTestFeature>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        WithPerceptionTracking{
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                EmptyView()
                    .navigationTitle("")
            } destination: { store in
                switch store.case {
                case let .bluetoothPairing(store):
                    MainBluetoothPairingView(store: store)
                case let .attach(store):
                    AttachMainView(store: store)
                case let .selectST(store):
                    STSelectClipView(store: store)
                case let .selectBT(store):
                    BTSelectClipView(store: store)
                case let .spine(store):
                    StMainView(store: store)
                case let .functional(store):
                    FtMainView(store: store)
                case let .exercise(store):
                    EtMainView(store: store)
                case let .brief(store):
                    BtMainView(store: store)
                }
            }
        }
    }
        
}
