//
//  TraineeList.swift
//  WorkwayVer2
//
//  Created by loyH on 7/12/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct TraineeList{
    @ObservableState
    struct State: Equatable{
        var trainees: [String] = Trainees
        var selectedTrainee: String?
    }
    
    enum Action{
        case selectTrainee(String)
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            case goToHubConnect
        }
    }
    
    var body: some ReducerOf<Self>{
        Reduce{ state, action in
            switch action{
            case let .selectTrainee(trainee):
                state.selectedTrainee = trainee
                return .send(.delegate(.goToHubConnect))
            case .delegate:
                return .none
            }
        }
    }
}

struct TraineeListView: View {
    @Perception.Bindable var store: StoreOf<TraineeList>
    
    var body: some View {
        WithPerceptionTracking{
            GeometryReader{ geometry in
                VStack(alignment: .leading){
                    Text("회원명")
                    VStack{
                        ForEach(store.trainees, id: \.self){ trainee in
                            Button(action: {
                                store.send(.selectTrainee(trainee))
                            }, label: {
                                HStack{
                                    Rectangle().frame(width: 50, height: 50)
                                    VStack(alignment: .leading){
                                        HStack{
                                            Text("\(trainee) 님")
                                            Text("010123123123")
                                        }
                                        Text("최근 측정  24.01.01")
                                    }
                                }
                            })
                           
                        }
                    }
                }
                .padding()
                .basicToolbar(title: "회원 목록")
            }
        }
    }
}

#Preview {
    TraineeListView(store: Store(initialState: TraineeList.State(), reducer:{
        TraineeList()
    }))
}
