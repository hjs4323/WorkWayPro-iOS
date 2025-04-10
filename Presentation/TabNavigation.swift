//
//  TabNavigation.swift
//  WorkwayVer2
//
//  Created by loyH on 7/12/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct TabNavigation {
    @ObservableState
    struct State: Equatable{
        
        var measurement: MainFeature.State? = MainFeature.State()
        var log: LogFeature.State?
        var setting: SettingMain.State?
        
        var screen: Screen
        
        enum Screen: Equatable {
            case measurement
            case log
            case setting
        }
        
        init(){
            self.screen = .measurement
            self.measurement = MainFeature.State()
        }
    }
    
    
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        
        case measurement(MainFeature.Action)
        case log(LogFeature.Action)
        case setting(SettingMain.Action)
        
        case changeTab(State.Screen)
    }
    
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action{
            case let .changeTab(newTab):
                guard state.screen != newTab else { return .none }
                switch newTab{
                case .measurement:
                    state.measurement = MainFeature.State()
                case .log:
                    state.log = LogFeature.State()
                case .setting:
                    state.setting = SettingMain.State()
                }
                state.screen = newTab
                return .none
                
            case let .measurement(.delegate(.gotoLog(who))):
                state.log = LogFeature.State(who: who)
                state.screen = .log
                return .none
                
            case .measurement:
                return .none
            case .log:
                return .none
            case .setting:
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.measurement, action: /Action.measurement) {
            MainFeature()
        }
        .ifLet(\.log, action: /Action.log) {
            LogFeature()
        }
        .ifLet(\.setting, action: \.setting) {
            SettingMain()
        }
    }
}

struct TabNavigationView: View {
    @Perception.Bindable var store: StoreOf<TabNavigation>
    @StateObject var forceUpdateViewModel: ForceUpdateViewModel = .init()
    
    @StateObject private var keyboardObserver = KeyboardObserver()
    
    let tabSize: CGFloat = 2
    
    var body: some View {
        GeometryReader { geometry in
            WithPerceptionTracking {
                VStack(spacing: 0){
                    
                    let noUpdate: [ForceUpdateViewModel.UpdateCases] = [.noUpdate, .isRecommended]
                    if noUpdate.contains(forceUpdateViewModel.isUpdateNeeded)  {
                        
                        switch store.screen{
                        case .measurement:
                            MainNavigation(store: self.store.scope(state: \.measurement!, action: \.measurement))
                        case .log:
                            LogNavigation(store: self.store.scope(state: \.log!, action: \.log))
                        case .setting:
                            MainNavigation(store: self.store.scope(state: \.measurement!, action: \.measurement))
                        }
                        
                        var isBottomBar: Bool {
                            if keyboardObserver.isKeyboardVisible {
                                return false
                            }
                            switch store.screen{
                            case .measurement:
                                if store.measurement!.path.count > 0 {
                                    return false
                                }
                            case .log:
                                return true
                            case .setting:
                                return true
                            }
                            return true
                        }
                        
                        if isBottomBar {
                            HStack(spacing: 0.0){
                                Button(action: {
                                    store.send(.changeTab(.measurement))
                                }, label: {
                                    VStack(spacing: 5){
                                        Image(systemName: "dumbbell.fill")
                                            .foregroundColor(store.screen == .measurement ? .workwayBlue : .mediumGray)
                                            .frame(width: geometry.size.width / tabSize, height: 24)
                                            .font(.system(size: 20))
                                        Text("측정")
                                            .foregroundColor(store.screen == .measurement ? .white : .mediumGray)
                                    }
                                })
                                
                                Button(action: {
                                    store.send(.changeTab(.log))
                                }, label: {
                                    VStack(spacing: 5){
                                        Image(systemName: "chart.bar.fill")
                                            .foregroundColor(store.screen == .log ? .workwayBlue : .mediumGray)
                                            .frame(width: geometry.size.width / tabSize, height: 24)
                                            .font(.system(size: 20))
                                        Text("분석")
                                            .foregroundColor(store.screen == .log ? .white : .mediumGray)
                                    }
                                })
                            }
                            .frame(height: 56)
                            .background(.black)
                            .font(.labelLarge())
                        }
                    }
                }
                .singleBtnAlert(isPresented: .constant(forceUpdateViewModel.isUpdateNeeded == .isForced), alert: {
                    SingleBtnAlertView(content: {
                        VStack {
                            Text("필수 업데이트 버전이 있어요")
                                .font(.r_16())
                                .foregroundStyle(.lightBlack)
                            Spacer().frame(height: 12)
                            Text("보다 쾌적한 사용을 위해 앱을 업데이트 해 주세요")
                                .font(.r_14())
                                .foregroundStyle(.mediumGray)
                        }
                    }, button: AlertButtonView(type: .UPDATE, isPresented: .constant(forceUpdateViewModel.isUpdateNeeded == .isForced), action: {
                        if let url = URL(string: "itms-apps://itunes.apple.com/app/6605929363"),
                                            UIApplication.shared.canOpenURL(url)
                        {
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            } else {
                                UIApplication.shared.openURL(url)
                            }
                        }
                    }))
                })
            }
        }
    }
}

#Preview {
    TabNavigationView(store: Store(initialState: TabNavigation.State(), reducer: {
        TabNavigation()
    }))
}
