//
//  LogHistoryDetailET.swift
//  WorkwayVer2
//
//  Created by loyH on 8/28/24.
//


import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LogHistoryDetailET {
    @Reducer(state: .equatable)
    enum Destination {
        case dashboardList(LogDashboardList)
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        
        let who: String
        let exercise: ExerciseDTO
        var dashboards: [DashboardDTO]
        var selectedList: [DashboardDTO]
        let etParam: ETParamDTO
    }
    
    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)
        
        case goToDashboardList
        
        enum Delegate: Equatable {
            case dashboardListSelected([DashboardDTO], [DashboardDTO])
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case let .destination(.presented(.dashboardList(.delegate(delegateAction)))):
                switch delegateAction {
                case .selectDashboard:
                    return .none
                case let .selectList(allDashboards, selectedDashboards):
                    state.dashboards = allDashboards
                    state.selectedList = selectedDashboards
                    return .send(.delegate(.dashboardListSelected(allDashboards, selectedDashboards)))
                }
                
            case .goToDashboardList:
                state.destination = .dashboardList(.init(who: state.who, selectMode: .multi, dashboards: state.dashboards, selectedList: state.selectedList))
                return .none
                
            case .delegate:
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct LogHistoryDetailETView : View {
    @Perception.Bindable var store: StoreOf<LogHistoryDetailET>
    
    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack {
                    HStack {
                        DashboardFilterButton()
                        Spacer()
                    }
                    .padding([.horizontal, .top], 20)
                    .padding(.bottom, 14)
                    
                    let reportETs = store.selectedList.compactMap({ $0.reportETs }).flatMap({ $0 }).filter({ $0.exerciseId == store.exercise.exerciseId })
                    
                    let recent7 = Array(reportETs.sorted(by: { $0.dashboardTime > $1.dashboardTime }).take(reportETs.count < 7 ? reportETs.count : 7).reversed())
                    
                    ScoreHistory(recent7: recent7)
                    
                    Spacer().frame(minHeight: 16)
                    
                    ActivationHistory(recent7: recent7, etParam: store.etParam)
                    
                    Spacer().frame(minHeight: 16)
                    
                    WeightHistory(recent7: recent7)
                }
                .background(.backgroundGray)
                .basicToolbar(title: store.exercise.name)
                .navigationDestination(item: $store.scope(state: \.destination?.dashboardList, action: \.destination.dashboardList)) { store in
                    LogDashboardListView(store: store)
                }
            }
        }
    }
    
    @ViewBuilder
    private func DashboardFilterButton() -> some View {
        WithPerceptionTracking {
            Button(action: {
                store.send(.goToDashboardList)
            }, label: {
                HStack(spacing: 5){
                    var firstTime: String {
                        if let timeInterval = store.selectedList.first?.time{
                            let formattedString = Double(timeInterval).unixTimeToDateStr("yy.MM.dd")
                            return formattedString
                        }
                        else {
                            return "오류"
                        }
                    }
                    var lastTime: String {
                        if let lastSelected = store.selectedList.last, let lastDashboard = store.dashboards.last {
                            if lastDashboard == lastSelected {
                                return "최근 검사"
                            }
                            let formattedString = Double(lastSelected.time).unixTimeToDateStr("yy.MM.dd")
                            return formattedString
                        }
                        else {
                            return "오류"
                        }
                    }
                    
                    Image("funnel")
                        .frame(width: 14, height: 14)
                    Text("\(firstTime)~\(lastTime)")
                        .font(.m_14())
                        .foregroundStyle(.lightBlack)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow2()
            })
        }
    }
    
    private struct ScoreHistory: View {
        
        let recent7: [ReportETDTO]
        
        var body: some View {
            
            VStack {
                Spacer().frame(height: 5)
                HStack{
                    Text("점수 변화")
                        .font(.s_18())
                        .foregroundStyle(.lightBlack)
                    Spacer()
                }
                .padding(20)
                
                Divider()
                
                let timeIntervals = recent7.map({ Double($0.dashboardTime) })
                LineGraph(
                    title: "평균 점수",
                    unit: "점",
                    labels: timeIntervals.unixTimeToDateStrForGraph(),
                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
                    scores: recent7.map({ $0.reportSets?.compactMap({ $0?.score }).average() ?? 0.0 }),
                    minStandard: 80,
                    maxStandard: 100
                )
                .frame(height: 180)
                .padding(20)
            }
            .background(.background)
        }
    }
    
    private struct ActivationHistory: View {
        
        let recent7: [ReportETDTO]
        let etParam: ETParamDTO
        
        var body: some View {
            
            VStack {
                Spacer().frame(height: 5)
                HStack{
                    Text("활성도 변화")
                        .font(.s_18())
                        .foregroundStyle(.lightBlack)
                    Spacer()
                    if let exid = recent7.first?.exerciseId, let exercise = ExerciseRepository.shared.getExercisesById(exerciseId: exid), let mainMuscle = exercise.mainMuscles.first {
                        Text(mainMuscle.name)
                            .font(.s_12())
                            .foregroundStyle(.lightBlack)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(.whiteGray)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
                .padding(20)
                
                Divider()
                
                let timeIntervals = recent7.map({ Double($0.dashboardTime) })
                LineGraph(
                    title: "최대 활성도",
                    unit: "%",
                    labels: timeIntervals.unixTimeToDateStrForGraph(),
                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
                    scores: recent7.map({ $0.reportSets?.compactMap({ $0?.mainMax }).max() ?? 0.0 }),
                    minStandard: etParam.mainMaxBor.first,
                    maxStandard: etParam.mainMaxBor.last
                )
                .frame(height: 180)
                .padding(20)
                
                Divider()
                
                LineGraph(
                    title: "평균 활성도",
                    unit: "%",
                    labels: timeIntervals.unixTimeToDateStrForGraph(),
                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
                    scores: recent7.map({ $0.reportSets?.compactMap({ $0?.mainMean }).average() ?? 0.0 }),
                    minStandard: etParam.mainMeanBor.first,
                    maxStandard: etParam.mainMeanBor[1]
                )
                .frame(height: 180)
                .padding(20)
            }
            .background(.background)
        }
    }
    
    private struct WeightHistory: View {
        
        let recent7: [ReportETDTO]
        
        var body: some View {
            
            VStack {
                Spacer().frame(height: 5)
                HStack{
                    Text("중량 변화")
                        .font(.s_18())
                        .foregroundStyle(.lightBlack)
                    Spacer()
                }
                .padding(20)
                
                Divider()
                
                let timeIntervals = recent7.map({ Double($0.dashboardTime) })
                LineGraph(
                    title: "평균 중량",
                    unit: "kg",
                    labels: timeIntervals.unixTimeToDateStrForGraph(),
                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
                    scores: recent7.map({ $0.reportSets?.compactMap({ $0?.weight }).average() ?? 0.0 })
                )
                .frame(height: 180)
                .padding(20)
                
                Divider()
                
                LineGraph(
                    title: "최대 중량",
                    unit: "kg",
                    labels: timeIntervals.unixTimeToDateStrForGraph(),
                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
                    scores: recent7.map({ $0.reportSets?.compactMap({ $0?.weight }).map({ Float($0) }).max() ?? 0.0 })
                )
                .frame(height: 180)
                .padding(20)
            }
            .background(.background)
        }
    }
}
