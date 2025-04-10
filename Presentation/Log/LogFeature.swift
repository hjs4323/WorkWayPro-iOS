//
//  LogFeature.swift
//  WorkwayVer2
//
//  Created by loyH on 7/12/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LogFeature{
    @Reducer(state: .equatable)
    enum Path {
        case home(LogHome)
    }
    
    @ObservableState
    struct State: Equatable{
        var path = StackState<Path.State>()
        var traineeNumber = LogTraineeNumber.State()
        
        var who: String?
        
        init(who: String? = nil) {
            if let who {
                self.who = who
                self.path.append(.home(.init(who: who)))
            }
        }
    }
    
    enum Action{
        case path(StackActionOf<Path>)
        case traineeNumber(LogTraineeNumber.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.traineeNumber, action: \.traineeNumber) {
            LogTraineeNumber()
        }
        Reduce { state, action in
            switch action {
            case let .traineeNumber(.delegate(delegateAction)):
                switch delegateAction{
                case .goToHome:
                    state.who = state.traineeNumber.number
                    
                    state.path.append(.home(.init(who: state.who!)))
                    return .none
                }
                
                
            case .path:
                return .none
            case .traineeNumber:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

struct LogNavigation: View {
    @Perception.Bindable var store: StoreOf<LogFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                LogTraineeNumberView(store: self.store.scope(state: \.traineeNumber, action: \.traineeNumber))
            } destination: { store in
                switch store.case {
                case let .home(store):
                    LogHomeView(store: store)
                }
            }
        }
    }
}
