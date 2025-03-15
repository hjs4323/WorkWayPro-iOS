//
//  TestView.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 9/28/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct Test {
    @Reducer(state: .equatable)
    enum Destination {
        case test(Test2)
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
    }
    
    enum Action {
        case show
        
        case destination(PresentationAction<Destination.Action>)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .show:
                state.destination = .test(.init())
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct TestView: View {
    @Perception.Bindable var store: StoreOf<Test>
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.green
                VStack {
                    Button{
                        print("something")
                    } label: {
                        Text("print someting")
                            .font(.largeTitle)
                            .foregroundStyle(.lightBlack)
                    }
                    
                    Spacer()
                        .frame(height: 100)
                    
                    Button {
                        store.send(.show)
                    } label: {
                        Text("test1")
                    }
                }
            }
            .sheet(item: $store.scope(state: \.destination?.test, action: \.destination.test)) { store in
                WithPerceptionTracking {
                    TestView2(store: store)
                        .presentationDetents([.height(100), .medium, .large])
                        .presentationBackgroundInteraction(
                            .enabled(upThrough: .height(100))
                        )
                }
            }
        }
    }
}

#Preview {
    TestView(store: Store(initialState: Test.State(), reducer: {
        Test()
    }))
}
