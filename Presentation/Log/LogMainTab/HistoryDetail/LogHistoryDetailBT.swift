//
//  LogHistoryDetailBT.swift
//  WorkwayVer2
//
//  Created by loyH on 9/20/24.
//

//import Foundation
//import SwiftUI
//import ComposableArchitecture
//
//@Reducer
//struct LogHistoryDetailBT {
//    @Reducer(state: .equatable)
//    enum Destination {
//        case dashboardList(LogDashboardList)
//    }
//    
//    @ObservableState
//    struct State: Equatable {
//        @Presents var destination: Destination.State?
//        
//        let who: String
//        var dashboards: [DashboardDTO]
//        var selectedList: [DashboardDTO]
//        let btParam: BTParam
//    }
//    
//    enum Action {
//        case destination(PresentationAction<Destination.Action>)
//        case delegate(Delegate)
//        
//        case goToDashboardList
//        
//        enum Delegate: Equatable {
//            case dashboardListSelected([DashboardDTO], [DashboardDTO])
//        }
//    }
//    
//    var body: some ReducerOf<Self> {
//        Reduce { state, action in
//            switch action {
//            case let .destination(.presented(.dashboardList(.delegate(delegateAction)))):
//                switch delegateAction {
//                case .selectDashboard:
//                    return .none
//                case let .selectList(allDashboards, selectedDashboards):
//                    state.dashboards = allDashboards
//                    state.selectedList = selectedDashboards
//                    return .send(.delegate(.dashboardListSelected(allDashboards, selectedDashboards)))
//                }
//                
//            case .goToDashboardList:
//                state.destination = .dashboardList(.init(who: state.who, selectMode: .multi, dashboards: state.dashboards, selectedList: state.selectedList))
//                return .none
//                
//            case .destination:
//                return .none
//            case .delegate:
//                return .none
//            }
//        }
//        .ifLet(\.$destination, action: \.destination)
//    }
//}
//
//struct LogHistoryDetailBTView : View {
//    @Perception.Bindable var store: StoreOf<LogHistoryDetailBT>
//    
//    var body: some View {
//        WithPerceptionTracking {
//            ScrollView {
//                VStack{
//                    HStack {
//                        DashboardFilterButton()
//                        Spacer()
//                    }
//                    .padding([.horizontal, .top], 20)
//                    .padding(.bottom, 14)
//                    
//                    let recent7: [[ReportBTDTO]] = Array(store.selectedList.compactMap({ $0.reportBTs }).filter({ !$0.isEmpty }).prefix(7).reversed())
//                    
//                    ActivationHistory(recent7: recent7, btParam: store.btParam)
//                    
//                    Spacer().frame(minHeight: 16)
//                    
//                    WeightHistory(recent7: recent7)
//                }
//                .background(.backgroundGray)
//                .basicToolbar(title: "자율 측정")
//                .navigationDestination(item: $store.scope(state: \.destination?.dashboardList, action: \.destination.dashboardList)) { store in
//                    LogDashboardListView(store: store)
//                }
//            }
//        }
//    }
//    
//    @ViewBuilder
//    private func DashboardFilterButton() -> some View {
//        WithPerceptionTracking {
//            Button(action: {
//                store.send(.goToDashboardList)
//            }, label: {
//                HStack(spacing: 5){
//                    var firstTime: String {
//                        if let timeInterval = store.selectedList.first?.time{
//                            let formattedString = Double(timeInterval).unixTimeToDateStr("yy.MM.dd")
//                            return formattedString
//                        }
//                        else {
//                            return "오류"
//                        }
//                    }
//                    var lastTime: String {
//                        if let lastSelected = store.selectedList.last, let lastDashboard = store.dashboards.last {
//                            if lastDashboard == lastSelected {
//                                return "최근 검사"
//                            }
//                            let formattedString = Double(lastSelected.time).unixTimeToDateStr("yy.MM.dd")
//                            return formattedString
//                        }
//                        else {
//                            return "오류"
//                        }
//                    }
//                    
//                    Image("funnel")
//                        .frame(width: 14, height: 14)
//                    Text("\(firstTime)~\(lastTime)")
//                        .font(.m_14())
//                        .foregroundStyle(.lightBlack)
//                }
//                .padding(.horizontal, 16)
//                .padding(.vertical, 10)
//                .background(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//                .shadow2()
//            })
//        }
//    }
//    
//    private struct ActivationHistory: View {
//        
//        let recent7: [[ReportBTDTO]]
//        let btParam: BTParam
//        
//        var body: some View {
//            
//            VStack {
//                Spacer().frame(height: 5)
//                HStack{
//                    Text("활성도 변화")
//                        .font(.s_18())
//                        .foregroundStyle(.lightBlack)
//                    Spacer()
//                }
//                .padding(20)
//                
//                Divider()
//                
//                let timeIntervals = recent7.compactMap({$0.first != nil ? Double($0.first!.dashboardTime) : nil})
//                LineGraph(
//                    title: "최대 활성도",
//                    unit: "%",
//                    labels: timeIntervals.unixTimeToDateStrForGraph(),
//                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
//                    scores: recent7.compactMap({ $0.compactMap({$0.top.max()}).max() })
//                )
//                .frame(height: 180)
//                .padding(20)
//                
//                Divider()
//                
//                LineGraph(
//                    title: "평균 활성도",
//                    unit: "%",
//                    labels: timeIntervals.unixTimeToDateStrForGraph(),
//                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
//                    scores: recent7.map({ $0.compactMap({ $0.mean.average() }).average()})
//                )
//                .frame(height: 180)
//                .padding(20)
//            }
//            .background(.background)
//        }
//    }
//    
//    private struct WeightHistory: View {
//        
//        let recent7: [[ReportBTDTO]]
//        
//        var body: some View {
//            
//            VStack {
//                Spacer().frame(height: 5)
//                HStack{
//                    Text("중량 변화")
//                        .font(.s_18())
//                        .foregroundStyle(.lightBlack)
//                    Spacer()
//                }
//                .padding(20)
//                
//                Divider()
//                
//                let timeIntervals = recent7.compactMap({$0.first != nil ? Double($0.first!.dashboardTime) : nil})
//                LineGraph(
//                    title: "평균 중량",
//                    unit: "kg",
//                    labels: timeIntervals.unixTimeToDateStrForGraph(),
//                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
//                    scores: recent7.map({ $0.compactMap({ $0.weight }).average() })
//                )
//                .frame(height: 180)
//                .padding(20)
//                
//                Divider()
//                
//                LineGraph(
//                    title: "최대 중량",
//                    unit: "kg",
//                    labels: timeIntervals.unixTimeToDateStrForGraph(),
//                    subLabels: timeIntervals.map({ $0.unixTimeToDateStr("hh:mm")}),
//                    scores: recent7.map({ $0.compactMap({ $0.weight }).map({ Float($0) }).max() ?? 0.0})
//                )
//                .frame(height: 180)
//                .padding(20)
//            }
//            .background(.background)
//        }
//    }
//}
//
//
//#Preview{
//    LogHistoryDetailBTView(store: Store(initialState: LogHistoryDetailBT.State(
//        who: "010112312311",
//        dashboards: testDashboards,
//        selectedList: testDashboards,
//        btParam: testBTParam
//    ), reducer: {
//        LogHistoryDetailBT()
//    }))
//}
