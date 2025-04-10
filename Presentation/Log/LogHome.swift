//
//  LogHome.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 8/21/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LogHome {
    @ObservableState
    struct State: Equatable {
        var homeTab: LogHomeTab.State?
        
        var who: String
        
        var dashboards: [DashboardDTO]?
        var selectedList: [DashboardDTO]?
        var selectedDashboard: DashboardDTO?
        
        var stParams: [STParam]?
        var ftParam: FTParam?
        var etParams: [ETParamDTO]?
        var btParam: BTParam?
        
        init(who: String) {
            self.who = who
        }
    }
    
    enum Action {
        case getDashboards
        case getParams
        
        case setDashboards([DashboardDTO])
        case setParams([STParam], FTParam, [ETParamDTO], BTParam)
        case setselectedList([DashboardDTO])
        case setselectedDashboard(DashboardDTO)
        
        case showHomeTab
        
        case homeTab(LogHomeTab.Action)
        case changeTab(LogHomeTab.Tabs)
    }
    
    @Dependency(\.reportRepository) var reportRepository
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .getDashboards:
                return .run { [who = state.who] send in
                    do {
                        if let muscles = ExerciseRepository.shared.muscles {
                            let dashboards = try await reportRepository.getDashboards(who: who, startUnixTime: nil, endUnixTime: nil, muscles: muscles)
                            await send(.setDashboards(dashboards))
                        } else if let muscles = await ExerciseRepository.shared.getMuscles() {
                            let dashboards = try await reportRepository.getDashboards(who: who, startUnixTime: nil, endUnixTime: nil, muscles: muscles)
                            await send(.setDashboards(dashboards))
                        }
                    } catch {
                        print("LogHome/getDashboards: error getting dashboards \(error)")
                    }
                }
                
            case let .setDashboards(dashboards):
                state.dashboards = dashboards
                if state.selectedList == nil {
                    state.selectedList = dashboards
                }
                if state.selectedDashboard == nil {
                    state.selectedDashboard = dashboards.first
                }
                print("LOGHOME/setDashboards : \(dashboards.first?.reportETs?.first?.reportSets)")
                return .send(.showHomeTab)
                
            case let .setselectedList(selectedList):
                state.selectedList = selectedList
                return .none
                
            case let .setselectedDashboard(selectedDashboard):
                state.selectedDashboard = selectedDashboard
                return .none
                
            case .getParams:
                return .run { send in
                    do {
                        if
                            let stParams = try await reportRepository.getSTParams(),
                            let ftParam = try await reportRepository.getFTParam(),
                            let btParam = try await reportRepository.getBTParam(){
                            var etParams: [ETParamDTO] = []
                            if let exercises = await ExerciseRepository.shared.getExercises() {
                                for i in 0..<exercises.count {
                                    let exercise = exercises[i]
                                    if let etparam = try await reportRepository.getETParam(exerciseId: exercise.exerciseId) {
                                        print("id = \(exercise.exerciseId), param = \(etparam)")
                                        etParams.append(etparam)
                                    }
                                }
                            }
                            await send(.setParams(stParams, ftParam, etParams, btParam))
                        }
                    } catch {
                        print("LogHome/getParams: error \(error)")
                    }
                }
                
            case let .setParams(stParams, ftParam, etParams, btParam):
                state.stParams = stParams
                state.ftParam = ftParam
                state.etParams = etParams
                state.btParam = btParam
                return .send(.showHomeTab)
                
            case .showHomeTab:
                if
                    let selectedDashboard = state.selectedDashboard,
                    let dashboards = state.dashboards,
                    let stParams = state.stParams,
                    let ftParam = state.ftParam,
                    let etParams = state.etParams
                {
                    state.homeTab = .dashboard(.init(
                        who: state.who,
                        dashboards: dashboards,
                        selectedDashboard: selectedDashboard,
                        stParams: stParams,
                        ftParam: ftParam,
                        etParams: etParams
                    ))
                }
                return .none
                
            case let .changeTab(tab):
                guard let selectedDashboard = state.selectedDashboard, let selectedList = state.selectedList, let dashboards = state.dashboards, let stParams = state.stParams, let ftParam = state.ftParam, let etParams = state.etParams, let btParam = state.btParam else { return .none }
                switch tab {
                case .dashboard:
                    state.homeTab = .dashboard(.init(
                        who: state.who,
                        dashboards: dashboards,
                        selectedDashboard: selectedDashboard,
                        stParams: stParams,
                        ftParam: ftParam,
                        etParams: etParams
                    ))
                case .detail:
                    state.homeTab = .detail(.init(
                        who: state.who,
                        dashboards: dashboards,
                        selectedDashboard: selectedDashboard,
                        stParams: stParams,
                        ftParam: ftParam,
                        etParams: etParams,
                        btParam: btParam
                    ))
                case .history:
                    state.homeTab = .history(.init(
                        who: state.who,
                        dashboards: dashboards,
                        selectedList: selectedList,
                        stParams: stParams,
                        ftParam: ftParam,
                        etParams: etParams,
                        btParam: btParam
                    ))
                }
                return .none
                
                
            case let .homeTab(homeAction):
                switch homeAction{
                case let .dashboard(.delegate(delegateAction)):
                    switch delegateAction{
                    case let .selectDashboard(totalDashboard, dashboard):
                        state.dashboards = totalDashboard
                        state.selectedDashboard = dashboard
                        return .none
                    }
                case let .detail(.delegate(delegateAction)):
                    switch delegateAction{
                    case let .selectDashboard(totalDashboard, dashboard):
                        state.dashboards = totalDashboard
                        state.selectedDashboard = dashboard
                        return .none
                    }
                case let .history(.delegate(delegateAction)):
                    switch delegateAction{
                    case let .selectList(totalDashboard, list):
                        state.dashboards = totalDashboard
                        state.selectedList = list
                        return .none
                    }
                case .dashboard:
                    return .none
                case .detail:
                    return .none
                case .history:
                    return .none
                }
                
            }
        }
        .ifLet(\.homeTab, action: \.homeTab) {
            LogHomeTab()
        }
    }
}

