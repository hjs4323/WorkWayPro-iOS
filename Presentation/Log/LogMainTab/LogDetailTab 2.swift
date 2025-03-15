//
//  LogDetail.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 8/21/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LogDetailTab {
    @Reducer(state: .equatable)
    enum Destination {
        case ftReport(FtReport)
        case etReport(EtReport)
        case dashboardList(LogDashboardList)
    }
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        var who: String
        var dashboards: [DashboardDTO]
        var selectedDashboard: DashboardDTO?
        
        var stParams: [STParam]
        var ftParam: FTParam
        var etParams: [ETParamDTO]
        
        var lastStReport: ReportST?
        
        var dashboardIndex: Int? {
            return self.dashboards.firstIndex(where: { $0 == self.selectedDashboard })
        }
    }
    
    enum Action {
        case selectLast
        case selectNext
        
        case goToDashboardList
        case gotoFTReport(Int)
        case goToETReport([ReportETDTO], Int, Int?)
        
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case selectDashboard([DashboardDTO], DashboardDTO)
        }
    }
    @Dependency(\.reportRepository) var reportRepository
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .selectLast:
                if let index = state.dashboards.firstIndex(where: { $0 == state.selectedDashboard }), index > 0 {
                    state.selectedDashboard = state.dashboards[index - 1]
                }
                else {
                    // TODO 대시보드 갖고오기
                }
                return .none
            case .selectNext:
                if let index = state.dashboards.firstIndex(where: { $0 == state.selectedDashboard }), index < state.dashboards.count - 1 {
                    state.selectedDashboard = state.dashboards[index + 1]
                }
                else {
                    // TODO 대시보드 갖고오기
                }
                return .none
                
            case .goToDashboardList:
                state.destination = .dashboardList(.init(who: state.who, selectMode: .single, dashboards: state.dashboards, selectedDashboard: state.selectedDashboard))
                return .none
            
            case let .gotoFTReport(index):
                if let reports = state.selectedDashboard?.reportFTs {
//                    let lastReport: ReportFTDTO? = index>0 ? reports[index-1] : state.dashboards.last(where: {$0.time < reports[index].time && !($0.reportFTs?.isEmpty ?? true)})?.reportFTs?.last
                    state.destination = .ftReport(.init(
                        reportIndex: index,
                        reports: reports,
                        ftParam: state.ftParam,
                        isFromLog: true
                    ))
                }
                return .none
                
            case let .goToETReport(reportETs, etIndex, setIndex):
                let lastReportET = etIndex > 0 ? reportETs[etIndex - 1] : nil
                let exid = reportETs[etIndex].exerciseId
                state.destination = .etReport(.init(report: reportETs[etIndex], lastReportET: lastReportET, setIndex: setIndex, etParam: state.etParams.first(where: { $0.exid == exid }), isFromLog: true))
                return .none
                
            case let .destination(.presented(.dashboardList(.delegate(delegateAction)))):
                switch delegateAction{
                case let .selectDashboard(totalDashboard, dashboard):
                    state.selectedDashboard = dashboard
                    state.dashboards = totalDashboard
                    return .send(.delegate(.selectDashboard(totalDashboard, dashboard)))
                case .selectList:
                    return .none
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

struct LogDetailTabView: View {
    @Perception.Bindable var store: StoreOf<LogDetailTab>
    
    var body: some View {
        GeometryReader { geometry in
            WithPerceptionTracking {
                ScrollView{
                    VStack(alignment: .leading, spacing: 0){
                        SelectPrevNextView()
                        
                        StReportsView()
                            .background(.white)
                        
                        FtReportsView(geometry: geometry)
                            .background(.white)
                        
                        EtReportsView(geometry: geometry)
                            .background(.white)
                        
                        Spacer().frame(height: 100)
                    }
                    .onDisappear{
                        store.send(.delegate(.selectDashboard(store.dashboards, store.selectedDashboard!)))
                    }
                }
                .navigationDestination(item: $store.scope(state: \.destination?.ftReport, action: \.destination.ftReport)) { store in
                    FtReportView(store: store)
                }
                .navigationDestination(item: $store.scope(state: \.destination?.etReport, action: \.destination.etReport)) { store in
                    EtReportView(store: store)
                }
                .navigationDestination(item: $store.scope(state: \.destination?.dashboardList, action: \.destination.dashboardList)) { store in
                    LogDashboardListView(store: store)
                }
            }
        }
    }
    
    @ViewBuilder
    private func SelectPrevNextView() -> some View {
        HStack{
            Button(action: {
                store.send(.goToDashboardList)
            }, label: {
                
                HStack{
                    var time: String {
                        if let timeInterval = store.selectedDashboard?.time{
                            let formattedString = Double(timeInterval).unixTimeToDateStr("yy.MM.dd (E) hh:mm")
                            return formattedString
                        }
                        else {
                            return "오류"
                        }
                    }
                    Button(action: {
                        store.send(.selectLast)
                    }, label: {
                        ZStack{
                            Image(systemName: "chevron.backward")
                                .resizable()
                                .frame(width: 6, height: 12)
                                .foregroundStyle(.darkGraySet)
                        }
                        .frame(width: 44, height: 44)
                    })
                    
                    Spacer()
                    
                    Text(time)
                        .font(.r_14())
                        .foregroundStyle(.lightBlack)
                    Spacer()
                    
                    Button(action: {
                        store.send(.selectNext)
                    }, label: {
                        ZStack {
                            Image(systemName: "chevron.forward")
                                .resizable()
                                .frame(width: 6, height: 12)
                                .foregroundStyle(.darkGraySet)
                        }
                        .frame(width: 44, height: 44)
                    })
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow2()
                
            })
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
        .background(.backgroundGray)
    }
    
    @ViewBuilder
    private func StReportsView() -> some View {
        if let reportSTs: [ReportST] = store.selectedDashboard?.reportSTs{
            ForEach(0..<reportSTs.count, id: \.self){ index in
                let lastReport: ReportST? = index>0 ? reportSTs[index-1] : store.dashboards.last(where: {$0.time < reportSTs[index].time && !($0.reportSTs?.isEmpty ?? true)})?.reportSTs?.last
                StReportPartView(
                    report: reportSTs[index],
                    lastReport: lastReport,
                    stParams: store.stParams,
                    setNum: index + 1
                )
                if index == reportSTs.count - 1{
                    ThickDivider()
                }
                else{
                    Divider()
                }
            }
        }
    }
    
    @ViewBuilder
    private func FtReportsView(geometry: GeometryProxy) -> some View {
        if let reportFTs: [ReportFTDTO] = store.selectedDashboard?.reportFTs{
            VStack(alignment: .leading, spacing: 0){
                Spacer().frame(height: 10)
                
                Text("기능 평가")
                    .font(.m_18())
                    .foregroundStyle(.lightBlack)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                
                Divider()
                ForEach(0..<reportFTs.count, id: \.self){ index in
                    
                    VStack(alignment: .leading, spacing: 20){
                        FTEvalueationByPart(
                            geometry: geometry,
                            report: reportFTs[index],
                            ftParam: store.ftParam,
                            setNum: index + 1
                        )
                        .padding(.horizontal, 16)
                        
                        
                        Button(action: {
                            store.send(.gotoFTReport(index))
                        }, label: {
                            HStack{
                                Spacer()
                                Text("\(index + 1)세트 자세히 보기")
                                    .font(.r_16())
                                    .foregroundStyle(.darkGraySet)
                                Spacer()
                            }
                            .padding(.vertical, 15)
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow2()
                        })
                        .padding(.horizontal, 20)
                        
                    }
                    .padding(.vertical, 30)
                    
                    if index == reportFTs.count - 1{
                        ThickDivider()
                    }
                    else{
                        Divider()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func EtReportsView(geometry: GeometryProxy) -> some View {
        if let reportETs: [ReportETDTO] = store.selectedDashboard?.reportETs,
           let dashboardET: DashboardETDTO = store.selectedDashboard?.dashboardET{
            
            VStack(alignment: .leading, spacing: 0){
                Spacer().frame(height: 10)
                Text("운동 평가")
                    .font(.m_18())
                    .foregroundStyle(.lightBlack)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                
                VBSTBox(
                    score: dashboardET.averageScore,
                    volume: dashboardET.totalWeight,
                    exerciseTime: store.selectedDashboard!.totTime
                )
                    .padding(35)
                    .frame(height: 250)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow2()
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 30)
                
                
                Divider()
                ForEach(0..<reportETs.count, id: \.self){ index in
                    VStack(spacing: 0){
                        let exercise: ExerciseDTO? = ExerciseRepository.shared.getExercisesById(exerciseId: reportETs[index].exerciseId)
                        HStack{
                            Text(exercise?.name ?? "오류")
                            Spacer()
                            Text(exercise?.mainMuscles.first?.name ?? "오류")
                                .font(.s_12())
                                .foregroundStyle(.lightBlack)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.whiteGray)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 20)
                        
                        if let setReports = reportETs[index].reportSets{
                            TabView{
                                ForEach(0..<(setReports.count), id: \.self){ setIndex in
                                    let report: ReportETSetDTO = setReports[setIndex]!
                                    let lastReport: ReportETSetDTO? = (setIndex>0 ? setReports[setIndex-1]! :
                                                                        store.dashboards.last(where: {$0.time < report.time && !($0.reportETs?.contains(where: {$0.exerciseId == reportETs[index].exerciseId }) ?? true)})?.reportETs?.first(where: {$0.exerciseId == reportETs[index].exerciseId })?.reportSets?.last) ?? nil
                                    VStack{
                                        Spacer().frame(height: 5)
                                        if let etParam = store.etParams.first(where: {$0.exid == reportETs[index].exerciseId}) {
                                            Button(action: {
                                                store.send(.goToETReport(reportETs, index, setIndex))
                                            }, label: {
                                                EtReportPartView(
                                                    geometry: geometry,
                                                    setNum: setIndex + 1,
                                                    report: report,
                                                    lastReport: lastReport,
                                                    etParam: etParam
                                                )
                                                .padding(.horizontal, 20)
                                            })
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .tabViewStyle(.page)
                            .frame(height: 450)
                            
                            Button(action: {
                                store.send(.goToETReport(reportETs, index, nil))
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text("자세히 보기")
                                        .font(.r_16())
                                        .foregroundStyle(.darkGraySet)
                                    Spacer()
                                }
                                .padding(.vertical, 15)
                                .background(.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow2()
                            })
                            .padding(.horizontal, 20)
                        }
                        Divider()
                    }
                    .padding(.vertical, 30)
                }
            }
        }
    }
    
    @ViewBuilder
    private func EtReportPartView(
        geometry: GeometryProxy,
        setNum: Int,
        report: ReportETSetDTO,
        lastReport: ReportETSetDTO?,
        etParam: ETParamDTO
    ) -> some View{
        VStack(spacing: 0){
            HStack(spacing: 8){
                Text("\(setNum) 세트")
                    .font(.m_14())
                    .foregroundStyle(.darkGraySet)
                Text("(\(report.weight) kg)")
                    .font(.m_12())
                    .foregroundStyle(.darkGraySet)
                Spacer()
                
                Image(systemName: "chevron.forward")
                    .resizable()
                    .frame(width: 5, height: 12)
                    .foregroundStyle(.darkGraySet)
            }
            .padding(.horizontal, 20)
            
            SingleBar(
                unit: "점",
                score: report.score,
                lastScore: lastReport?.score,
                standard: 80,
                UIStandard: 70,
                smallBar: true
            )
            .padding(.horizontal, 20)
            
            Divider()
            Spacer().frame(height: 25)
            
            ActivationGraph(
                activation: report.activation,
                muscles: report.muscles,
                activBorder: etParam.activBor
            )
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow2()
    }
}


