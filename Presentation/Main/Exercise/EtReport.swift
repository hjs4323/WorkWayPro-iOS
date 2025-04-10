//
//  etReport.swiET
//  WorkwayVer2
//
//  Created by loyH on 8/14/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct EtReport{
    @ObservableState
    struct State: Equatable{
        var report: ReportETDTO
        var lastReportET: ReportETDTO?
        var lastSetReport: ReportETSetDTO?
        var rawDatas: [ [[Float]]? ]
        var etParam: ETParamDTO?
        var setIndex: Int?
        var exercise: ExerciseDTO?
        var isFromLog: Bool
        
        init(report: ReportETDTO, lastReportET: ReportETDTO? = nil, lastSetReport: ReportETSetDTO? = nil, rawDatas: [[Float]]? = nil, setIndex: Int?, etParam: ETParamDTO? = nil, isFromLog: Bool) {
            self.report = report
            self.lastSetReport = lastSetReport
            var tempRawDatas: [ [[Float]]? ] = Array(repeating: nil, count: report.reportSets?.count ?? (setIndex ?? 0) + 1)
            if let setIndex {
                tempRawDatas[setIndex] = rawDatas
            }
            self.rawDatas = tempRawDatas
            
            self.setIndex = setIndex
            self.exercise = ExerciseRepository.shared.getExercisesById(exerciseId: report.exerciseId)
            
            self.isFromLog = isFromLog
        }
    }
    enum Action{
        case getETParam
        case setETParam(ETParamDTO)
        case getETRawData(Int)
        case setETRawData(Int, [[Float]]?)
        case getLastETReport
        case setLastETReport(ReportETDTO?)
        case getLastSetReport
        case setLastSetReport(ReportETSetDTO?)
        
        case dismiss
        case setSetIndex(Int?)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case goToMainList(ReportETSetDTO)
        }
    }
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.reportRepository) var reportRepository
    
    let exerciseRepository = ExerciseRepository.shared
    
    var body: some ReducerOf<Self>{
        Reduce{ state, action in
            switch action{
            case .getETParam:
                return .run { [exerciseId = state.report.exerciseId] send in
                    do {
                        if let etParam = try await reportRepository.getETParam(exerciseId: exerciseId) {
                            await send(.setETParam(etParam))
                        }
                    } catch {
                        print("ETReport/getETParam: error getting ETParam \(error)")
                    }
                }
                
            case let .setETParam(param):
                state.etParam = param
                print("etparam = \(state.etParam)")
                return .none
                
            case let .getETRawData(setIndex):
                if let report: ReportETSetDTO = state.report.reportSets?[setIndex] {
                    return .run { send in
                        reportRepository.getGraphData(dir: .ETGRAPH, who: report.who, time: report.time, muscleCount: report.muscles.count, callBack: { data in
                            DispatchQueue.main.async {
                                send(.setETRawData(setIndex, data))
                            }
                        })
                    }
                } else {
                    return .none
                }
                
                
            case let .setETRawData(setIndex, raw):
                state.rawDatas[setIndex] = raw
                return .none
                
            case .getLastSetReport:
                let who: String = state.report.who
                let time: Double = Double(state.report.reportSets![0]!.time)
                let exerciseId: Int = state.report.exerciseId
                return .run { send in
                    do {
                        if let allMuscles = exerciseRepository.muscles {
                            await send(.setLastSetReport(try await reportRepository.getLastETSet(who: who, exerciseId: exerciseId, endUnixTime: time, muscles: allMuscles)))
                        } else if let allMuscles = await exerciseRepository.getMuscles() {
                            await send(.setLastSetReport(try await reportRepository.getLastETSet(who: who, exerciseId: exerciseId, endUnixTime: time, muscles: allMuscles)))
                        }
                    } catch {
                        print("ETReport/getLastSetReport: no lastSetReport \(error)")
                        await send(.setLastSetReport(nil))
                    }
                }
                
            case let .setLastSetReport(lastSetReport):
                state.lastSetReport = lastSetReport
                return .none
                
            case .getLastETReport:
                return .run { [reportET = state.report]send in
                    do {
                        if let allMuscles = exerciseRepository.muscles {
                            await send(.setLastETReport(try await reportRepository.getLastET(who: reportET.who, exerciseId: reportET.exerciseId, endUnixTime: reportET.dashboardTime, muscles: allMuscles)))
                        } else if let allMuscles = await exerciseRepository.getMuscles() {
                            await send(.setLastETReport(try await reportRepository.getLastET(who: reportET.who, exerciseId: reportET.exerciseId, endUnixTime: reportET.dashboardTime, muscles: allMuscles)))
                        }
                    } catch {
                        print("ETReport/getLastETReport: error getting ReportET \(error)")
                    }
                }
                
            case let .setLastETReport(report):
                state.lastReportET = report
                return .none
                
            case let .setSetIndex(newVal):
                state.setIndex = newVal
                return .none
                
            case .dismiss:
                return .run { _ in
                    await dismiss()
                }
            case .delegate:
                return .none
                
            }
        }
    }
    
    
}

