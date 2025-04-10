//
//  MainAddTest.swift
//  WorkwayVer2
//
//  Created by loyH on 8/8/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct MainAddTest{
    @ObservableState
    struct State: Equatable{
        var searchName: String = ""
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case dismiss
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            case add(ReportType)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce{ state, action in
            switch action {
            case .binding:
                return .none
            case .dismiss:
                return .run { _ in
                    await dismiss()
                }
                
            case .delegate(.add):
                return .send(.dismiss)
            case .delegate:
                return .none
            }
        }
    }
}


struct MainAddTestView: View {
    @Perception.Bindable var store: StoreOf<MainAddTest>
    @FocusState private var focused: Bool
    
    @State var exercises: [ExerciseDTO]? = ExerciseRepository.shared.exercises
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 30){
                Text("종목 추가")
                    .font(.s_18())
                    .foregroundStyle(.lightBlack)
                    .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 30){
                        HStack{
                            Image(systemName: "magnifyingglass")
                            TextField("종목 이름을 검색해주세요", text: $store.searchName)
                                .foregroundStyle(focused ? .lightBlack : .mediumGray)
                                .font(.r_16())
                                .autocorrectionDisabled()
                                .focused($focused)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.backgroundGray)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        if(store.searchName.isEmpty || "척추근 평가".contains(store.searchName)){
                            VStack(alignment: .leading, spacing: 20){
                                Text("척추근 평가")
                                    .font(.s_16())
                                    .foregroundStyle(.lightBlack)
                                VStack(spacing: 25){
                                    bottomSheetTestCard(
                                        name: "척추근 평가",
                                        recentTime: 0,
                                        part: "등",
                                        addTest: {
                                            store.send(.delegate(.add(ReportType(testType: .SPINE, exid: 0, name: TestType.SPINE.rawValue))))
                                        }
                                    )
                                }
                            }
                        }
                        
                        if(store.searchName.isEmpty || "기능 평가".contains(store.searchName)){
                            VStack(alignment: .leading, spacing: 20){
                                Text("기능 평가")
                                    .font(.s_16())
                                    .foregroundStyle(.lightBlack)
                                VStack(spacing: 25){
                                    bottomSheetTestCard(
                                        name: "기능 평가",
                                        recentTime: 0,
                                        part: "하체",
                                        addTest: {
                                            store.send(.delegate(.add(ReportType(testType: .FUNC, exid: 0, name: TestType.FUNC.rawValue))))
                                        }
                                    )
                                }
                            }
                        }
                        
                        if let exercises = exercises {
                            if !exercises.filter({ $0.name.contains(store.searchName) }).isEmpty || store.searchName.isEmpty {
                                VStack(alignment: .leading, spacing: 20){
                                    Text("운동 평가")
                                        .font(.s_16())
                                        .foregroundStyle(.lightBlack)
                                    VStack(spacing: 25){
                                        if
                                            store.searchName.isEmpty ||
                                                "자율 측정".contains(store.searchName){
                                            bottomSheetTestCard(
                                                name: "자율 측정",
                                                recentTime: 0,
                                                addTest: {
                                                    store.send(.delegate(.add(ReportType(testType: .BRIEF, exid: 0, name: TestType.BRIEF.rawValue))))
                                                }
                                            )
                                        }
                                        ForEach(exercises.indices) { i in
                                            if
                                                store.searchName.isEmpty ||
                                                exercises[i].name.contains(store.searchName) {
                                                bottomSheetTestCard(
                                                    name: exercises[i].name,
                                                    recentTime: 0,
                                                    part: ExercisePartNameMap[exercises[i].part],
                                                    addTest: {
                                                        store.send(.delegate(.add(ReportType(testType: .EXER, exid: exercises[i].exerciseId, name: exercises[i].name))))
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            HStack{
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .onAppear{
                                Task {
                                    print("exercises = \(exercises)")
                                    print("repo exercises = \(ExerciseRepository.shared.exercises)")
                                    while(exercises == nil) {
                                        try? await Task.sleep(nanoseconds: 100_000_000)
                                        exercises = await ExerciseRepository.shared.getExercises()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                
                okButton(name: "닫기", action: {
                    store.send(.dismiss)
                })
            }
            .padding(20)
        }
    }
    
    @ViewBuilder
    private func bottomSheetTestCard(
        name: String,
        recentTime: Int? = nil,
        part: String? = nil,
        addTest: @escaping () -> Void
    ) -> some View {
        Button(action: {
            addTest()
        }, label: {
            HStack(spacing: 25){
                Image("exercise_picture")
                    .resizable()
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 8){
                    Text(name)
                        .font(.m_16())
                        .foregroundStyle(.lightBlack)
                }
                
                Spacer()
                
                if let part = part{
                    Text(part)
                        .font(.s_12())
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .foregroundStyle(.lightBlack)
                        .background(.whiteGray)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        })
    }
}


@Reducer
struct MainListSelectPart{
    @ObservableState
    struct State: Equatable{
        var selectedPart: Int = 0
    }
    
    enum Action {
        case setPart(Int)
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            case setPart(Int)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce {state, action in
            switch action {
            case let .setPart(part):
                state.selectedPart = part
                return .run { send in
                    await send(.delegate(.setPart(part)))
                    await dismiss()
                }
                
            case .delegate:
                return .none
            }
            
        }
    }
}

struct MainListSelectPartView: View {
    @Perception.Bindable var store: StoreOf<MainListSelectPart>
    let parts: [String] = ["전체", "등", "가슴", "어깨"]
    
    var body: some View {
        VStack(spacing: 55){
            Text("측정 부위")
                .font(.s_18())
                .foregroundStyle(.lightBlack)
            
            VStack(spacing: 25){
                ForEach(parts.indices){ index in
                    Button(action: {
                        store.send(.setPart(index))
                    }, label: {
                        HStack(spacing: 20){
                            Image("")
                                .frame(width: 30, height: 30)
                            Text(parts[index])
                                .font(.m_16())
                                .foregroundStyle(.lightBlack)
                            Spacer()
                            if store.selectedPart == index {
                                Image(systemName: "checkmark")
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.mainBlue)
                            }
                        }
                    })
                }
            }
            .padding(.leading, 30)
            .padding(.trailing, 25)
        }
        .padding(.vertical, 30)
    }
}