struct LogHomeView: View {
    @Perception.Bindable var store: StoreOf<LogHome>
    
    @State var tabIndex: Int = 0
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0){
                if
                    let dashboards = store.dashboards
                {
                    let tabList: [LogHomeTab.Tabs]  = [.dashboard, .detail, .history]
                    
                    HStack(spacing: 0.0) {
                        Spacer().frame(width: 15)
                        ForEach(Array(tabList.enumerated()), id: \.element) { index, tab in
                                Button(action: {
                                    store.send(.changeTab(tab))
                                    tabIndex = index
                                }) {
                                    VStack{
                                        Spacer().frame(height: 16)
                                        Text(tab.rawValue)
                                            .font(.m_18())
                                            .foregroundStyle(.white)
                                        Spacer().frame(height: 14)
                                        RoundedRectangle(cornerRadius: 100)
                                            .frame(height: 2)
                                            .foregroundStyle(tabIndex == index ? .workwayBlue : .lightBlack)
                                    }
                                }
                        }
                        Spacer().frame(width: 15)
                    }
                    .background(.lightBlack)
                    
                    if !dashboards.isEmpty {
                        if let homeTabStore = store.scope(state: \
                                .homeTab, action: \.homeTab) {
                            LogHomeTabView(store: homeTabStore)
                        } else {
                            VStack {
                                Spacer()
                                Divider()
                                    .foregroundStyle(.background)
                                ProgressView()
                                Divider()
                                    .foregroundStyle(.background)
                                Spacer()
                            }
                            .background(.background)
                        }
                    } else {
                        VStack{
                            Spacer()
                            HStack{
                                Spacer()
                                Text("측정된 기록이 없어요")
                                    .font(.m_18())
                                    .foregroundStyle(.lightGraySet)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                        ProgressView()
                            .onAppear {
                                if store.dashboards == nil {
                                    store.send(.getDashboards)
                                }
                                if store.stParams == nil || store.ftParam == nil || store.etParams == nil {
                                    store.send(.getParams)
                                }
                            }
                        Spacer()
                        Divider()
                            .foregroundStyle(.background)
                    }
                    .background(.background)
                }
            }
            .background(.backgroundGray)
            .basicToolbar(
                title: "\(store.who) 님",
                darkToolBar: true
            )
        }
    }
}

#Preview {
    NavigationStack{
        LogHomeView(store: Store(initialState: LogHome.State(who: "123123123"), reducer: {
            LogHome()
        }))
    }
}
