//
//  BtReport.swift
//  WorkwayVer2
//
//  Created by loyH on 9/13/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct RawInfo: Equatable, Hashable {
    let reportName: String
    let setIndex: Int
    let muscleName: String
    let dashboardTime: Int
    let startTime: Int
    var rawData: [Float]
    
    var timeStr: String {
        let timeInterval = Double(self.dashboardTime)
        let formattedString = timeInterval.unixTimeToDateStr("(MM.dd)")
        return formattedString
    }
    var str: String {
        var mName: String {
            if let range = self.muscleName.range(of: "번 근육") {
                let number = String(self.muscleName[..<range.lowerBound])
                return "\(number)번"
            } else {
                return self.muscleName
            }
        }
        return "\(self.setIndex+1)세트 \(mName) / \(timeStr) \(self.reportName) "
    }
}

@Reducer
struct BtReport{
    @Reducer(state: .equatable)
    enum Destination {
        case edit(BTEditMuscleName)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        
        var setIndex: Int?
        let initMuscleName: String?
        var reports: [ReportBTDTO]
        var reportsNotToday: [ReportBTDTO]?
        var selectedReportName: String
        
        var report: ReportBTDTO {
            return reports.first(where: { $0.name == selectedReportName })!
        }
        var rawInfos: [RawInfo] {
            var rawInfos: [RawInfo] = []
            for report in reports + (reportsNotToday ?? []) {
                for setIndex in 0..<report.setTimes.count {
                    for muscleIndex in 0..<report.muscleName.count {
                        var rawData: [Float] {
                            if let rSet = report.reportSets[setIndex],
                               let rawDatas = rSet.rawData,
                               muscleIndex < rawDatas.count {
                                return rawDatas[muscleIndex]
                            } else {
                                return []
                            }
                        }
                        
                        let rawInfo = RawInfo(
                            reportName: report.name,
                            setIndex: setIndex,
                            muscleName: report.muscleName[muscleIndex],
                            dashboardTime: report.dashboardTime,
                            startTime: report.setTimes[setIndex],
                            rawData: rawData
                        )
                        rawInfos.append(rawInfo)
                    }
                }
            }
            return rawInfos
        }
        
        var btParam: BTParam?
        let isFromLog: Bool
        
        var editingMuscle: Int?
        
        var selectedReport: ReportBTSetDTO? {
            if let setIndex {
                return report.reportSets[setIndex]
            }
            else{
                return nil
            }
        }
        
        init(setIndex: Int? = nil, initMuscleName: String?, reports: [ReportBTDTO], reportsNotToday: [ReportBTDTO]?, selectedReportName: String, btParam: BTParam? = nil, isFromLog: Bool) {
            self.setIndex = setIndex
            self.initMuscleName = initMuscleName
            self.reports = reports
            self.reportsNotToday = reportsNotToday
            self.selectedReportName = selectedReportName
            self.btParam = btParam
            self.isFromLog = isFromLog
        }
    }
    
    enum Action{
        case getBTParam
        case setBTParam(BTParam)
        case getReportsNotToday
        case setReportsNotToday([ReportBTDTO])
        case getBTSetReport(RawInfo)
        case setBTSetReport(RawInfo, ReportBTSetDTO)
        case getBTRawData(RawInfo)
        case setBTRawData(RawInfo, [[Float]]?)
        
