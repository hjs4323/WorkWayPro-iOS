//
//  EtWeightCount.swift
//  WorkwayVer2
//
//  Created by loyH on 8/14/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


@Reducer
struct EtWeightCount{
    @Reducer(state: .equatable)
    enum Destination {
        case report(EtReport)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        var endBottomSheetShown: Bool = false
        
        let who: String
        var report: ReportETDTO
        var rawDatas: [[Float]]
        let exercise: ExerciseDTO?
        let setIndex: Int
        
        var count: Int
        var weight: Int
        
        var pickerShown: Bool = false
        
        enum PickerMode{
            case weight
            case count
        }
        
        var pickerMode: PickerMode = .weight
        
        init(who: String, report: ReportETDTO, rawDatas: [[Float]], exercise: ExerciseDTO?, setIndex: Int) {
            self.destination = nil
            self.endBottomSheetShown = false
            self.who = who
            self.report = report
            self.rawDatas = rawDatas
            self.exercise = exercise
            self.setIndex = setIndex
            self.count = 10
            self.weight = exercise?.dfWei ?? -1
            
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        
        case showCountPicker
        case showWeightPicker
        case closePicker
        
        case goToReport
        
        case destination(PresentationAction<Destination.Action>)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case goToMainList(ReportETSetDTO)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.reportRepository) var reportRepository
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce {state, action in
            switch action {
            case .binding:
                return .none
                
            case .toggleEndBottomSheetShown:
                state.endBottomSheetShown.toggle()
                return .none
                
            case .showCountPicker:
                withAnimation(.smooth(duration: 0.2)){
                    state.pickerShown = true
                    state.pickerMode = .count
                }
                return .none
                
            case .showWeightPicker:
                withAnimation(.smooth(duration: 0.2)){
                    state.pickerShown = true
                    state.pickerMode = .weight
                }
                return .none
                
            case .closePicker:
                withAnimation{
                    state.pickerShown = false
                }
                return .none
                
            case .goToReport:
                if let index = state.report.reportSets?.lastIndex(where: { $0 != nil}){
                    state.report.reportSets![index]!.weight = state.weight
                    state.report.reportSets![index]!.repCount = state.count
                    print("reportSet = \(state.report.reportSets![index]!)")
                    state.destination = .report(.init(report: state.report, rawDatas: state.rawDatas, setIndex: index, isFromLog: false))
                    
                    return .run { [report = state.report.reportSets![index]!] send in
                        try await reportRepository.setETWeightCount(setReportId: report.reportId, weight: report.weight, count: report.repCount)
                    }
                }
                return .none
                
            case let .destination(.presented(.report(.delegate(delegateAction)))):
                switch delegateAction{
                case let .goToMainList(et):
                    return .send(.delegate(.goToMainList(et)))
                }
            
            case .destination:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct EtWeightCountView: View {
    @Perception.Bindable var store: StoreOf<EtWeightCount>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        WithPerceptionTracking{
            let setReport: ReportETSetDTO = store.report.reportSets![store.setIndex]!
            GeometryReader{ geometry in
                VStack(spacing: 0){
                    VStack(alignment: .leading, spacing: 0){
                        if store.pickerShown {
                            Spacer().frame(height: 25)
                            HStack{
                                Text(store.exercise?.name ?? "오류")
                                    .font(.m_20())
                                    .foregroundStyle(.lightBlack)
                                Spacer()
                                Text("\(store.setIndex + 1) 세트")
                                    .font(.m_16())
                                    .foregroundStyle(.darkGraySet)
                            }
                            Spacer().frame(height: 40)
                        }
                        else{
                            Spacer().frame(height: 40)
                            Text("세트 정보")
                                .font(.m_20())
                                .foregroundStyle(.lightBlack)
                            Spacer().frame(height: 20)
                            
                            HStack(alignment: .center, spacing: 30){
                                Image("exercise_picture")
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                VStack(alignment: .leading, spacing: 10){
                                    Text(store.exercise?.name ?? "오류")
                                        .font(.m_16())
                                        .foregroundStyle(.lightBlack)
                                    Text("\(store.setIndex + 1) 세트")
                                        .font(.m_16())
                                        .foregroundStyle(.darkGraySet)
                                }
                            }
                            
                            Spacer().frame(height: 50)
                        }
                        
                        Text("중량")
                            .font(.m_20())
                            .foregroundStyle(.lightBlack)
                        Spacer().frame(height: 20)
                        
                        Button(action: {
                            store.send(.showWeightPicker)
                        }, label: {
                            HStack {
                                Text("\(store.weight != -1 ? String(store.weight) : "--") kg")
                                    .font(.m_16())
                                    .foregroundStyle(store.weight != -1 ? .lightBlack : .lightGraySet)
                                Spacer()
                            }
                            .padding(20)
                            .background(.whiteGray)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        })
                        
                        
                        Spacer().frame(height: 50)
                        
                        Text("횟수")
                            .font(.m_20())
                            .foregroundStyle(.lightBlack)
                        Spacer().frame(height: 20)
                        
                        Button(action: {
                            store.send(.showCountPicker)
                        }, label: {
                            HStack {
                                Text("\(store.count != -1 ? String(store.count) : "--") 회")
                                    .font(.m_16())
                                    .foregroundStyle(store.count != -1 ? .lightBlack : .lightGraySet)
                                Spacer()
                            }
                            .padding(20)
                            .background(.whiteGray)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        })
                       
                    }
                    .padding(.horizontal, 10)
                    Spacer()
                    
                    okButton(
                        name: "\(store.setIndex + 1)세트 리포트 보기",
                        action: {
                            store.send(.goToReport)
                        },
                        enable: store.count != -1 && store.weight != -1
                    )
                    if store.pickerShown {
                        Spacer().frame(height: 207)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .basicToolbar(
                    title: "운동 평가",
                    closeButtonAction: {
                        store.send(.toggleEndBottomSheetShown)
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    store.send(.closePicker)
                }
                .navigationDestination(item: $store.scope(state: \.destination?.report, action: \.destination.report)) { store in
                    EtReportView(store: store, swipeBack: false)
                }
                .sheet(isPresented: $store.pickerShown, content: {
                    WithPerceptionTracking {
                        VStack(alignment: .trailing) {
                            HStack {
                                Spacer()
                                Button(action: {
                                    store.send(.closePicker)
                                }, label: {
                                    Text("완료")
                                        .font(.r_16())
                                        .foregroundStyle(.deepDarkGray)
                                        .padding()
                                })
                            }
                            switch store.pickerMode {
                            case .count:
                                let countArray = Array(0..<100)
                                Picker("count", selection: $store.count) {
                                    ForEach(countArray, id: \.self) { count in
                                        Text("\(String(count)) 회")
                                            .font(.s_22())
                                            .foregroundStyle(.deepDarkGray)
                                    }
                                }
                                .scaleEffect(1.5)
                                .pickerStyle(.wheel)
                            case .weight:
                                let weightArray = Array(stride(from: 0, to: 205, by: 5))
                                Picker("weight", selection: $store.weight) {
                                    ForEach(weightArray, id: \.self) { count in
                                        Text("\(String(count)) kg")
                                            .font(.s_22())
                                            .foregroundStyle(.deepDarkGray)
                                    }
                                }
                                .scaleEffect(1.5)
                                .pickerStyle(.wheel)
                            }
                           
                            Spacer()
                                .frame(height: 25)
                        }
                        .presentationDetents([.height(207)])
                        .presentationBackgroundInteraction(
                            .enabled(upThrough: .height(207))
                        )
                    }
                })
                .sheet(isPresented: $store.endBottomSheetShown, content: {
                    WithPerceptionTracking {
                        MainEndBottomSheet(
                            testType: .EXER,
                            cancel: {
                                store.send(.toggleEndBottomSheetShown)
                            },
                            end: {
                                store.send(.delegate(.goToMainList(setReport)))
                            })
                        .presentationDetents([.height(230)])
                    }
                })
            }
        }
    }
}
