//
//  LogHistoryDetailFT.swift
//  WorkwayVer2
//
//  Created by loyH on 8/28/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LogHistoryDetailFT {
    @Reducer(state: .equatable)
    enum Destination {
        case dashboardList(LogDashboardList)
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        
        let who: String
        var dashboards: [DashboardDTO]
        var selectedList: [DashboardDTO]
        let ftParam: FTParam
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
                
            case .destination:
                return .none
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}

struct LogHistoryDetailFTView : View {
    @Perception.Bindable var store: StoreOf<LogHistoryDetailFT>
    
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
                    
                    let reportFTs = store.selectedList.compactMap({ $0.reportFTs }).flatMap({ $0 })
                    let recent7 = Array(reportFTs.sorted(by: { $0.time > $1.time }).take(reportFTs.count < 7 ? reportFTs.count : 7).reversed())
                    
                    ScoreHistory(recent7: recent7)
                    
                    Spacer().frame(minHeight: 16)
                    
                    CRRateHistory(recent7: recent7, ftParam: store.ftParam)
                }
                .background(.backgroundGray)
                .basicToolbar(title: "기능 평가")
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
        
        let recent7: [ReportFTDTO]
        
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
                
                let timeIntervals = recent7.map({ Double($0.time) })
                LineGraph(
                    title: "부위 적합성",
                    unit: "(p)",
                    labels: timeIntervals.unixTimeToDateStrForGraph(),
                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
                    scores: recent7.map({ $0.corrScore }),
                    minStandard: 80,
                    maxStandard: 100
                )
                .frame(height: 180)
                .padding(20)
            }
            .background(.background)
        }
    }
    
    private struct CRRateHistory: View {
        
        let recent7: [ReportFTDTO]
        let ftParam: FTParam
        
        @State var index = 0
        
        var body: some View {
            VStack {
                Spacer().frame(height: 10)
                HStack{
                    Text("수축 이완비 변화")
                        .font(.m_18())
                        .foregroundStyle(.lightBlack)
                    Spacer()
                }
                .padding(20)
                
                Divider()
                
                Spacer().frame(height: 20)
                
                let muscles = Array(Set(recent7.flatMap({ $0.muscles }))).sorted(by: { $0.id < $1.id })
                
                ForEach(0..<muscles.count / 4) { index4 in
                    HStack(spacing: 8){
                        var nCol: Int {
                            let temp = muscles.count - index4 * 4
                            if temp >= 4 {
                                return 4
                            } else {
                                return temp
                            }
                        }
                        
                        ForEach(0..<nCol) { i in
                            Button(action: {
                                index = i + index4 * 4
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text(muscles[i + index4 * 4].fullName(multiLine: true))
                                        .lineSpacing(1)
                                        .font(.m_12())
                                        .foregroundStyle((index == i + index4 * 4) ? .white : .lightBlack)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                            })
                            .background((index == i + index4 * 4) ? .lightBlack : .backgroundGray)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer().frame(height: 20)
                
                let timeIntervals = recent7.map({ Double($0.time) })
                LineGraph(labels: timeIntervals.unixTimeToDateStrForGraph(), subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}), scores: recent7.map({ $0.corrScore }), minStandard: ftParam.crBorder[muscles[index].id]?.first, maxStandard: ftParam.crBorder[muscles[index].id]?.last)
                    .frame(height: 150)
                    .padding(20)
                
                Spacer().frame(height: 20)
            }
            .background(.background)
        }
    }
}
