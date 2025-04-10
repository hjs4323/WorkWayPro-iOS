//
//  LogDashboardList.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 8/21/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LogDashboardList {
    @ObservableState
    struct State: Equatable {
        let who: String
        var selectMode: SelectMode
        var dashboards: [DashboardDTO]?
        var selectedDashboard: DashboardDTO?
        var selectedList: [DashboardDTO]?
        
        enum SelectMode {
            case single
            case multi
        }
        
        init(who: String, selectMode: SelectMode, dashboards: [DashboardDTO], selectedDashboard: DashboardDTO? = nil ,selectedList: [DashboardDTO]? = nil) {
            self.who = who
            self.selectMode = selectMode
            self.dashboards = dashboards
            self.selectedDashboard = selectedDashboard
            self.selectedList = selectedList
        }
    }
    
    enum Action {
        case delegate(Delegate)
        
        case getDashboards
        case setDashboards([DashboardDTO])
        
        case selectDashboard(DashboardDTO)
        case done
        @CasePathable
        enum Delegate: Equatable {
            case selectDashboard([DashboardDTO], DashboardDTO)
            case selectList([DashboardDTO], [DashboardDTO])
        }
    }
    
    @Dependency(\.reportRepository) var reportRepository
    @Dependency(\.dismiss) var dismiss
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
                        print("LogDashboardList/getDashboards: error getting dashboards \(error)")
                    }
                }
                
            case let .setDashboards(dashboards):
                state.dashboards = dashboards
                return .none
                
            case let .selectDashboard(dashboard):
                print("1")
                switch state.selectMode {
                case .single:
                    state.selectedDashboard = dashboard
                case .multi:
                    if state.selectedList?.contains(dashboard) == true {
                        if let index = state.selectedList?.firstIndex(of: dashboard) {
                            state.selectedList?.remove(at: index)
                        }
                    } else {
                        state.selectedList?.append(dashboard)
                    }
                }
                return .none
                
            case .done:
                if let dashboards = state.dashboards {
                    switch state.selectMode {
                    case .single:
                        return .send(.delegate(.selectDashboard(dashboards, state.selectedDashboard!)))
                    case .multi:
                        return .send(.delegate(.selectList(dashboards, state.selectedList!)))
                    }
                }
                return .none
                
            case .delegate:
                return .run { _ in
                    await self.dismiss()
                }
            }
        }
    }
}


struct LogDashboardListView: View {
    @Perception.Bindable var store: StoreOf<LogDashboardList>
    
    var body: some View {
        WithPerceptionTracking {
            VStack {
                if let dashboards = store.dashboards{
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(dashboards, id: \.time) { dashboard in
                                WithPerceptionTracking {
                                    var isSelected: Bool {
                                        switch store.selectMode {
                                        case .single:
                                            return store.selectedDashboard == dashboard
                                        case .multi:
                                            return store.selectedList?.map({ $0.time }).contains(dashboard.time) == true
                                        }
                                    }
                                    dashboardCard(mode: store.selectMode, dashboard: dashboard, isSelected: isSelected)
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    okButton {
                        store.send(.done)
                    }
                    .padding(20)
                } else {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
            .basicToolbar(title: "데이터 선택")
        }
    }
    
    @ViewBuilder
    private func dashboardCard(mode: LogDashboardList.State.SelectMode, dashboard: DashboardDTO, isSelected: Bool) -> some View {
        WithPerceptionTracking {
            Button {
                store.send(.selectDashboard(dashboard))
            } label: {
                let formattedString = Double(dashboard.time).unixTimeToDateStr("yy.MM.dd (E) hh:mm")
                
                VStack(spacing: 18){
                    Divider()
                        .foregroundStyle(.whiteGray)
                    HStack(spacing: 30) {
                        Spacer().frame(width: 1)
                        switch mode {
                        case .single:
                            Circle()
                                .stroke(isSelected ? .lightBlack : .whiteLightGray, lineWidth: isSelected ? 8 : 2)
                                .frame(width: 30, height: isSelected ? 26 : 30)
                        case .multi:
                            if isSelected {
                                Image(systemName: "checkmark.square.fill")
                                    .resizable()
                                    .foregroundStyle(.lightBlack)
                                    .frame(width: 30, height: 30)
                            } else {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.whiteLightGray, lineWidth: 2)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(formattedString)
                                .font(.r_16())
                                .foregroundStyle(.lightBlack)
                            HStack(spacing: 8) {
                                if dashboard.st {
                                    Text("척추근 평가")
                                        .font(.r_12())
                                        .foregroundStyle(.lightGraySet)
                                }
                                if dashboard.ft {
                                    Text("기능 평가")
                                        .font(.r_12())
                                        .foregroundStyle(.lightGraySet)
                                }
                                if dashboard.dashboardET != nil || dashboard.bt {
                                    Text("운동 평가")
                                        .font(.r_12())
                                        .foregroundStyle(.lightGraySet)
                                }
                            }
                        }
                        Spacer()
                    }
                    Divider()
                        .foregroundStyle(.whiteGray)
                }
            }
        }
    }
}