        case setSetIndex(Int?)
        case goToEdit(Int)
        case dismiss
        
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
    var body: some ReducerOf<Self>{
        Reduce{ state, action in
            switch action{
            case .getBTParam:
                return .run { send in
                    do {
                        if let btParam = try await reportRepository.getBTParam(){
                            await send(.setBTParam(btParam))
                        }
                    } catch {
                        print("BTReport/getBTParam: error getting BTParam \(error)")
                    }
                }
                
            case let .setBTParam(param):
                state.btParam = param
                return .none
                
            case .getReportsNotToday:
                return .run { [ who = state.report.who, reports = state.reports ]send in
                    do {
                        let reportsNotToday = try await reportRepository.getReportBT(who: who, startUnixTime: nil, endUnixTime: nil)
                            .filter({ notToday in
                                !reports.contains(where: {
                                    $0.dashboardTime == notToday.dashboardTime &&
                                    $0.name == notToday.name &&
                                    $0.who == notToday.who
                                })
                            })
                        await send(.setReportsNotToday(reportsNotToday))
                    } catch {
                        print("BTReport/getReportsNotToday: error getting ReportBT \(error)")
                    }
                }
                
            case let .setReportsNotToday(reportsNotToday):
                state.reportsNotToday = reportsNotToday
                return .send(.delegate(.setReportBTsNotToday(reportsNotToday)))
                
            case let .getBTSetReport(rawInfo):
                if let report = state.reports.first(where: {$0.dashboardTime == rawInfo.dashboardTime}) {
                    return .run { [ report, rawInfo ] send in
                        try await reportRepository.getReportBTSet(
                            who: report.who,
                            startTime: report.setTimes[rawInfo.setIndex],
                            graphTogether: true,
                            callBack: { data in
                                DispatchQueue.main.async {
                                    send(.setBTSetReport(rawInfo, data))
                                }
                            },
                            onFailure: {}
                        )
                    }
                }
                return .none
                
            case let .setBTSetReport(rawInfo, rSet):
                if let reportIndex = state.reports.firstIndex(where: {$0.dashboardTime == rawInfo.dashboardTime}) {
                    state.reports[reportIndex].reportSets[rawInfo.setIndex] = rSet
                    print("set setReport -> setIndex = \(rawInfo.setIndex), \(state.reports[reportIndex].reportSets[rawInfo.setIndex]?.rawData?.count ?? -1)")
                }
                return .none
                
            case let .getBTRawData(rawInfo):
                if let report = state.reports.first(where: {$0.dashboardTime == rawInfo.dashboardTime}) {
                    let rSet = report.reportSets[rawInfo.setIndex]!
                    return .run { [ rSet ] send in
                        reportRepository.getGraphData(dir: .BTGRAPH, who: rSet.who, time: rSet.time, muscleCount: rSet.top.count, callBack: { data in
                            DispatchQueue.main.async {
                                send(.setBTRawData(rawInfo, data))
                            }
                        })
                    }
                }
                return .none
                
            case let .setBTRawData(rawInfo, raw):
                if
                    let reportIndex = state.reports.firstIndex(where: {
                        $0.dashboardTime == rawInfo.dashboardTime &&
                        $0.name == rawInfo.reportName
                    })
                {
                    state.reports[reportIndex].reportSets[rawInfo.setIndex]?.rawData = raw
                    print("set rawdata -> setIndex = \(rawInfo.setIndex)")
                }
                return .none
                
            case let .setSetIndex(newVal):
                state.setIndex = newVal
                print("BtReport/setSetIndex: to \(state.setIndex)")
                return .none
                
            case let .goToEdit(order):
                state.editingMuscle = order
                state.destination = .edit(.init(name: state.report.muscleName[order]))
                return .none
                
            case .dismiss:
                return .run { _ in
                    await dismiss()
                }
                
            case let .destination(.presented(.edit(.delegate(delegateAction)))):
                switch delegateAction {
                case let .editMuscleName(muscleName):
                    state.destination = nil
                    
                    if let editingMuscle = state.editingMuscle{
                        if
                            let reportIndex = state.reports.firstIndex(where: { $0.name == state.selectedReportName }),
                            state.reports[reportIndex].muscleName[editingMuscle] != muscleName
                        {
                            state.reports[reportIndex].muscleName[editingMuscle] = muscleName
                            state.editingMuscle = nil
                            return .run { [ report = state.report ] send in
                                try await reportRepository.setBTNames(reportBTId: report.reportId, muscleNames: report.muscleName)
                            }
                        }
                    }
                    state.editingMuscle = nil
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

struct BtReportView: View {
    @Perception.Bindable var store: StoreOf<BtReport>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var swipeBack: Bool = true
    
    var body: some View {
        WithPerceptionTracking{
            GeometryReader { geometry in
                WithPerceptionTracking {
                    VStack(spacing: 0){
                        let reportSets = store.report.reportSets
                        
                        if let btParam = store.btParam, let reportsNotToday = store.reportsNotToday {
                            if store.isFromLog {
                                ReportIndexRow(
                                    geometry: geometry,
                                    reportCount: reportSets.compactMap({ $0 }).count,
                                    currentIndex: store.setIndex,
                                    selectIndex: { newIndex in
                                        store.send(.setSetIndex(newIndex))
                                    }
                                )
                            }
                            ScrollView {
                                WithPerceptionTracking {
                                    if let setIndex = store.setIndex, let selectedReport = store.selectedReport {
                                        if !store.isFromLog {
                                            VStack(spacing: 0){
                                                HStack(spacing: 25){
                                                    Image("exercise_picture")
                                                        .resizable()
                                                        .frame(width: 50, height: 50)
                                                    VStack(alignment: .leading, spacing: 10){
                                                        Text("자율 측정")
                                                            .font(.m_16())
                                                            .foregroundStyle(.lightBlack)
                                                        Text("\(setIndex + 1) 세트   \(selectedReport.weight != nil ? "\(selectedReport.weight!)" : "-") kg   \(selectedReport.count != nil ? "\(selectedReport.count!)" : "-") 회")
                                                            .font(.m_14())
                                                            .foregroundStyle(.darkGraySet)
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 30)
                                                .padding(.vertical, 25)
                                            }
                                            
                                            ThickDivider()
                                        }
                                        
                                        if let firstInfo = store.rawInfos.filter({
                                            $0.setIndex == setIndex &&
                                            $0.startTime == store.report.setTimes[setIndex] &&
                                            $0.muscleName == store.initMuscleName ?? store.report.muscleName[0]
                                        }).first {
                                            ActivationView(
                                                geometry: geometry,
                                                rawInfos: store.rawInfos,
                                                report: store.report,
                                                reports: store.reports,
                                                setIndex: store.setIndex,
                                                clipIndex: store.report.muscleName.firstIndex(where: { $0 == store.initMuscleName }) ?? 0,
                                                firstInfo: firstInfo,
                                                getSetReport: {store.send(.getBTSetReport($0))},
                                                getRawData: {store.send(.getBTRawData($0))},
                                                goToEdit: {store.send(.goToEdit($0))}
                                            )
                                        }
                                        
                                    } else {
                                        if store.isFromLog {
                                            BTSummaryView(report: store.report, btParam: btParam)
                                        }
                                    }
                                }
                            }
                            if !store.isFromLog {
                                Spacer()
                                okButton(action: {
                                    if !swipeBack {
                                        if let _ = store.selectedReport {
                                            store.send(.delegate(.goToMainList(store.report)))
                                        }
                                        
                                    }
                                    else {
                                        store.send(.dismiss)
                                    }
                                })
                                .padding(20)
                            } else {
                                Spacer().frame(height: 20)
                            }
                        }
                        else {
                            Spacer()
                            HStack{
                                Spacer()
                                ProgressView()
                                    .onAppear {
                                        if store.btParam == nil {
                                            store.send(.getBTParam)
                                        }
                                        if store.reportsNotToday == nil {
                                            store.send(.getReportsNotToday)
                                        }
                                    }
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .basicToolbar(
                title: "운동 평가",
                swipeBack: swipeBack,
                closeButtonAction: swipeBack ? nil : {
                    if let _ = store.selectedReport {
                        store.send(.delegate(.goToMainList(store.report)))
                    }
                }
            )
            .navigationDestination(item: $store.scope(state: \.destination?.edit, action: \.destination.edit)) { store in
                WithPerceptionTracking {
                    BTEditMuscleNameView(store: store)
                }
            }
            
        }
    }
    
    private struct ActivationView: View {
        let geometry: GeometryProxy
        let rawInfos: [RawInfo]
        let report: ReportBTDTO
        let reports: [ReportBTDTO]
        let setIndex: Int?
        let clipIndex: Int
        
        @State var firstInfo: RawInfo
        @State var lastInfo: RawInfo?
        
        let getSetReport: (RawInfo) -> ()
        let getRawData: (RawInfo) -> ()
        let goToEdit: (Int) -> ()
        
        
        func setFirstInfo(_ rawInfo: RawInfo) {
            firstInfo = rawInfo
            if let report = reports.first(where: {$0.dashboardTime == firstInfo.dashboardTime}) {
                if let setReport = report.reportSets[firstInfo.setIndex] {
                    if setReport.rawData == nil {
                        getRawData(firstInfo)
                    }
                }
                else {
                    getSetReport(firstInfo)
                }
            }
        }
        
        func setLastInfo(_ rawInfo: RawInfo?) {
            lastInfo = rawInfo
            if let lastInfo {
                if let report = reports.first(where: {$0.dashboardTime == lastInfo.dashboardTime}) {
                    if let setReport = report.reportSets[lastInfo.setIndex] {
                        if setReport.rawData == nil {
                            getRawData(lastInfo)
                        }
                    }
                    else{
                        getSetReport(lastInfo)
                    }
                }
            }
        }
        
        var body: some View {
            WithPerceptionTracking {
                let todayRawInfos: [RawInfo] = rawInfos.filter { $0.dashboardTime == report.dashboardTime }
                let previousRawInfos: [RawInfo] = rawInfos.filter{ !todayRawInfos.contains($0) }
                VStack {
                    HStack {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.whiteLightGray, lineWidth: 1.0)
                            .frame(height: 53)
                            .overlay {
                                HStack {
                                    Text(firstInfo.str)
                                        .font(.m_16())
                                        .foregroundStyle(.lightBlack)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(.blue)
                                }
                                .padding(.horizontal, 11)
                                .padding(.leading, 3)
                            }
                            .overlay {
                                Picker("longlongemtpytexthere", selection: $firstInfo) {
                                    Section("오늘 측정") {
                                        ForEach(todayRawInfos, id: \.self) { rawInfo in
                                            Text(rawInfo.str)
                                                .tag(rawInfo)
                                        }
                                    }
                                }
                                .frame(height: 53)
                                .frame(maxWidth: .infinity)
                                .pickerStyle(.menu)
                                .opacity(0.025)
                            }
                        
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.whiteLightGray, lineWidth: 1.0)
                            .frame(height: 53)
                            .overlay {
                                HStack {
                                    Text(lastInfo?.str ?? "-")
                                        .font(.m_16())
                                        .foregroundStyle(.lightBlack)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(.blue)
                                }
                                .padding(.horizontal, 11)
                                .padding(.leading, 3)
                            }
                            .overlay {
                                Picker("longlongemtpytexthere", selection: $lastInfo) {
                                    Text("없음                                         ")
                                        .tag(nil as RawInfo?)
                                    Section("오늘 측정") {
                                        ForEach(todayRawInfos, id: \.self) { rawInfo in
                                            Text(rawInfo.str)
                                                .tag(rawInfo as RawInfo?)
                                        }
                                    }
                                    Section("이전 측정") {
                                        ForEach(previousRawInfos, id: \.self) { rawInfo in
                                            Text(rawInfo.str)
                                                .tag(rawInfo as RawInfo?)
                                        }
                                    }
                                }
                                .frame(height: 53)
                                .frame(maxWidth: .infinity)
                                .pickerStyle(.menu)
                                .opacity(0.025)
                            }
                    }
                    .padding(.horizontal, 25)
                    
                    Spacer().frame(height: 30)
                    
                    if
                        let firstReport = reports.first(where: {$0.dashboardTime == firstInfo.dashboardTime})
                    {
                        if
                            let _ = firstReport.reportSets[firstInfo.setIndex],
                            (lastInfo == nil || reports.first(where: { $0.dashboardTime == lastInfo!.dashboardTime })?.reportSets[lastInfo!.setIndex] != nil)
                        {
                            VStack(alignment: .center ,spacing: 0){
                                HStack {
                                    VStack {
                                        VStack {
                                            HStack(spacing:0){
                                                Spacer().frame(width: 6)
                                                Text(firstInfo.muscleName)
                                                    .font(.m_18())
                                                    .foregroundStyle(.lightBlack)
                                                Spacer().frame(width: 10)
                                                
                                                let muscleIndex = report.muscleName.firstIndex{$0 == firstInfo.muscleName}
                                                Button(action: {
                                                    if let muscleIndex {
                                                        goToEdit(muscleIndex)
                                                    }
                                                }, label: {
                                                    Image(systemName: "pencil")
                                                        .resizable()
                                                        .frame(width: 14, height: 14)
                                                        .foregroundStyle(.whiteLightGray)
                                                })
                                            }
                                            Spacer().frame(height: 7)
                                            Text("\(firstInfo.timeStr) / \(firstInfo.setIndex + 1)세트")
                                                .font(.r_12())
                                                .foregroundStyle(.lightGraySet)
                                            
                                            Spacer().frame(height: 20)
                                        }
                                        .frame(height: 45)
                                        
                                        Text("수축 활성도")
                                            .font(.r_14())
                                            .foregroundStyle(.darkGraySet)
                                        Spacer().frame(height: 10)
                                        
                                        
                                        if
                                            let firstReport = reports.first(where: { $0.setTimes.contains(where: { $0 == firstInfo.startTime }) } ),
                                            let firstReportSet = firstReport.reportSets[firstInfo.setIndex],
                                            let muscleIndex = firstReport.muscleName.firstIndex(of: firstInfo.muscleName),
                                            let val = firstReportSet.top[safe: muscleIndex]
                                        {
                                            HStack {
                                                Text(String(format: "%.2f", val))
                                                    .font(.s_22())
                                                    .foregroundStyle(.lightBlack)
                                                Spacer().frame(width: 8)
                                                Text("μV")
                                                    .font(.r_12())
                                                    .foregroundStyle(.darkGraySet)
                                                    .offset(y: 3)
                                            }
                                        } else {
                                            Text("-")
                                                .font(.s_22())
                                                .foregroundStyle(.lightBlack)
                                        }
                                        
                                        Spacer().frame(height: 25)
                                        
                                        Text("이완 활성도")
                                            .font(.r_14())
                                            .foregroundStyle(.darkGraySet)
                                        Spacer().frame(height: 10)
                                        
                                        if
                                            let firstReport = reports.first(where: { $0.setTimes.contains(where: { $0 == firstInfo.startTime }) } ),
                                            let firstReportSet = firstReport.reportSets[firstInfo.setIndex],
                                            let muscleIndex = firstReport.muscleName.firstIndex(of: firstInfo.muscleName),
                                            let val = firstReportSet.low[safe: muscleIndex]
                                        {
                                            HStack {
                                                Text(String(format: "%.2f", val))
                                                    .font(.s_22())
                                                    .foregroundStyle(.lightBlack)
                                                Spacer().frame(width: 8)
                                                Text("μV")
                                                    .font(.r_12())
                                                    .foregroundStyle(.darkGraySet)
                                                    .offset(y: 3)
                                            }
                                        } else {
                                            Text("-")
                                                .font(.s_22())
                                                .foregroundStyle(.lightBlack)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                                    
                                    Divider()
                                    
                                    VStack {
                                        VStack {
                                            if let lastInfo {
                                                Text(lastInfo.muscleName)
                                                    .font(.m_18())
                                                    .foregroundStyle(.lightBlack)
                                                Spacer().frame(height: 7)
                                                Text("\(lastInfo.timeStr) / \(lastInfo.setIndex + 1)세트")
                                                    .font(.r_12())
                                                    .foregroundStyle(.lightGraySet)
                                                
                                                Spacer().frame(height: 20)
                                            } else {
                                                Spacer()
                                                Text("-")
                                                    .font(.m_18())
                                                    .foregroundStyle(.lightBlack)
                                                Spacer()
                                            }
                                        }
                                        .frame(height: 45)
                                        
                                        Text("수축 활성도")
                                            .font(.r_14())
                                            .foregroundStyle(.darkGraySet)
                                        Spacer().frame(height: 10)
                                        
                                        if let lastInfo,
                                           let lastReport = reports.first(where: { $0.setTimes.contains(where: { $0 == lastInfo.startTime}) } ),
                                           let lastReportSet = lastReport.reportSets[safe: lastInfo.setIndex],
                                           let muscleIndex = lastReport.muscleName.firstIndex(of: lastInfo.muscleName),
                                           let val = lastReportSet?.top[safe: muscleIndex] {
                                            
                                            HStack {
                                                Text(String(format: "%.2f", val))
                                                    .font(.s_22())
                                                    .foregroundStyle(.lightBlack)
                                                Spacer().frame(width: 8)
                                                Text("μV")
                                                    .font(.r_12())
                                                    .foregroundStyle(.darkGraySet)
                                                    .offset(y: 3)
                                            }
                                        } else {
                                            Text("-")
                                                .font(.s_22())
                                                .foregroundStyle(.lightBlack)
                                        }
                                        
                                        Spacer().frame(height: 25)
                                        
                                        Text("이완 활성도")
                                            .font(.r_14())
                                            .foregroundStyle(.darkGraySet)
                                        Spacer().frame(height: 10)
                                        
                                        if let lastInfo,
                                           let lastReport = reports.first(where: { $0.setTimes.contains(where: { $0 == lastInfo.startTime}) } ),
                                           let lastReportSet = lastReport.reportSets[safe: lastInfo.setIndex],
                                           let muscleIndex = lastReport.muscleName.firstIndex(of: lastInfo.muscleName),
                                           let val = lastReportSet?.low[safe: muscleIndex] {
                                            HStack {
                                                Text(String(format: "%.2f", val))
                                                    .font(.s_22())
                                                    .foregroundStyle(.lightBlack)
                                                Spacer().frame(width: 8)
                                                Text("μV")
                                                    .font(.r_12())
                                                    .foregroundStyle(.darkGraySet)
                                                    .offset(y: 3)
                                            }
                                        } else {
                                            Text("-")
                                                .font(.s_22())
                                                .foregroundStyle(.lightBlack)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                                }
                                
                                Divider()
                                
                                Spacer().frame(height: 30)
                                
                                if (!firstInfo.rawData.isEmpty && (lastInfo == nil || lastInfo?.rawData.isEmpty == false)) {
                                    let maxData = Int(min(10000, max(4150, max(firstInfo.rawData.max() ?? 0, lastInfo?.rawData.max() ?? 0))))
                                    let minData = 0
                                    
                                    ZStack(alignment: .leading){
                                        VStack(spacing: 0){
                                            HStack(spacing: 9){
                                                Rectangle()
                                                    .frame(width: 1, height: 160)
                                                    .foregroundColor(.whiteLightGray)
                                                VStack(alignment: .leading){
                                                    Text("\(Int(ceil(valueToqV(Float(maxData)))))")
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
                                            let graphWidth: CGFloat =
                                                (geometry.size.width - 42) * CGFloat(max(1, max(firstInfo.rawData.count, lastInfo?.rawData.count ?? 0) / 600))
                                            VStack(spacing: 0){
                                                var names: [String?] {
                                                    if let lastInfo {
                                                        if firstInfo.muscleName == lastInfo.muscleName {
                                                            return ["\(Double(firstInfo.dashboardTime).unixTimeToDateStr("MM.dd")) \(firstInfo.setIndex + 1)세트 \(firstInfo.muscleName)", "\(Double(lastInfo.dashboardTime).unixTimeToDateStr("MM.dd")) \(lastInfo.setIndex + 1)세트 \(lastInfo.muscleName)"]
                                                        } else {
                                                            return [firstInfo.muscleName, lastInfo.muscleName]
                                                        }
                                                    } else {
                                                        return [firstInfo.muscleName]
                                                    }
                                                    
                                                }
                                                RawDataGraph(
                                                    names: names.compactMap({$0}),
                                                    rawDatas: [firstInfo.rawData, lastInfo?.rawData].compactMap({$0}),
                                                    minData: Float(minData),
                                                    maxData: Float(maxData)
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
                                        Text(firstInfo.muscleName)
                                            .font(.m_14())
                                            .foregroundColor(.lightGraySet)
                                        
                                        if let lastInfo{
                                            Spacer().frame(width: 14)
                                            Rectangle()
                                                .frame(width: 17, height: 1)
                                                .foregroundColor(.red)
                                            Spacer().frame(width: 8)
                                            Text(lastInfo.muscleName)
                                                .font(.m_14())
                                                .foregroundColor(.lightGraySet)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 25)
                                } else {
                                    VStack {
                                        Spacer().frame(height: 100)
                                        ProgressView()
                                        Spacer().frame(height: 100)
                                    }
                                    .onAppear {
                                        if firstInfo.rawData.isEmpty {
                                            print("firstInfo rawdata empty, firstInfo = \(firstInfo)")
                                            getRawData(firstInfo)
                                        }
                                        if lastInfo?.rawData.isEmpty == true {
                                            print("lastInfo rawdata empty, lasttInfo = \(lastInfo)")
                                            getRawData(lastInfo!)
                                        }
                                    }
                                }
                            }
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow2()
                            .padding(.horizontal, 21)
                        } else {
                            Spacer().frame(height: 250)
                            ProgressView()
                                .onAppear {
                                    if firstReport.reportSets[firstInfo.setIndex] == nil {
                                        getSetReport(firstInfo)
                                    }
                                    if
                                        let lastInfo,
                                            reports.first(where: { $0.dashboardTime == lastInfo.dashboardTime })?.reportSets[lastInfo.setIndex] == nil
                                    {
                                        getSetReport(lastInfo)
                                    }
                                }
                            Spacer().frame(height: 250)
                        }
                    }
                }
                .padding(.vertical, 30)
            }
            .onChange(of: setIndex) { newValue in
                setFirstInfo(rawInfos.first{ $0.setIndex == newValue && $0.muscleName == report.muscleName[clipIndex] }!)
                setLastInfo(nil)
            }
            .onChange(of: rawInfos) { newValue in
                if newValue.map({ $0.muscleName }) != rawInfos.map({ $0.muscleName }) {
                    setFirstInfo(newValue.filter{ $0.setIndex == firstInfo.setIndex && $0.startTime == firstInfo.startTime }[clipIndex])
                    setLastInfo(nil)
                }
                if newValue.map({ $0.rawData }) != rawInfos.map({ $0.rawData }) {
                    setFirstInfo(newValue.first(where: { $0.setIndex == firstInfo.setIndex && $0.startTime == firstInfo.startTime && $0.muscleName == firstInfo.muscleName })!)
                    setLastInfo(newValue.first(where: { $0.setIndex == lastInfo?.setIndex && $0.startTime == lastInfo?.startTime && $0.muscleName == lastInfo?.muscleName}))
                }
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
}

struct ActivationCard: View {
    let color: Color
    let maxData: Float
    let data: Float?
    let label: String
    
    var body: some View {
        VStack(spacing: 20){
            CircleGraph(data: data, maxData: maxData, unit: "%", color: color)
                .frame(minWidth: 90)
            Text(label)
                .font(.r_12())
                .foregroundStyle(.darkGraySet)
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 20)
        .aspectRatio(1, contentMode: .fit)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow2()
    }
}

struct BTSummaryView: View {
    let report: ReportBTDTO
    let btParam: BTParam
    
    var body: some View {
        let reportSets = report.reportSets.compactMap({ $0 })
        
        VStack(spacing: 0){
            Spacer().frame(height: 25)
            HStack{
                var time: String {
                    let timeInterval = Double(report.dashboardTime)
                    let formattedString = timeInterval.unixTimeToDateStr("yy.MM.dd")
                    return formattedString
                }
                Text("수축 활성도")
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
            
            ForEach(0..<report.muscleName.count, id: \.self) { muscleIndex in
                LineGraph(
                    title: report.muscleName[muscleIndex],
                    unit: nil,
                    labels: setLabels,
                    scores: reportSets.map({ $0.top[muscleIndex] })
                )
                .frame(height: 130)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                if muscleIndex != report.muscleName.count - 1 {
                    Divider()
                    Spacer().frame(height: 20)
                }
            }
            
            ThickDivider()
            
            Spacer().frame(height: 25)
            HStack{
                var time: String {
                    let timeInterval = Double(report.dashboardTime)
                    let formattedString = timeInterval.unixTimeToDateStr("yy.MM.dd")
                    return formattedString
                }
                Text("이완 활성도")
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
            
            ForEach(0..<report.muscleName.count) { muscleIndex in
                LineGraph(
                    title: report.muscleName[muscleIndex],
                    unit: nil,
                    labels: setLabels,
                    scores: reportSets.map({ $0.low[muscleIndex] })
                )
                .frame(height: 130)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                if muscleIndex != report.muscleName.count - 1 {
                    Divider()
                    Spacer().frame(height: 20)
                }
            }
            
            let setWithWeight = reportSets.filter({ $0.weight != nil })
            let weightLabels = setWithWeight.map({
                "\((reportSets.firstIndex(of: $0) ?? -1) + 1)세트"
            })
            
            if !setWithWeight.isEmpty {
                
                ThickDivider()
                
                Spacer().frame(height: 25)
                HStack{
                    var time: String {
                        let timeInterval = Double(report.dashboardTime)
                        let formattedString = timeInterval.unixTimeToDateStr("yy.MM.dd")
                        return formattedString
                    }
                    Text("중량")
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
                
                LineGraph(
                    title: "중량",
                    unit: "kg",
                    labels: weightLabels,
                    scores: setWithWeight.map({ Float($0.weight!) })
                )
                .frame(height: 130)
                .padding(.horizontal, 20)
            }
            
            Spacer().frame(height: 25)
        }
    }
}
