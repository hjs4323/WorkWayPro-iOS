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
struct LogHomeTab {
    @ObservableState
    enum State: Equatable {
        case dashboard(LogDashboardTab.State)
        case detail(LogDetailTab.State)
        case history(LogHistoryTab.State)
    }
    
    enum Tabs: String {
        case dashboard = "대시보드"
        case detail = "상세"
        case history = "변화"
    }
    
    enum Action {
        case dashboard(LogDashboardTab.Action)
        case detail(LogDetailTab.Action)
        case history(LogHistoryTab.Action)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .dashboard:
                return .none
            case .detail:
                return .none
            case .history:
                return .none
            }
        }
        .ifCaseLet(\.dashboard, action: \.dashboard) {
            LogDashboardTab()
        }
        .ifCaseLet(\.detail, action: \.detail) {
            LogDetailTab()
        }
        .ifCaseLet(\.history, action: \.history) {
            LogHistoryTab()
        }
    }
}

struct LogHomeTabView: View {
    @Perception.Bindable var store: StoreOf<LogHomeTab>
    
    var body: some View {
        switch store.state {
        case .dashboard:
            if let store = store.scope(state: \.dashboard, action: \.dashboard) {
                LogDashboardTabView(store: store)
            }
        case .detail:
            if let store = store.scope(state: \.detail, action: \.detail) {
                LogDetailTabView(store: store)
            }
        case .history:
            if let store = store.scope(state: \.history, action: \.history) {
                LogHistoryTabView(store: store)
            }
        }
    }
}
