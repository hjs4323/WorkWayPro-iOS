//
//  LogHistoryTab.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 8/21/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LogHistoryTab {
    @Reducer(state: .equatable)
    enum Destination {
        case dashboardList(LogDashboardList)
        case detailFT(LogHistoryDetailFT)
        case detailET(LogHistoryDetailET)
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        
        var who: String
        var dashboards: [DashboardDTO]
        var selectedList: [DashboardDTO]
        
        var stParams: [STParam]
        var ftParam: FTParam
        var etParams: [ETParamDTO]
        var btParam: BTParam
        
        var etLastReports: [Int: ReportETDTO?] = [:]
    }
    
    enum Action {
        case getLastET(Int)
        case setLastET(Int, ReportETDTO?)
        
        case gotoDetailFT
        case gotoDetailET(ExerciseDTO)
        
        case goToDashboardList
        case destination(PresentationAction<Destination.Action>)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case selectList([DashboardDTO], [DashboardDTO])
        }
    }
    
    @Dependency(\.reportRepository) var reportRepository
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .getLastET(exid):
                let who: String = state.who
                let time = state.selectedList.first?.time ?? Int(Date().timeIntervalSince1970)
                
                if let lastReport: ReportETDTO? = state.dashboards
                    .last(where: {$0.reportETs?.first(where: {$0.exerciseId == exid}) != nil})?
                    .reportETs?.last(where: {$0.exerciseId == exid}){
                    state.etLastReports[exid] = lastReport
                }
                else {
                    return .run { [exid] send in
                        do {
                            if let muscles = ExerciseRepository.shared.muscles {
                                await send(.setLastET(exid, try await reportRepository.getLastET(who: who, exerciseId: exid, endUnixTime: time, muscles: muscles)))
                            } else if let muscles = await ExerciseRepository.shared.getMuscles() {
                                await send(.setLastET(exid, try await reportRepository.getLastET(who: who, exerciseId: exid, endUnixTime: time, muscles: muscles)))
                            }
                        } catch {
                            print("LogHistoryTab/getLastET: error \(error)")
                        }
                    }
                }
                return .none
                
            case let .setLastET(exid, lastReport):
                state.etLastReports[exid] = lastReport
                return .none
                
            case .gotoDetailFT:
                state.destination = .detailFT(.init(who: state.who, dashboards: state.dashboards, selectedList: state.selectedList, ftParam: state.ftParam))
                return .none
                
            case let .gotoDetailET(exercise):
                if let etParam = state.etParams.first(where: { $0.exid == exercise.exerciseId}) {
                    state.destination = .detailET(.init(who: state.who, exercise: exercise, dashboards: state.dashboards, selectedList: state.selectedList, etParam: etParam))
                }
                return .none
                
            case .goToDashboardList:
                state.destination = .dashboardList(.init(who: state.who, selectMode: .multi, dashboards: state.dashboards, selectedList: state.selectedList))
                return .none
                
            case let .destination(.presented(.detailET(.delegate(delegateAction)))):
                switch delegateAction {
                case let .dashboardListSelected(totalDashboards, list):
                    state.selectedList = list
                    state.dashboards = totalDashboards
                    return .send(.delegate(.selectList(totalDashboards, list)))
                }
                
            case let .destination(.presented(.detailFT(.delegate(delegateAction)))):
                switch delegateAction {
                case let .dashboardListSelected(totalDashboards, list):
                    state.selectedList = list
                    state.dashboards = totalDashboards
                    return .send(.delegate(.selectList(totalDashboards, list)))
                }
                
            case let .destination(.presented(.dashboardList(.delegate(delegateAction)))):
                switch delegateAction{
                case .selectDashboard:
                    return .none
                case let .selectList(totalDashboard, list):
                    state.selectedList = list
                    state.dashboards = totalDashboard
                    return .send(.delegate(.selectList(totalDashboard, list)))
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

struct LogHistoryTabView: View {
    @Perception.Bindable var store: StoreOf<LogHistoryTab>
    
    var body: some View {
        GeometryReader{ geometry in
            WithPerceptionTracking {
                ScrollView{
                    VStack(alignment: .leading, spacing: 0){
                        DashboardFilterButton()
                            .padding([.horizontal, .top], 20)
                            .padding(.bottom, 14)
                        
                        let stReports: [ReportST] = Array(store.selectedList.flatMap({$0.reportSTs ?? []}).prefix(6).reversed())
                        if !stReports.isEmpty{
                            STHistoryView(geometry: geometry, stReports: stReports, stParams: store.stParams)
                            
                            ThickDivider()
                        }
                        
                        let ftReports: [ReportFTDTO] = Array(store.selectedList.flatMap({$0.reportFTs ?? []}).prefix(6).reversed())
                        if !ftReports.isEmpty{
                            FTHistoryView(
                                geometry: geometry,
                                ftReports: ftReports,
                                ftParam: store.ftParam,
                                gotoDetailFT: {
                                    store.send(.gotoDetailFT)
                                }
                            )
                            ThickDivider()
                        }
                        
                        let etReports: [ReportETDTO] = Array(store.selectedList.flatMap({$0.reportETs ?? []}))
                        if !etReports.isEmpty{
                            ETHistoryView(
                                geometry: geometry,
                                etReports: etReports,
                                lastReports: store.etLastReports,
                                etParams: store.etParams,
                                gotoDetailET: { exercise in
                                    store.send(.gotoDetailET(exercise))
                                }
                            )
                            Divider()
                        }
                        
                    }
                }
                .background(.backgroundGray)
                .onAppear{
                    let exids = Set(Array(store.selectedList.flatMap({$0.reportETs ?? []})).map({$0.exerciseId}))
                    for exid in exids {
                        store.send(.getLastET(exid))
                    }
                }
                .onDisappear{
                    store.send(.delegate(.selectList(store.dashboards, store.selectedList)))
                }
                .navigationDestination(item: $store.scope(state: \.destination?.dashboardList, action: \.destination.dashboardList)) { store in
                    LogDashboardListView(store: store)
                }
                .navigationDestination(item: $store.scope(state: \.destination?.detailFT, action: \.destination.detailFT)) { store in
                    LogHistoryDetailFTView(store: store)
                }
                .navigationDestination(item: $store.scope(state: \.destination?.detailET, action: \.destination.detailET)) { store in
                    LogHistoryDetailETView(store: store)
                }
            }
        }
    }
    
    @ViewBuilder
    private func DashboardFilterButton() -> some View {
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
    
    struct STHistoryView: View {
        var geometry: GeometryProxy
        var stReports: [ReportST]
        var stParams: [STParam]
        
        @State var index: Int = 0
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0){
                Spacer().frame(height: 30)
                Text("척추근 평가")
                    .font(.m_18())
                    .foregroundStyle(.lightBlack)
                    .padding(.horizontal, 20)
                Spacer().frame(height: 20)
                
                VStack(spacing: 0){
                    let timeIntervals = stReports.map({Double($0.time)})
                    let dates: [String] = timeIntervals.unixTimeToDateStrForGraph()
                    let times: [String] = timeIntervals.map({$0.unixTimeToDateStr("hh:mm")})
                    
                    if let report = stReports[safe: index] {
                        STTensionBalanceView(report: report, stParams: stParams, pickerDownside: true)
                            .padding(.top, 5)
                            .overlay(alignment: .topLeading){
                                VStack(alignment: .center, spacing: 5){
                                    Text(timeIntervals[index].unixTimeToDateStr("yy.MM.dd"))
                                        .font(.m_12())
                                        .foregroundStyle(.darkGraySet)
                                    Text(times[index])
                                        .font(.m_12())
                                        .foregroundStyle(.whiteLightGray)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                    } else {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(.vertical, 40)
                            Spacer()
                        }
                        .onAppear {
                            index = 0
                        }
                    }
                    
                    
                    Divider()
                    
                    if index < stReports.count {
                        LineAndBarGraph(
                            label: dates,
                            subLabel: times,
                            score: stReports.map({$0.score}),
                            border: 80,
                            select: $index,
                            height: 170,
                            width: geometry.size.width - 80
                        )
                        .overlay(alignment: .topLeading){
                            Text("점수")
                                .font(.m_14())
                                .foregroundStyle(.lightBlack)
                        }
                        .padding(.vertical, 25)
                       
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow2()
                .padding(.horizontal, 20)
                Spacer().frame(height: 30)
            }
            .frame(width: geometry.size.width)
            .background(.white)
        }
    }
    
    struct FTHistoryView: View {
        var geometry: GeometryProxy
        var ftReports: [ReportFTDTO]
        var ftParam: FTParam
        
        let gotoDetailFT: () -> ()
        
        @State var index: Int = 0
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0){
                Spacer().frame(height: 30)
                HStack{
                    Text("기능 평가")
                        .font(.m_18())
                        .foregroundStyle(.lightBlack)
                    Spacer()
                    
                    Text("오버헤드 스쿼트")
                        .font(.m_14())
                        .foregroundStyle(.lightGraySet)
                }
                .padding(.horizontal, 20)
                Spacer().frame(height: 20)
                
                VStack(spacing: 0){
                    let timeIntervals = ftReports.map({Double($0.time)})
                    let dates: [String] = timeIntervals.unixTimeToDateStrForGraph()
                    let times: [String] = timeIntervals.map({$0.unixTimeToDateStr("hh:mm")})
                    
                    if let report = ftReports[safe: index] {
                        let mids = report.muscles.map { $0.id }
                        let wsBorder = mids.compactMap { ftParam.wsBorder[$0]! }
                        let esStandard = wsBorder.map({$0[1]}).chunked(into: 2)
                        let swStandard = wsBorder.map({$0.first!}).chunked(into: 2)
                        let maxScores = wsBorder.map({$0.last!}).chunked(into: 2)
                        
                        SWBarGraph(
                            labels: report.muscles.filter({$0.id % 2 == 0}).map{$0.name},
                            scores: report.crRates.chunked(into: 2),
                            esStandard: esStandard,
                            swStandard: swStandard,
                            maxScore: maxScores
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 25)
                    } else {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(.vertical, 40)
                            Spacer()
                        }
                        .onAppear {
                            index = 0
                        }
                    }
                    
                    Divider()
                    
                    if index < ftReports.count {
                        LineAndBarGraph(
                            label: dates,
                            subLabel: times,
                            score: ftReports.map({$0.corrScore}),
                            border: 80,
                            select: $index,
                            height: 170,
                            width: geometry.size.width - 80
                        )
                        .overlay(alignment: .topLeading){
                            Text("점수")
                                .font(.m_14())
                                .foregroundStyle(.lightBlack)
                        }
                        .padding(.vertical, 25)
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow2()
                .padding(.horizontal, 20)
                Spacer().frame(height: 20)
                
                Button(action: {
                    gotoDetailFT()
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
                
                Spacer().frame(height: 30)
            }
            .frame(width: geometry.size.width)
            .background(.white)
        }
    }
    
    struct ETHistoryView: View {
        var geometry: GeometryProxy
        var etReports: [ReportETDTO]
        var lastReports: [Int: ReportETDTO?]
        var etParams: [ETParamDTO]
        let gotoDetailET: (ExerciseDTO) -> ()
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0){
                Spacer().frame(height: 30)
                Text("운동 평가")
                    .font(.m_18())
                    .foregroundStyle(.lightBlack)
                    .padding(.horizontal, 20)
                Spacer().frame(height: 7)
                Text("자율 측정은 리포트별 상세 페이지에서 확인할 수 있습니다.")
                    .font(.r_12())
                    .foregroundStyle(.darkGraySet)
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                let reportsArr = Array(groupReportETsByExerciseId(etReports).values).sorted(by: { $0.first?.exerciseId ?? 0 < $1.first?.exerciseId ?? 1})
                
                ForEach(reportsArr.indices, id: \.self) { i in
                    ETSummaryCardView(
                        totalReports: reportsArr[i],
                        lastReports: lastReports,
                        etParams: etParams,
                        geometry: geometry,
                        gotoDetailET: gotoDetailET
                    )
                    
                    Spacer().frame(minHeight: 30)
                    if i != reportsArr.count-1 {
                        Divider()
                        Spacer().frame(minHeight: 30)
                    }
                }
                
            }
            .background(.white)
        }
        
        struct ETSummaryCardView: View {
            let totalReports: [ReportETDTO]
            let lastReports: [Int: ReportETDTO?]
            let etParams: [ETParamDTO]
            let geometry: GeometryProxy
            
            let gotoDetailET: (ExerciseDTO) -> ()
            
            @State var index: Int = 0
            
            var body: some View {
                let reports = Array(totalReports.prefix(6).reversed())
                
                let exercise = ExerciseRepository.shared.getExercisesById(exerciseId: totalReports.first!.exerciseId)
                let etParam = etParams.first(where: {$0.exid == reports.first?.exerciseId})
                
                let timeIntervals = reports.map({Double($0.dashboardTime)})
                let dateTimes: [String] = timeIntervals.map({$0.unixTimeToDateStr("( MM.dd hh:mm )")})
                let dates: [String] = timeIntervals.unixTimeToDateStrForGraph()
                let times: [String] = timeIntervals.map({$0.unixTimeToDateStr("hh:mm")})
                
                if index < reports.count {
                    Button(action: {
                        gotoDetailET(exercise!)
                    }, label: {
                        VStack(spacing: 0){
                            HStack(spacing: 10){
                                Text(exercise?.name ?? "오류")
                                    .font(.s_16())
                                    .foregroundStyle(.lightBlack)
                                if let dateTime = dateTimes[safe: index] {
                                    Text(dateTime)
                                        .font(.m_12())
                                        .foregroundStyle(.lightGraySet)
                                }
                                Spacer()
                                
                                Image(systemName: "chevron.forward")
                                    .resizable()
                                    .frame(width: 8, height: 16)
                                    .foregroundStyle(.lightGraySet)
                                    .offset(y: -8)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 30)
                            
                            VStack(alignment: .leading, spacing: 0){
                                
                                let lastReport: ReportETDTO? = {
                                    if index > reports.count - 1 {
                                        return nil
                                    }
                                    else if index>0 {
                                        return reports[index-1]
                                    }
                                    else if let lastReport = totalReports.last(where: {$0.exerciseId == exercise?.exerciseId}){
                                        return lastReport
                                    }
                                    else {
                                        return lastReports[exercise?.exerciseId ?? -1] ?? nil
                                    }
                                }()
                                
                                let activations = getReportData(report: reports[index])
                                let lastActivations = getReportData(report: lastReport)
                                
                                if let maxScore = etParam?.mainMaxBor.last, let standard = etParam?.mainMaxBor.first {
                                    HStack(spacing: 5){
                                        Text("최대 활성도")
                                            .font(.m_14())
                                            .foregroundStyle(.lightBlack)
                                        Text("(\(exercise?.mainMuscles.first?.name ?? "오류"))")
                                            .font(.m_12())
                                            .foregroundStyle(.lightGraySet)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    
                                    SingleBar(
                                        unit: "%",
                                        score: activations.maxActivation ?? 0,
                                        lastScore: lastActivations.maxActivation,
                                        maxScore: maxScore,
                                        standard: standard,
                                        smallBar: true
                                    )
                                    .padding(.horizontal, 20)
                                    
                                    Spacer().frame(minHeight: 20)
                                    Divider()
                                    Spacer().frame(minHeight: 20)
                                }
                                
                                if
                                    let standard = etParam?.mainMeanBor.first,
                                    let standard2 = etParam?.mainMeanBor[safe: 1],
                                    let maxScore = etParam?.mainMeanBor.last {
                                    
                                    HStack(spacing: 5){
                                        Text("평균 활성도")
                                            .font(.m_14())
                                            .foregroundStyle(.lightBlack)
                                        Text("(\(exercise?.mainMuscles.first?.name ?? "오류"))")
                                            .font(.m_12())
                                            .foregroundStyle(.lightGraySet)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    SingleBar(
                                        unit: "%",
                                        score: activations.avgActivation ?? 0,
                                        lastScore: lastActivations.avgActivation,
                                        maxScore: maxScore,
                                        standard: standard,
                                        standard2: standard2,
                                        smallBar: true
                                    )
                                    .padding(.horizontal, 20)
                                    
                                    Spacer().frame(minHeight: 20)
                                    Divider()
                                    Spacer().frame(minHeight: 25)
                                    
                                }
                                
                                let avgScores: [Float] = reports.compactMap { report in
                                    let scores = report.reportSets?.compactMap { $0?.score } ?? []
                                    return scores.isEmpty ? 0.0 : scores.getAvg()
                                }
                                
                                let avgWeights: [Float] = reports.compactMap { report in
                                    let weights = report.reportSets?.compactMap { $0?.weight } ?? []
                                    return weights.isEmpty ? 0 : weights.getAvg()
                                }
                                
                                if index < avgScores.count {
                                    
                                    TwoBarGraph(
                                        label: dates,
                                        subLabel: times,
                                        score: avgScores,
                                        score2: avgWeights,
                                        select: $index,
                                        height: 170,
                                        width: geometry.size.width - 80
                                    )
                                    .padding(.horizontal, 20)
                                }
                                
                                Spacer().frame(height: 20)
                                HStack(spacing: 0){
                                    Spacer()
                                    
                                    Text("평균 점수")
                                        .font(.m_14())
                                        .foregroundColor(.lightGraySet)
                                    Text("(점)")
                                        .font(.m_10())
                                        .foregroundStyle(.darkGraySet)
                                    Spacer().frame(width: 8)
                                    Rectangle()
                                        .frame(width: 17, height: 17)
                                        .foregroundColor(.mainBlue)
                                        .opacity(0.2)
                                    
                                    
                                    Spacer().frame(width: 30)
                                    
                                    Text("평균 중량")
                                        .font(.m_14())
                                        .foregroundColor(.lightGraySet)
                                    Text("(kg)")
                                        .font(.m_10())
                                        .foregroundStyle(.darkGraySet)
                                    Spacer().frame(width: 8)
                                    Rectangle()
                                        .frame(width: 17, height: 17)
                                        .foregroundColor(.darkGraySet)
                                        .opacity(0.2)
                                    
                                    Spacer()
                                }
                                Spacer().frame(height: 35)
                            }
                        }
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow2()
                        .padding(.horizontal, 20)
                    })
                } else {
                    VStack(alignment: .center) {
                        Spacer().frame(height: 70)
                        ProgressView()
                        Spacer().frame(height: 70)
                    }
                    .onAppear {
                        index = 0
                    }
                }
            }
            
            private func getReportData(report: ReportETDTO?) -> (maxActivation: Float?, avgActivation: Float?) {
                if let reportSets = report?.reportSets {
                    let maxActivation = reportSets.compactMap({ $0?.mainMax }).average()
                    let avgActivation = reportSets.compactMap({ $0?.mainMean }).average()
                    
                    return (maxActivation, avgActivation)
                }
                return (nil, nil)
            }
        }
        private func groupReportETsByExerciseId(_ reportETDTOs: [ReportETDTO], prefix: Int? = nil) -> [Int: [ReportETDTO]] {
            var groupedReports = [Int: [ReportETDTO]]()
            
            for report in reportETDTOs {
                groupedReports[report.exerciseId, default: []].append(report)
            }
            
            if let prefix = prefix {
                for exid in groupedReports.keys {
                    groupedReports[exid] = Array(groupedReports[exid]?.prefix(prefix) ?? [])
                }
            }
            
            return groupedReports
        }
    }
}