struct EtReportView: View {
    @Perception.Bindable var store: StoreOf<EtReport>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var swipeBack: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            WithPerceptionTracking {
                VStack(spacing: 0){
                    if let etParam = store.etParam {
                        if store.isFromLog {
                            ReportIndexRow(geometry: geometry, reportCount: store.report.reportSets!.count, currentIndex: store.setIndex) { newIndex in
                                store.send(.setSetIndex(newIndex))
                            }
                        }
                        if let setIndex = store.setIndex, let setReport: ReportETSetDTO = store.report.reportSets?[setIndex] {
                            ScrollView {
                                VStack(spacing: 0){
                                    
                                    HStack(spacing: 25){
                                        Image("exercise_picture")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                        VStack(alignment: .leading, spacing: 10){
                                            Text(store.exercise?.name ?? "오류")
                                                .font(.m_16())
                                                .foregroundStyle(.lightBlack)
                                            Text("\(setIndex + 1) 세트   \(setReport.weight) kg   \(setReport.repCount) 회")
                                                .font(.m_14())
                                                .foregroundStyle(.darkGraySet)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 25)
                                    

                                    ThickDivider()
                                    
                                    SingleBar(
                                        title: "점수",
                                        unit: "점",
                                        score: setReport.score,
                                        lastScore: store.lastSetReport?.score,
                                        standard: 80,
                                        UIStandard: 70,
                                        description: "운동 평가 점수는 부위별 근활성도를 기반으로 AI가 분석한 점수로, 단순 근활성도 세기뿐만 아니라 활성 타이밍 등을 포함하여 산출됩니다."
                                    )
                                    .padding(25)
                                    .onAppear(perform: {
                                        if setIndex == 0 && store.lastSetReport == nil {
                                            store.send(.getLastSetReport)
                                        }
                                    })
                                    
                                    Divider()
                                        .border(.whiteGray)
                                    
                                    VStack(alignment: .leading, spacing: 25){
                                        Text("부위별 분석")
                                            .font(.m_18())
                                            .foregroundStyle(.lightBlack)
                                        
                                        ActivationGraph(
                                            activation: setReport.activation,
                                            muscles: setReport.muscles,
                                            activBorder: etParam.activBor
                                        )
                                        Spacer().frame(height: 5)
                                    }
                                    .padding(25)
                                    
                                    Divider()
                                        .border(.whiteGray)
                                    
                                    if let standard = etParam.mainMaxBor.first, let maxScore = etParam.mainMaxBor.last {
                                        SingleBar(
                                            title: "최대 활성도",
                                            unit: "%",
                                            label: store.exercise?.mainMuscles.first?.name,
                                            score: setReport.mainMax,
                                            lastScore: store.lastSetReport?.mainMax,
                                            maxScore: maxScore,
                                            standard: standard,
                                            description: "최대 활성도 적절 범위 : \(Int(standard))% 이상",
                                            description2: "타겟 근육의 세트 중 최대 활성도를 산출한 것입니다. 적절 범위에서 벗어날 경우 다음 세트에서 주의가 필요한 것으로 이해할 수 있습니다."
                                        )
                                        .padding(25)
                                        
                                        Divider()
                                            .border(.whiteGray)
                                    }
                                    
                                    if let standard1 = etParam.mainMeanBor.first, let standard2 = etParam.mainMeanBor[safe: 1], let maxScore = etParam.mainMeanBor.last {
                                        SingleBar(
                                            title: "평균 활성도",
                                            unit: "%",
                                            label: store.exercise?.mainMuscles.first?.name,
                                            score: setReport.mainMean,
                                            lastScore: store.lastSetReport?.mainMean,
                                            maxScore: maxScore,
                                            standard: standard1,
                                            standard2: standard2,
                                            description: "평균 활성도 적절 범위 : \(Int(standard1))% ~ \(Int(standard2))%",
                                            description2: "타겟 근육의 세트 중 평균 활성도를 산출한 것입니다. 적절 범위에서 벗어날 경우 다음 세트에서 주의가 필요한 것으로 이해할 수 있습니다."
                                        )
                                        .padding(25)
                                    }
                                    
                                    if let rawDatas = store.rawDatas[setIndex] {
                                        if rawDatas.filter({ $0.isEmpty }).isEmpty {
                                            ThickDivider()
                                            
                                            SingleRawByPart(
                                                geometry: geometry,
                                                report: setReport,
                                                muscles: setReport.muscles,
                                                rawDatas: rawDatas,
                                                etParam: etParam
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.top, 25)
                                            .padding(.bottom, 30)
                                            
                                            Divider()
                                                .border(.whiteGray)
                                            
                                            PairRawByPart(
                                                geometry: geometry,
                                                report: setReport,
                                                muscles: setReport.muscles,
                                                rawDatas: rawDatas
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.top, 25)
                                            .padding(.bottom, 30)
                                            
                                            Spacer().frame(height: 7)
                                            
                                        }
                                    } else {
                                        VStack {
                                            Spacer()
                                            ProgressView()
                                                .onAppear(perform: {
                                                    store.send(.getETRawData(setIndex))
                                                })
                                            Spacer()
                                        }
                                        .frame(width: geometry.size.width, height: 50)
                                    }
                                }
                            }
                            if !store.isFromLog {
                            
                                okButton(action: {
                                    if !swipeBack {
                                        store.send(.delegate(.goToMainList(setReport)))
                                    }
                                    else {
                                        store.send(.dismiss)
                                    }
                                })
                                .padding(20)
                            } else {
                                Spacer().frame(height: 20)
                            }
                        } else {
                            ScrollView{
                                ETSummaryView(report: store.report, lastReport: store.lastReportET, etParam: etParam)
                                    .onAppear {
                                        if store.lastReportET == nil {
                                            store.send(.getLastETReport)
                                        }
                                    }
                            }
                        }
                    } else {
                        Spacer()
                        ProgressView()
                            .onAppear {
                                if store.etParam == nil {
                                    print("getETParam")
                                    store.send(.getETParam)
                                }
                            }
                        Spacer()
                    }
                }
                .frame(width: geometry.size.width)
                .basicToolbar(
                    title: "운동 평가",
                    swipeBack: swipeBack,
                    closeButtonAction: swipeBack ? nil : {
                        store.send(.delegate(.goToMainList(store.report.reportSets![store.setIndex ?? 0]!)))
                    }
                )
            }
        }
    }
    
    private struct ReportIndexRow: View {
        let geometry: GeometryProxy
        @State var isExpanded: Bool = false
        let reportCount: Int
        let currentIndex: Int?
        let selectIndex: (Int?) -> ()
        
        var body: some View {
            ScrollView(.horizontal){
                HStack {
                    if isExpanded {
                        Button {
                            isExpanded = false
                            selectIndex(nil)
                        } label: {
                            HStack {
                                if currentIndex == nil {
                                    Triangle()
                                        .frame(width: 12, height: 11)
                                        .rotationEffect(.degrees(90))
                                    Spacer().frame(width: 12)
                                }
                                Text("요약")
                                    .font(.m_14())
                                    .foregroundStyle(.darkGraySet)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow2()
                        }
                        ForEach(0..<reportCount, id: \.self) { index in
                            Button {
                                isExpanded = false
                                selectIndex(index)
                            } label: {
                                HStack {
                                    if currentIndex == index {
                                        Triangle()
                                            .frame(width: 12, height: 11)
                                            .rotationEffect(.degrees(90))
                                        Spacer().frame(width: 12)
                                    }
                                    Text("\(index + 1)세트")
                                        .font(.m_14())
                                        .foregroundStyle(.darkGraySet)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(.background)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow2()
                            }
                        }
                    } else {
                        Button {
                            isExpanded = true
                        } label: {
                            HStack {
                                Triangle()
                                    .frame(width: 12, height: 11)
                                    .rotationEffect(.degrees(180))
                                Spacer().frame(width: 12)
                                Text(currentIndex == nil ? "요약" : "\(currentIndex! + 1)세트")
                                    .font(.m_14())
                                    .foregroundStyle(.darkGraySet)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow2()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(width: geometry.size.width)
            .background(.backgroundGray)
        }
    }
    
    struct SingleRawByPart: View {
        let geometry: GeometryProxy
        let report: ReportETSetDTO
        let muscles: [MuscleDTO]
        let rawDatas: [[Float]]
        let etParam: ETParamDTO
        var minData: Float = 0
        var maxData: Float = 700
        
        @State var index = 0
        
        var body: some View {
            VStack(alignment: .leading ,spacing: 20){
                VStack(alignment: .leading ,spacing: 20){
                    Text("단일 부위 데이터 보기")
                        .font(.m_16())
                        .foregroundStyle(.lightBlack)
                    
                    VStack(spacing: 10){
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
                        }
                    }
                }
                .padding(.horizontal, 4)
                
                VStack(alignment: .trailing ,spacing: 0){
                    Spacer().frame(height: 20)
                    Text("단위: EMG (%)")
                        .font(.m_12())
                        .foregroundColor(.lightGraySet)
                        .padding(.horizontal, 10)
                    
                    Spacer().frame(height: 13)
                    
                    ZStack(alignment: .leading){
                        VStack(spacing: 0){
                            HStack(spacing: 9){
                                Rectangle()
                                    .frame(width: 1, height: 160)
                                    .foregroundColor(.whiteLightGray)
                                VStack(alignment: .leading){
                                    Text(String(Int(maxData)))
                                        .font(.r_10())
                                        .foregroundColor(.whiteLightGray)
                                        .offset( y: -8)
                                    Spacer()
                                    Text(String(Int(minData)))
                                        .font(.r_10())
                                        .foregroundColor(.whiteLightGray)
                                        .offset(y: 8)
                                }
                            }
                            .frame(height: 160)
                            Spacer().frame(height: 22)
                        }
                        ScrollView(.horizontal, showsIndicators: true){
                            let graphWidth: CGFloat = (geometry.size.width - 50) * CGFloat(max(1, rawDatas[index].count / 400))
                            VStack(spacing: 0){
                                RawDataGraph(
                                    names: [muscles[index].fullName(multiLine: false)],
                                    rawDatas: [rawDatas[index]],
                                    standard: etParam.rawBor[report.muscles[index].id],
                                    minData: minData,
                                    maxData: maxData
                                )
                                .frame(width: graphWidth, height: 160)
                                Spacer().frame(height: 22)
                            }
                        }
                        
                    }
                    HStack{
                        Spacer()
                        Rectangle()
                            .frame(width: 17, height: 17)
                            .foregroundColor(.mainBlue)
                            .opacity(0.5)
                        Spacer().frame(width: 8)
                        Text("적정 범위")
                            .font(.m_14())
                            .foregroundColor(.lightGraySet)
                        
                        Spacer().frame(width: 14)
                        
                        Rectangle()
                            .frame(width: 17, height: 1)
                            .foregroundColor(.mainBlue)
                        Spacer().frame(width: 8)
                        Text(muscles[index].fullName(multiLine: false))
                            .font(.m_14())
                            .foregroundColor(.lightGraySet)
                        Spacer()
                    }
                    .padding(.vertical, 25)
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow2()
                .padding(.horizontal, 5)
            }
        }
    }
    
    struct PairRawByPart: View {
        let geometry: GeometryProxy
        let report: ReportETSetDTO
        let muscles: [MuscleDTO]
        let rawDatas: [[Float]]
        let minData: Float = 0
        let maxData: Float = 700
        
        @State var index = 0
        
        var body: some View {
            VStack(alignment: .leading ,spacing: 20){
                VStack(alignment: .leading ,spacing: 20){
                    Text("좌우 비교 데이터 보기")
                        .font(.m_16())
                        .foregroundStyle(.lightBlack)
                    
                    HStack(spacing: 8){
                        ForEach(0..<muscles.count / 2) { i in
                            Button(action: {
                                index = i
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text(muscles[i*2].name)
                                        .font(.m_12())
                                        .foregroundStyle((index == i) ? .white : .lightBlack)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                            })
                            .background((index == i) ? .lightBlack : .backgroundGray)
                            .cornerRadius(10)
                        }
                    }
                    
                }
                .padding(.horizontal, 4)
                
                VStack(alignment: .trailing ,spacing: 0){
                    Spacer().frame(height: 20)
                    Text("단위: EMG (%)")
                        .font(.m_12())
                        .foregroundColor(.lightGraySet)
                        .padding(.horizontal, 10)
                    
                    Spacer().frame(height: 13)
                    
                    ZStack(alignment: .leading){
                        VStack(spacing: 0){
                            HStack(spacing: 9){
                                Rectangle()
                                    .frame(width: 1, height: 160)
                                    .foregroundColor(.whiteLightGray)
                                VStack(alignment: .leading){
                                    Text(String(Int(maxData)))
                                        .font(.r_10())
                                        .foregroundColor(.whiteLightGray)
                                        .offset( y: -8)
                                    Spacer()
                                    Text(String(Int(minData)))
                                        .font(.r_10())
                                        .foregroundColor(.whiteLightGray)
                                        .offset(y: 8)
                                }
                            }
                            .frame(height: 160)
                            Spacer().frame(height: 22)
                        }
                        ScrollView(.horizontal, showsIndicators: true){
                            let graphWidth: CGFloat = (geometry.size.width - 50) * CGFloat(max(1, rawDatas[index].count / 400))
                            VStack(spacing: 0){
                                RawDataGraph(
                                    names: [muscles[index*2].fullName(multiLine: false), muscles[index*2 + 1].fullName(multiLine: false)],
                                    rawDatas: [rawDatas[index*2], rawDatas[index*2 + 1]],
                                    minData: minData,
                                    maxData: maxData
                                )
                                .frame(width: graphWidth, height: 160)
                                Spacer().frame(height: 22)
                            }
                        }
                    }
                    HStack{
                        Spacer()
                        Rectangle()
                            .frame(width: 17, height: 1)
                            .foregroundColor(.workwayBlue)
                        Spacer().frame(width: 8)
                        Text(muscles[index * 2].fullName(multiLine: false))
                            .font(.m_14())
                            .foregroundColor(.lightGraySet)
                        
                        Spacer().frame(width: 14)
                        
                        Rectangle()
                            .frame(width: 17, height: 1)
                            .foregroundColor(.red)
                        Spacer().frame(width: 8)
                        Text(muscles[index * 2 + 1].fullName(multiLine: false))
                            .font(.m_14())
                            .foregroundColor(.lightGraySet)
                        Spacer()
                    }
                    .padding(.vertical, 25)
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow2()
                .padding(.horizontal, 5)
            }
        }
    }
}

struct ETSummaryView: View {
    let report: ReportETDTO
    let lastReport: ReportETDTO?
    let etParam: ETParamDTO
    
    var body: some View {
        VStack(spacing: 0){
            Spacer().frame(height: 25)
            HStack{
                var time: String {
                    let timeInterval = Double(report.dashboardTime)
                    let formattedString = timeInterval.unixTimeToDateStr("yy.MM.dd")
                    return formattedString
                }
                Text("종합 분석")
                    .font(.s_18())
                    .foregroundStyle(.lightBlack)
                Spacer()
                Text(time)
                    .font(.r_14())
                    .foregroundStyle(.lightGraySet)
            }
            .padding(.horizontal, 20)
            Spacer().frame(height: 20)
            Divider()
            Spacer().frame(height: 25)
            
            let score: Float? = getAvgScore(report: report)
            let lastScore: Float? = getAvgScore(report: lastReport)
            
            SingleBar(
                title: "평균 점수",
                unit: "점",
                score: score ?? 0,
                lastScore: lastScore,
                description: "운동 평가 점수는 부위별 근활성도를 기반으로 AI가 분석한 점수로, 단순 근활성도 세기뿐만 아니라 활성 타이밍 등을 포함하여 산출됩니다."
            )
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 25)
            ThickDivider()
            Spacer().frame(height: 25)
            
            if let reportSets = report.reportSets{
                HStack{
                    var time: String {
                        let timeInterval = Double(report.dashboardTime)
                        let formattedString = timeInterval.unixTimeToDateStr("yy.MM.dd")
                        return formattedString
                    }
                    Text("세트별 분석")
                        .font(.s_18())
                        .foregroundStyle(.lightBlack)
                    Spacer()
                    Text(time)
                        .font(.r_14())
                        .foregroundStyle(.lightGraySet)
                }
                .padding(.horizontal, 20)
                Spacer().frame(height: 20)
                Divider()
                Spacer().frame(height: 25)
                
                let setLabels: [String] = (1...reportSets.count).map { "\($0)세트" }
                LineGraph(
                    title: "점수",
                    unit: "점",
                    labels: setLabels,
                    scores: reportSets.map({$0?.score ?? 0}),
                    minStandard: 80,
                    maxStandard: 100
                )
                .frame(height: 130)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                Divider()
                Spacer().frame(height: 25)
                
                LineGraph(
                    title: "최대 활성도",
                    unit: "%",
                    labels: setLabels,
                    scores: reportSets.map({$0?.mainMax ?? 0}),
                    minStandard: etParam.mainMaxBor.first,
                    maxStandard: etParam.mainMaxBor.last
                )
                .frame(height: 130)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                Divider()
                Spacer().frame(height: 20)
                
                LineGraph(
                    title: "평균 활성도",
                    unit: "%",
                    labels: setLabels,
                    scores: reportSets.map({$0?.mainMean ?? 0}),
                    minStandard: etParam.mainMeanBor.first,
                    maxStandard: etParam.mainMeanBor[1]
                )
                .frame(height: 130)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                Divider()
                Spacer().frame(height: 20)
                
                LineGraph(
                    title: "중량",
                    unit: "kg",
                    labels: setLabels,
                    scores: reportSets.map({Float($0?.weight ?? 0)})
                )
                .frame(height: 130)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 25)
                ThickDivider()
            }
            StaticBySet(report: report, etParam: etParam)
        }
    }
    
    struct StaticBySet: View {
        let report: ReportETDTO
        let etParam: ETParamDTO
        
        @State var index: Int = 0
        
        var body: some View {
            if let reportSets = report.reportSets{
                VStack{
                    Spacer().frame(height: 25)
                    HStack{
                        var time: String {
                            let timeInterval = Double(report.dashboardTime)
                            let formattedString = timeInterval.unixTimeToDateStr("yy.MM.dd")
                            return formattedString
                        }
                        Text("부위별 분석")
                            .font(.s_18())
                            .foregroundStyle(.lightBlack)
                        Spacer()
                        Text(time)
                            .font(.r_14())
                            .foregroundStyle(.lightGraySet)
                    }
                    .padding(.horizontal, 20)
                    Spacer().frame(height: 20)
                    Divider()
                    
                    ScrollView(.horizontal){
                        HStack(spacing: 8){
                            ForEach(0..<reportSets.count) { i in
                                Button(action: {
                                    index = i
                                }, label: {
                                        Text("\(i+1)세트")
                                            .font(.m_12())
                                            .foregroundStyle((index == i) ? .white : .lightBlack)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 26)
                                })
                                .background((index == i) ? .lightBlack : .backgroundGray)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .frame(height: 85)
                    .padding(.horizontal, 20)
                    
                    if let setReport = reportSets[index]{
                        HStack{
                            ActivationGraph(activation: setReport.activation, muscles: setReport.muscles, activBorder: etParam.activBor)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 25)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow2()
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    func getAvgScore(report: ReportETDTO?) -> Float? {
        guard report != nil else { return nil }
        let scores: [Float] = report?.reportSets?.compactMap { $0?.score } ?? []
        return scores.getAvg()
    }
}
