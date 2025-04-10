//
//  BtWeightCount.swift
//  WorkwayVer2
//
//  Created by loyH on 9/13/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


@Reducer
struct BtWeightCount{
    @Reducer(state: .equatable)
    enum Destination {
        case report(BtReport)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        var endBottomSheetShown: Bool = false
        
        let who: String
        var reportBTs: [ReportBTDTO]
        var reportBTsNotToday: [ReportBTDTO]?
        let selectedBTName: String
        var selectedBTIndex: Int {
            self.reportBTs.firstIndex(where: { $0.name == self.selectedBTName })!
        }
        let setIndex: Int
        
        var count: Int?
        var weight: Int?
        
        var pickerShown: Bool = false
        
        enum PickerMode{
            case weight
            case count
        }
        
        var pickerMode: PickerMode = .weight
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
            case goToMainList(ReportBTDTO)
            case setReportBTsNotToday([ReportBTDTO])
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
                withAnimation(.smooth(duration: 0.2)){
                    state.pickerShown = false
                }
                return .none
                
            case .goToReport:
                
                let btIndex = state.selectedBTIndex
                let setIndex = state.setIndex
                state.reportBTs[btIndex].reportSets[setIndex]!.weight = state.weight
                state.reportBTs[btIndex].reportSets[setIndex]!.count = state.count
                state.pickerShown = false
                
                print("BTWeightcount/gotoReport: selectedReportBT = \(state.reportBTs[btIndex])")
                state.destination = .report(.init(setIndex: state.setIndex, initMuscleName: nil, reports: state.reportBTs, reportsNotToday: state.reportBTsNotToday, selectedReportName: state.selectedBTName, isFromLog: false))
                
                return .run { [ rSet = state.reportBTs[state.selectedBTIndex].reportSets[state.setIndex] ] send in
                    if let rSet {
                        try await reportRepository.setBTWeightCount(reportSetId: rSet.reportId, weight: rSet.weight, count: rSet.count)
                    }
                }
                
            case let .destination(.presented(.report(.delegate(delegateAction)))):
                switch delegateAction{
                case let .goToMainList(bt):
                    return .send(.delegate(.goToMainList(bt)))
                case let .setReportBTsNotToday(bts):
                    return .send(.delegate(.setReportBTsNotToday(bts)))
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

struct BtWeightCountView: View {
    @Perception.Bindable var store: StoreOf<BtWeightCount>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        WithPerceptionTracking{
            GeometryReader{ geometry in
                WithPerceptionTracking {
                    VStack(spacing: 0){
                        VStack(alignment: .leading, spacing: 0){
                            if store.pickerShown {
                                Spacer().frame(height: 25)
                                HStack{
                                    Text("자율 측정")
                                        .font(.m_20())
                                        .foregroundStyle(.lightBlack)
                                    Spacer()
                                    Text("\(store.setIndex + 1) 세트")
                                        .font(.m_16())
                                        .foregroundStyle(.darkGraySet)
                                }
                                Spacer().frame(height: 40)
                            } else {
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
                                        Text("자율 측정")
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
                                    Text("\(store.weight != nil ? String(store.weight!) : "--") kg")
                                        .font(.m_16())
                                        .foregroundStyle(store.weight != nil ? .lightBlack : .lightGraySet)
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
                                    Text("\(store.count != nil ? String(store.count!) : "--") 회")
                                        .font(.m_16())
                                        .foregroundStyle(store.count != nil ? .lightBlack : .lightGraySet)
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
                            }
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
                        BtReportView(store: store, swipeBack: false)
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
                                                .tag(count as Int?)
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
                                                .tag(count as Int?)
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
                                    store.send(.delegate(.goToMainList(store.reportBTs[store.selectedBTIndex])))
                                })
                            .presentationDetents([.height(230)])
                        }
                    })
                }
            }
        }
    }
}
