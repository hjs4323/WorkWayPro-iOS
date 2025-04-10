//
//  LogDashboard.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 8/21/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LogDashboardTab {
    @Reducer(state: .equatable)
    enum Destination {
        case dashboardList(LogDashboardList)
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        
        let who: String
        var dashboards: [DashboardDTO]
        var selectedDashboard: DashboardDTO?
        
        var stParams: [STParam]
        var ftParam: FTParam
        var etParams: [ETParamDTO]
        
        var selectedTest: TestType
        var dashboardIndex: Int? {
            return self.dashboards.firstIndex(where: { $0 == self.selectedDashboard })
        }
        init(destination: Destination.State? = nil, who: String, dashboards: [DashboardDTO], selectedDashboard: DashboardDTO? = nil, stParams: [STParam], ftParam: FTParam, etParams: [ETParamDTO]) {
            self.destination = destination
            self.who = who
            self.dashboards = dashboards
            self.selectedDashboard = selectedDashboard
            self.stParams = stParams
            self.ftParam = ftParam
            self.etParams = etParams
            self.selectedTest = selectedDashboard?.st == true ? .SPINE : selectedDashboard?.ft == true ? .FUNC : .EXER
        }
    }
    
    enum Action {
        case selectLast
        case selectNext
        case selectTest(TestType)
        case setSelectedTest
        
        case goToDashboardList
        case destination(PresentationAction<Destination.Action>)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case selectDashboard([DashboardDTO], DashboardDTO)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .selectLast:
                if let index = state.dashboardIndex, index < state.dashboards.count - 1 {
                    state.selectedDashboard = state.dashboards[index + 1]
                    return .send(.setSelectedTest)
                }
                else {
                }
                return .none
            case .selectNext:
                if let index = state.dashboardIndex, index > 0 {
                    state.selectedDashboard = state.dashboards[index - 1]
                    return .send(.setSelectedTest)
                }
                else {
                }
                return .none
            case let .selectTest(testType):
                state.selectedTest = testType
                return .none
                
            case .setSelectedTest:
                print("dashboardINdex = \(state.dashboardIndex)")
                state.selectedTest = state.selectedDashboard?.st == true ? .SPINE : state.selectedDashboard?.ft == true ? .FUNC : .EXER
                if let selectedDashboard = state.selectedDashboard{
                    return .send(.delegate(.selectDashboard(state.dashboards,selectedDashboard)))
                }
                return .none
                
            case .goToDashboardList:
                state.destination = .dashboardList(.init(who: state.who, selectMode: .single, dashboards: state.dashboards, selectedDashboard: state.selectedDashboard))
                return .none
                
            case let .destination(.presented(.dashboardList(.delegate(delegateAction)))):
                switch delegateAction{
                case let .selectDashboard(totalDashboard, dashboard):
                    state.selectedDashboard = dashboard
                    state.dashboards = totalDashboard
                    return .send(.setSelectedTest)
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

struct LogDashboardTabView: View {
    @Perception.Bindable var store: StoreOf<LogDashboardTab>
    
    var body: some View {
        GeometryReader{ geometry in
            WithPerceptionTracking {
                ScrollView{
                    VStack(spacing: 0){
                        Spacer().frame(height: 20)
                        
                        HStack {
                            Text("검사 결과 요약")
                                .font(.m_18())
                                .foregroundStyle(.lightBlack)
                                .padding(.horizontal, 20)
                            Spacer()
                        }
                        Spacer().frame(height: 8)
                        
                        SelectPrevNextView()
                            .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 19)
                        
                        OverallView()
                            .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 13)
                        
                        switch store.selectedTest{
                        case .SPINE:
                            STOverallView(geometry: geometry)
                                .padding(.horizontal, 20)
                        case .FUNC:
                            FTOverallView(geometry: geometry)
                                .padding(.horizontal, 20)
                        case .EXER:
                            ETOverallView(geometry: geometry)
                                .padding(.horizontal, 20)
                        case .BRIEF:
                            Rectangle()
                        }
                        
                    }
                    .background(.backgroundGray)
                    .onAppear{
                        setupAppearance()
                    }
                    .onDisappear{
                        store.send(.delegate(.selectDashboard(store.dashboards, store.selectedDashboard!)))
                    }
                }
                .navigationDestination(item: $store.scope(state: \.destination?.dashboardList, action: \.destination.dashboardList)) { store in
                    LogDashboardListView(store: store)
                }
            }
        }
        
    }
    
    @ViewBuilder
    private func SelectPrevNextView() -> some View {
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
                if let dashboardIndex = store.dashboardIndex{
                    Button(action: {
                        store.send(.selectLast)
                    }, label: {
                        ZStack{
                            Image(systemName: "chevron.backward")
                                .resizable()
                                .frame(width: 6, height: 12)
                                .foregroundStyle(dashboardIndex < store.dashboards.count - 1 ? .darkGraySet : .lightGraySet)
                        }
                        .frame(width: 44, height: 44)
                    })
                }
                
                Spacer()
                
                Text(time)
                    .font(.r_14())
                    .foregroundStyle(.lightBlack)
                Spacer()
                
                if let dashboardIndex = store.dashboardIndex{
                    Button(action: {
                        store.send(.selectNext)
                    }, label: {
                        ZStack {
                            Image(systemName: "chevron.forward")
                                .resizable()
                                .frame(width: 6, height: 12)
                                .foregroundStyle(dashboardIndex > 0 ? .darkGraySet : .lightGraySet)
                        }
                        .frame(width: 44, height: 44)
                    })
                }
            }
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .shadow2()
            
        })
    }
    
    @ViewBuilder
    private func OverallView() -> some View {
        HStack(spacing: 10){
            if let report = store.selectedDashboard?.reportSTs {
                if !report.isEmpty{
                    SelectTestTypeCard(testType: .SPINE)
                }
            }
            
            if let report = store.selectedDashboard?.reportFTs {
                if !report.isEmpty{
                    SelectTestTypeCard(testType: .FUNC)
                }
            }
            
            if (store.selectedDashboard?.dashboardET) != nil {
                SelectTestTypeCard(testType: .EXER)
            }
            else {
                if let report = store.selectedDashboard?.reportBTs {
                    if !report.isEmpty{
                        SelectTestTypeCard(testType: .EXER)
                    }
                }
            }
        }
        .padding(.horizontal,
                 (store.selectedDashboard?.st == true ? 1 : 0) +
                 (store.selectedDashboard?.ft == true ? 1 : 0)  +
                 (store.selectedDashboard?.dashboardET == nil ? 0 : 1) != 3 ? 20 : 0)
    }
    
    @ViewBuilder
    private func SelectTestTypeCard(
        testType: TestType
    ) -> some View {
        Button(action: {
            store.send(.selectTest(testType))
        }, label: {
            GeometryReader {geometry in
                VStack(spacing: 10){
                    var avgScore: Int? {
                        switch testType {
                        case .SPINE:
                            if let reportSTs = store.selectedDashboard?.reportSTs, !reportSTs.isEmpty {
                                let totalScore = reportSTs.reduce(0) { $0 + $1.score }
                                return Int(totalScore / Float(reportSTs.count))
                            }
                            return 0
                        case .FUNC:
                            if let reportFTs = store.selectedDashboard?.reportFTs, !reportFTs.isEmpty {
                                let totalScore = reportFTs.reduce(0) { $0 + $1.corrScore }
                                return Int(totalScore / Float(reportFTs.count))
                            }
                            return 0
                        case .EXER:
                            if let averageScore = store.selectedDashboard?.dashboardET?.averageScore {
                                return Int(averageScore)
                            }
                            return nil
                        case .BRIEF:
                            return nil
                        }
                    }
                    let correction: Bool? = avgScore != nil ? avgScore! >= 80 : nil
                    
                    Text(testType.rawValue)
                        .font(.r_12())
                        .foregroundStyle(.darkGraySet)
                    
                    HStack(spacing: 4){
                        Spacer()
                        Text(avgScore != nil ? String(avgScore!) : "-")
                            .font(.s_20())
                            .foregroundStyle(.darkGraySet)
                        Text("점")
                            .font(.r_12())
                            .foregroundStyle(.darkGraySet)
                        Spacer()
                    }
                    HStack{
                        Spacer()
                        Text(correction != nil ? correction! ? "적절" : "주의" : "자율")
                            .font(.r_12())
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .frame(width: geometry.size.width * 2 / 3)
                    .padding(.vertical, 5)
                    .background(correction != nil ? correction! ? .mainBlue : .lightGraySet : .brown)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.vertical, 10)
            .padding(.top, 5)
            .frame(height: 105)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow2()
            .overlay{
                if store.selectedTest == testType {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.lightGraySet, lineWidth: 3)
                }
            }
        })
    }
    
    @ViewBuilder
    private func STOverallView(geometry: GeometryProxy) -> some View {
        if let reports = store.selectedDashboard?.reportSTs{
            TabView {
                ForEach(reports.indices, id: \.self) { index in
                    ZStack(alignment: .center) {
                        let report = reports[index]
                        let reportChartValue = getReportChartValue(reportST: report, params: store.stParams)
                        
                        MuscleBarGraph(
                            barSizes: reportChartValue.map({ $0.0 }).chunked(into: 2),
                            colors: reportChartValue.map({ $0.1 }).chunked(into: 2)
                        )
                        .frame(width: 220, height: 213)
                        
                        HStack{
                            Spacer()
                            VStack(spacing: 0){
                                Spacer()
                                Text("강")
                                    .font(.r_12())
                                    .foregroundStyle(.lightBlack)
                                Spacer().frame(height: 13)
                                
                                Rectangle()
                                    .frame(width: 4, height: 40)
                                    .foregroundStyle(.workwayBlue)
                                    .clipShape(
                                        .rect(
                                            topLeadingRadius: 2,
                                            bottomLeadingRadius: 0,
                                            bottomTrailingRadius: 0,
                                            topTrailingRadius: 2
                                        )
                                    )
                                Rectangle()
                                    .frame(width: 4, height: 40)
                                    .foregroundStyle(.buttonBlue)
                                Rectangle()
                                    .frame(width: 4, height: 40)
                                    .foregroundStyle(.whiteLightGray)
                                Rectangle()
                                    .frame(width: 4, height: 40)
                                    .foregroundStyle(.darkGraySet)
                                    .clipShape(
                                        .rect(
                                            topLeadingRadius: 0,
                                            bottomLeadingRadius: 2,
                                            bottomTrailingRadius: 2,
                                            topTrailingRadius: 0
                                        )
                                    )
                                
                                
                                Spacer().frame(height: 13)
                                Text("약")
                                    .font(.r_12())
                                    .foregroundStyle(.lightBlack)
                                Spacer()
                            }
                        }
                        
                        VStack{
                            HStack{
                                Text("\(index + 1)세트")
                                    .font(.m_14())
                                    .foregroundColor(.lightGraySet)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
            .frame(height: max(geometry.size.height * 320 / 830, 320))
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow2()
        }
    }
    
    @ViewBuilder
    private func FTOverallView(geometry: GeometryProxy) -> some View {
        if let reports = store.selectedDashboard?.reportFTs{
            TabView {
                ForEach(reports.indices, id: \.self) { index in
                    ZStack(alignment: .center) {
                        let report = reports[index]
                        
                        let mids = report.muscles.map { $0.id }
                        let wsBorder = mids.compactMap { store.ftParam.wsBorder[$0]! }
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
                        .padding(.bottom)
                        
                        VStack{
                            HStack{
                                Text("\(index + 1)세트")
                                    .font(.m_14())
                                    .foregroundColor(.lightGraySet)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .padding(.horizontal, 25)
            .padding(.top, 15)
            .frame(height: max(geometry.size.height * 320 / 830, 320))
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow2()
        }
    }
    
    @ViewBuilder
    private func ETOverallView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 18){
            let dashboardET = store.selectedDashboard?.dashboardET
            let btTotalWeight = store.selectedDashboard?.reportBTs?.flatMap({
                $0.reportSets.map({ ($0?.weight ?? 0) * ($0?.count ?? 0) })
            }).reduce(0, +)
            
            if dashboardET != nil || btTotalWeight != nil{
                VBSTBox(
                    score: dashboardET?.averageScore,
                    volume: (dashboardET?.totalWeight ?? 0) + (btTotalWeight ?? 0),
                    exerciseTime: store.selectedDashboard!.totTime
                )
                .padding(.horizontal, 45)
            }
            
            if let dashboardET {
                Divider()
                
                HStack{
                    Spacer().frame(width: 5)
                    Spacer()
                    let bestExName = ExerciseRepository.shared.getExercisesById(exerciseId: dashboardET.bestId)?.name ?? "이름 없음"
                    let worstExName = ExerciseRepository.shared.getExercisesById(exerciseId: dashboardET.worstId)?.name ?? "이름 없음"
                    VStack(alignment: .leading, spacing: 8){
                        Text("Best")
                            .font(.m_12())
                            .foregroundStyle(.darkGraySet)
                        Text("\(bestExName)     \(Int(dashboardET.bestScore))점")
                            .font(.s_14())
                            .foregroundStyle(.darkGraySet)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 8){
                        Text("Worst")
                            .font(.m_12())
                            .foregroundStyle(.darkGraySet)
                        Text("\(worstExName)     \(Int(dashboardET.worstScore))점")
                            .font(.s_14())
                            .foregroundStyle(.darkGraySet)
                    }
                    Spacer()
                    Spacer().frame(width: 5)
                }
            }
            
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
        .background(.white)
        .frame(height: store.selectedDashboard?.dashboardET != nil ? max(geometry.size.height * 320 / 830, 320) : max(geometry.size.height * 265 / 830, 265))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow2()
    }
    
    
    
    private func setupAppearance() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .black
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.2)
    }
}
