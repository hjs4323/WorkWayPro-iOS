//
//  test2.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 9/28/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct Test2 {
    @ObservableState
    struct State: Equatable {
        
    }
    
    enum Action {
        case action
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .action:
                return .none
            }
        }
    }
}

struct TestView2: View {
    @Perception.Bindable var store: StoreOf<Test2>
    
    var body: some View {
        WithPerceptionTracking {
            VStack {
                Text("test2")
                
                Spacer()
                    .frame(height: 50)
                
                Button {
                    print("test2")
                } label: {
                    Text("print test2")
                }

            }
        }
    }
}
