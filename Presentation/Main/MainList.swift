//
//  MainList.swift
//  WorkwayVer2
//
//  Created by loyH on 8/7/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct MainList{
    @Reducer(state: .equatable)
    enum Destination {
        case test(MainTestFeature)
        case stReport(StReport)
        case ftReport(FtReport)
        case etReport(EtReport)
        case btReport(BtReport)
        case addTestBottomSheet(MainAddTest)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        var who: String
        var startTime: Int
        
        var endBottomSheetShown: Bool = false
        var endFullScreenShown: Bool = false
        var btMuscleNameSheetShown: Bool = false
        
        var stReports: [ReportST?] = []
        var ftReports: [ReportFTDTO?] = []
        var etReports: [ReportETDTO] = []
        var btReports: [ReportBTDTO] = []
        var reportBTsNotToday: [ReportBTDTO]?
        
        var selectedBT: ReportBTDTO?
        
        var reportOrderList: [ReportType] = []
        
        var dashboardCount: Int?
        var lastTestAttach: ReportType?
        
        init(destination: Destination.State? = nil,  who: String, startTime: Int, stReports: [ReportST?], ftReports: [ReportFTDTO?], etReports: [ReportETDTO], btReports: [ReportBTDTO]) {
            self.destination = destination
            self.who = who
            self.startTime = startTime
            self.stReports = stReports
            self.ftReports = ftReports
            self.etReports = etReports
            self.btReports = btReports
            
            if !stReports.isEmpty {
                self.reportOrderList.append(ReportType(testType: .SPINE, exid: 0, name: TestType.SPINE.rawValue))
            }
            else if !ftReports.isEmpty {
                self.reportOrderList.append(ReportType(testType: .FUNC, exid: 0, name: TestType.FUNC.rawValue))
            }
        }
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        
        case showAddTestBottomSheet
        
        case toggleEndBottomSheetShown
        case toggleEndFullScreenShown
        case toggleBtMuscleNameSheetShown
        case showBtMuscleName(ReportType)
        
        case add(ReportType)          // 빈 레포트(nil) 추가
        case remove(ReportType)       // 마지막 빈 레포트 삭제
        case setReport(any Report, ReportType)
        
        case goToStReport(ReportST)
        case goToFtReport(ReportFTDTO)
        case goToEtReport(ReportETSetDTO)
        case goToBtReport(ReportBTSetDTO)
        case startTest(ReportType, Bool, Bool) // Bool -> 1st = 허브의 연결 유무, 2nd 클립.isEmpty
        
        case endMeasurement
        case getDashboardCount
        case setDashboardCount(Int)
        
        case destination(PresentationAction<Destination.Action>)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case goToHome
            case goToRecentLog
        }
    }
    
    @Dependency(\.reportRepository) var reportRepository
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action {
            case .binding:
                return .none
                
            case .showAddTestBottomSheet:
                state.destination = .addTestBottomSheet(.init())
                return .none
                
            case .toggleEndBottomSheetShown:
                state.endBottomSheetShown.toggle()
                return .none
            case .toggleEndFullScreenShown:
                state.endFullScreenShown.toggle()
                return .none
            case .toggleBtMuscleNameSheetShown:
                state.btMuscleNameSheetShown.toggle()
                return .none
            case let .showBtMuscleName(reportType):
                guard let report = state.btReports.first(where: { $0.name == reportType.name }) else {return .none}
                state.selectedBT = report
                return .send(.toggleBtMuscleNameSheetShown)
                
            case let .add(reportType):
                switch reportType.testType {
                case .SPINE:
                    if state.stReports.isEmpty {
                        state.reportOrderList.append(reportType)
                    }
                    state.stReports.append(nil)
                    return .none
                case .FUNC:
                    if state.ftReports.isEmpty {
                        state.reportOrderList.append(reportType)
                    }
                    state.ftReports.append(nil)
                    return .none
                case .EXER:
                    if let index = state.etReports.firstIndex(where: { $0.exerciseId == reportType.exid }) {
                        state.etReports[index].reportSets?.append(nil)
                    }
                    else{
                        state.reportOrderList.append(reportType)
                        state.etReports.append(.init(reportId: "", who: state.who, exerciseId: reportType.exid, dashboardTime: state.startTime, exerciseTime: 0, reportSets: [nil]))
                    }
                    return .none
                case .BRIEF:
                    if let index = state.btReports.firstIndex(where: { $0.name == reportType.name }) {
                        state.btReports[index].reportSets.append(nil)
                    }
                    else{
                        var btReportType = reportType
                        if btReportType.name == TestType.BRIEF.rawValue {
                            let btCnt: Int = (Int(state.btReports.last?.name.split(separator: " ").last ?? "0") ?? 0) + 1
                            btReportType.name = "\(TestType.BRIEF.rawValue) \(btCnt)"
                        }
                        state.reportOrderList.append(btReportType)
                        
                        state.btReports.append(.init(reportId: "", who: state.who, name: btReportType.name, dashboardTime: state.startTime, setTimes: [], muscleName: [], exerciseTime: 0, reportSets: [nil]))
                    }
                    return .none
                }
                
            case let .remove(reportType):
                switch reportType.testType {
                case .SPINE:
                    if state.stReports.contains(nil){
                        state.stReports.removeLast()
                    }
                    if state.stReports.isEmpty {
                        state.reportOrderList.removeAll(where: {$0 == reportType})
                    }
                    return .none
                case .FUNC:
                    if state.ftReports.contains(nil){
                        state.ftReports.removeLast()
                    }
                    if state.ftReports.isEmpty {
                        state.reportOrderList.removeAll(where: {$0 == reportType})
                    }
                    return .none
                case .EXER:
                    if let index = state.etReports.firstIndex(where: { $0.exerciseId == reportType.exid }) {
                        if state.etReports[index].reportSets?.contains(nil) == true{
                            state.etReports[index].reportSets?.removeLast()
                        }
                        if state.etReports[index].reportSets?.isEmpty == true {
                            state.etReports.remove(at: index)
                            state.reportOrderList.removeAll(where: {$0 == reportType})
                        }
                    }
                    return .none
                case .BRIEF:
                    if let index = state.btReports.firstIndex(where: { $0.name == reportType.name }) {
                        if state.btReports[index].reportSets.contains(nil) == true{
                            state.btReports[index].reportSets.removeLast()
                        }
                        if state.btReports[index].reportSets.isEmpty == true {
                            state.btReports.remove(at: index)
                            state.reportOrderList.removeAll(where: {$0 == reportType})
                        }
                    }
                    return .none
                }
                
            case let .setReport(report, reportType):
                switch reportType.testType{
                case .SPINE:
                    if let index = state.stReports.firstIndex(of: nil){
                        state.stReports[index] = report as! ReportST
                    }
                case .FUNC:
                    if let index = state.ftReports.firstIndex(of: nil){
                        state.ftReports[index] = report as! ReportFTDTO
                    }
                case .EXER:
                    if let index = state.etReports.firstIndex(where: { $0.exerciseId == reportType.exid }) {
                        state.etReports[index].addReportSet(rSet: report as! ReportETSetDTO)
                    }
                case .BRIEF:
                    return .none
                }
                return .none
                
            case let .goToStReport(st):
                let lastReport: ReportST? = {
                    if let index = state.stReports.firstIndex(of: st), index > 0 {
                        return state.stReports[index - 1]
                    }
                    return nil
                }()
                
                state.destination = .stReport(.init(report: st, lastReport: lastReport))
                return .none
                
            case let .goToFtReport(ft):
                if let index = state.ftReports.firstIndex(of: ft), index > 0 {
                    let lastReport = state.ftReports[index - 1]
                    state.destination = .ftReport(.init(setIndex: 0, reports: [ft], lastReport: lastReport, isFromLog: false))
                } else {
                    state.destination = .ftReport(.init(setIndex: 0, reports: [ft], lastReport: nil, isFromLog: false))
                }
                
                return .none
                
            case let .goToEtReport(et):
                if let report = state.etReports.first(where: { $0.reportSets?.contains(et) == true }){
                    if let index = report.reportSets?.firstIndex(of: et){
                        state.destination = .etReport(.init(report: report, setIndex: index, isFromLog: false))
                    }
                }
                return .none
                
            case let .goToBtReport(btSet):
                if let report = state.btReports.first(where: { $0.reportSets.contains(btSet) == true }){
                    if let setIndex = report.reportSets.firstIndex(of: btSet){
                        state.destination = .btReport(.init(
                            setIndex: setIndex,
                            initMuscleName: nil,
                            reports: state.btReports,
                            reportsNotToday: state.reportBTsNotToday,
                            selectedReportName: report.name,
                            isFromLog: false
                        ))
                    }
                }
                return .none
                
            case let .startTest(reportType, hubEnable, isClipsEmpty):
                var setIndex: Int? {
                    switch reportType.testType{
                    case .SPINE:
                        return state.stReports.firstIndex(where: {$0 == nil})
                    case .FUNC:
                        return state.ftReports.firstIndex(where: {$0 == nil})
                    case .EXER:
                        return state.etReports.first(where: { $0.exerciseId == reportType.exid })?.reportSets?.firstIndex(where: { $0 == nil })
                    case .BRIEF:
                        return state.btReports.first(where: { $0.name == reportType.name })?.reportSets.firstIndex(where: { $0 == nil })
                    }
                }
                
                state.destination = .test(.init(
                    who: state.who,
                    dashboardTime: state.startTime,
                    reportType: reportType,
                    etReport: state.etReports.first{$0.exerciseId == reportType.exid},
                    selectedBTName: reportType.name,
                    setIndex: setIndex,
                    hubEnable: hubEnable,
                    reportBTs: state.btReports,
                    reportBTsNotToday: state.reportBTsNotToday, 
                    skipAttach: (reportType.testType == state.lastTestAttach?.testType && reportType.testType == .BRIEF && (reportType.name == state.lastTestAttach?.name)) && !isClipsEmpty
                ))
                return .none
                
            case .getDashboardCount:
                if state.dashboardCount != nil {
                    return .none
                }
                return .run { [who = state.who] send in
                    do {
                        let count = try await reportRepository.getDashboardCount(who: who)
                        await send(.setDashboardCount(count))
                    } catch {
                        print("MainList/getDashboardCount: error \(error)")
                    }
                }
                
            case let .setDashboardCount(count):
                state.dashboardCount = count
                return .none
                
            case .endMeasurement:
                return .none
                
                
            case let .destination(.presented(.test(.delegate(delegateAction)))):
                switch delegateAction {
                case let .setReportETId(exid, reportId):
                    if let exIndex = state.etReports.firstIndex(where: { $0.exerciseId == exid}) {
                        state.etReports[exIndex].reportId = reportId
                    }
                    return .none
                    
                case let .setReportBT(rBT):
                    if let rBTIndex = state.btReports.firstIndex(where: { $0.name == rBT.name }) {
                        state.btReports[rBTIndex] = rBT
                        return .run { [rBT = rBT] _ in
                            do {
                                try await reportRepository.setReportBT(reportBT: rBT)
                            } catch {
                                print("MainList/setReportBT: error setting report \(error)")
                            }
                        }
                    }
                    return .none
                    
                case let .setMuscleName(name, muscleName):
                    state.lastTestAttach = .init(testType: .BRIEF, exid: -1, name: name)
                    if let index = state.btReports.firstIndex(where: { $0.name == name}) {
                        state.btReports[index].muscleName = muscleName
                        if state.btReports[index].reportId != "" {
                            return .run { [reportId = state.btReports[index].reportId]  _ in
                                do {
                                    try await reportRepository.setBTNames(reportBTId: reportId, muscleNames: muscleName)
                                } catch {
                                    print("MainList/setMuscleName: error setting BT Names \(error)")
                                }
                            }
                        }
                    }
                    return .none
                    
                case let .setLastTestAttach(testType):
                    state.lastTestAttach = testType
                    return .none
                    
                case let .goToMainList(report, reportType):
                    state.destination = nil
                    if let report {
                        return .send(.setReport(report, reportType))
                    }
                    return .none
                case let .goToMainListBT(rBT):
                    state.destination = nil
                    if let rBT, let rBTIndex = state.btReports.firstIndex(where: { $0.name == rBT.name }) {
                        state.btReports[rBTIndex] = rBT
                    }
                    return .none
                case let .setReportBTsNotToday(rBTs):
                    state.reportBTsNotToday = rBTs
                    return .none
                }
                
            case let .destination(.presented(.stReport(.delegate(delegateAction)))):
                switch delegateAction {
                case .goToMainList:
                    state.destination = nil
                    return .none
                }
            case let .destination(.presented(.ftReport(.delegate(delegateAction)))):
                switch delegateAction {
                case .goToMainList:
                    state.destination = nil
                    return .none
                }
            case let .destination(.presented(.etReport(.delegate(delegateAction)))):
                switch delegateAction {
                case .goToMainList:
                    state.destination = nil
                    return .none
                }
                
            case let .destination(.presented(.btReport(.delegate(delegateAction)))):
                switch delegateAction {
                case .goToMainList:
                    state.destination = nil
                    return .none
                case let .setReportBTsNotToday(reports):
                    state.reportBTsNotToday = reports
                    return .none
                }
                
            case let .destination(.presented(.addTestBottomSheet(.delegate(delegateAction)))):
                switch delegateAction {
                case let .add(reportType):
                    return .send(.add(reportType))
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

struct MainListView: View {
    @Perception.Bindable var store: StoreOf<MainList>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    @State var task: Task<Void, Never>? = nil
    @State var time: Double = Date().timeIntervalSince1970
    
    @State var onBoard: Bool = false
    @State var onLogic: Bool = false
    
    var body: some View {
        WithPerceptionTracking{
            GeometryReader{ geometry in
                WithPerceptionTracking {
                    ZStack {
                        VStack(alignment: .leading, spacing:0){
                            HStack {
                                Spacer()
                                Button(action: {
                                    store.send(.toggleEndBottomSheetShown)
                                }, label: {
                                    Text("완료")
                                        .font(.m_18())
                                        .foregroundStyle(.mainBlue)
                                })
                                .padding()
                            }
                            .background(.lightBlack)
                            HStack(spacing: 10){
                                Image(systemName: "stopwatch.fill")
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.whiteLightGray)
                                let timeInterval: Double = time - Double(store.startTime)
                                Text("전체 운동 시간 \(timeInterval.unixTimeToStopWatchTime())")
                                    .font(.m_14())
                                    .foregroundStyle(.whiteLightGray)
                                Spacer()
                            }
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .background(.lightBlack)
                            
                            testListView()
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Button(action: {
                                store.send(.showAddTestBottomSheet)
                            }, label: {
                                Image(systemName: "plus")
                                    .font(.title.weight(.semibold))
                                    .padding()
                                    .background(.darkGraySet)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            })
                            .padding()
                        }
                        .overlay(content: {
                            if store.destination != nil {
                                Color.black.opacity(0.7)
                            }
                        })
                        .background(.backgroundGray)
                        .toolbar(.hidden, for: .navigationBar)
                        .fullScreenCover(item: $store.scope(state: \.destination?.test, action: \.destination.test)) { store in
                            WithPerceptionTracking {
                                MainTestNavigation(store: store)
                                    .environmentObject(bluetoothManager)
                            }
                        }
                        .onAppear{
                            task = Task{
                                while true{
                                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10초마다
                                    time = Date().timeIntervalSince1970
                                }
                            }
                            bluetoothManager.requestBattInfo()
                        }
                        .onDisappear{
                            task?.cancel()
                        }
                        .sheet(item: $store.scope(state: \.destination?.addTestBottomSheet, action: \.destination.addTestBottomSheet)) { store in
                            WithPerceptionTracking {
                                MainAddTestView(store: store)
                                    .presentationDetents([.height(geometry.size.height - 100)])
                                    .presentationCornerRadius(20)
                            }
                        }
                        .sheet(isPresented: $store.btMuscleNameSheetShown, content: {
                            WithPerceptionTracking {
                                if let report = store.selectedBT {
                                    VStack(spacing: 0){
                                        Spacer().frame(height: 40)
                                        Text(report.name)
                                            .font(.s_18())
                                            .foregroundStyle(.lightBlack)
                                        
                                        Spacer().frame(height: 35)
                                        
                                        if report.muscleName.isEmpty {
                                            Text("근육 정보를 설정하지 않았습니다")
                                                .font(.m_16())
                                                .foregroundStyle(.lightGraySet)
                                        } else {
                                            HStack(spacing: 35) {
                                                VStack(spacing: 22){
                                                    ForEach(0..<(report.muscleName.count + 1)/2) { evenIndex in
                                                        Text(report.muscleName[evenIndex * 2])
                                                            .font(.m_16())
                                                            .foregroundStyle(.lightGraySet)
                                                    }
                                                }
                                                
                                                VStack(spacing: 22){
                                                    ForEach(0..<(report.muscleName.count + 1)/2, id: \.self) { evenIndex in
                                                        Text(report.muscleName[safe: evenIndex * 2 + 1] ?? "")
                                                            .font(.m_16())
                                                            .foregroundStyle(.lightGraySet)
                                                    }
                                                }
                                            }
                                        }
                                        Spacer().frame(height: 50)
                                        okButton(action: {
                                            store.send(.toggleBtMuscleNameSheetShown)
                                        })
                                        Spacer().frame(height: 22)
                                    }
                                    .padding(.horizontal, 20)
                                    .presentationDetents([.height(CGFloat(240 + (44 * report.muscleName.count) - 22))])
                                    .presentationCornerRadius(20)
                                }
                            }
                        })
                        .sheet(isPresented: $store.endBottomSheetShown, content: {
                            WithPerceptionTracking {
                                VStack(alignment: .leading, spacing: 0){
                                    Spacer().frame(height: 30)
                                    VStack(alignment: .leading, spacing: 0){
                                        Text("측정을 종료하시겠습니까?")
                                            .font(.s_18())
                                            .foregroundStyle(.lightBlack)
                                        Spacer().frame(height: 20)
                                        Text("완료되지 않은 운동은 기록되지 않습니다.")
                                            .font(.m_16())
                                            .foregroundStyle(.lightGraySet)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    Spacer()
                                    
                                    twoButton(
                                        geometry: geometry,
                                        leftName: "취소",
                                        leftAction: {
                                            store.send(.toggleEndBottomSheetShown)
                                        },
                                        rightName: "종료하기",
                                        rightAction: {
                                            let stReports: [ReportST] = store.stReports.compactMap { $0 }
                                            let ftReports: [ReportFTDTO] = store.ftReports.compactMap { $0 }
                                            let etReports: [ReportETDTO] =  store.etReports.compactMap { report in
                                                guard var nonNilReportSets = report.reportSets else { return nil }
                                                nonNilReportSets = nonNilReportSets.compactMap { $0 }
                                                guard !nonNilReportSets.isEmpty else { return nil }
                                                return ReportETDTO(
                                                    reportId: report.reportId,
                                                    who: report.who,
                                                    exerciseId: report.exerciseId,
                                                    dashboardTime: report.dashboardTime,
                                                    exerciseTime: report.exerciseTime,
                                                    reportSets: nonNilReportSets
                                                )
                                            }
                                            let btReports: [ReportBTDTO] =  store.btReports.compactMap { report in
                                                let nonNilReportSets = report.reportSets.compactMap({ $0 })
                                                guard !nonNilReportSets.isEmpty else { return nil }
                                                
                                                return ReportBTDTO(
                                                    reportId: report.reportId,
                                                    who: report.who,
                                                    name: report.name,
                                                    dashboardTime: report.dashboardTime,
                                                    setTimes: nonNilReportSets.map({ $0.time }),
                                                    muscleName: report.muscleName,
                                                    exerciseTime: report.exerciseTime,
                                                    reportSets: nonNilReportSets
                                                )
                                            }
                                            
                                            Task {
                                                await bluetoothManager.refreshAll()
                                            }
                                            
                                            if (!stReports.isEmpty || !ftReports.isEmpty || !etReports.isEmpty || !btReports.isEmpty) {
                                                store.send(.getDashboardCount)
                                                onLogic = true
                                                bluetoothManager.dashboardTrigger(
                                                    who: store.who,
                                                    dashboardTime: store.startTime,
                                                    reportSTs: stReports,
                                                    reportFTs: ftReports,
                                                    reportETs: etReports,
                                                    reportBTs: btReports,
                                                    callBack: { dashboard in
                                                        DispatchQueue.main.async{
                                                            onLogic = false
                                                            if onBoard {
                                                                onBoard = false
                                                                store.send(.delegate(.goToRecentLog))
                                                            }
                                                        }
                                                    },
                                                    onFailure: {
                                                        onLogic = false
                                                        onBoard = false
                                                    }
                                                )
                                                store.send(.toggleEndFullScreenShown)
                                            }
                                            else{
                                                store.send(.delegate(.goToHome))
                                            }
                                        }
                                    )
                                }
                                .padding(20)
                                .presentationDetents([.height(245)])
                                .presentationCornerRadius(20)
                                .fullScreenCover(isPresented: $store.endFullScreenShown, content: {
                                    WithPerceptionTracking {
                                        VStack(spacing: 0){
                                            HStack{
                                                Button(action: {
                                                    store.send(.delegate(.goToHome))
                                                }, label: {
                                                    Image(systemName: "xmark")
                                                        .resizable()
                                                        .frame(width: 20, height: 20)
                                                })
                                                Spacer()
                                            }
                                            
                                            Spacer()
                                            Text("축하합니다")
                                                .font(.s_20())
                                                .foregroundStyle(.lightBlack)
                                            Spacer().frame(height: 14)
                                            Text("\((store.dashboardCount ?? 0) + 1)번째 측정을 완료했어요")
                                                .font(.s_20())
                                                .foregroundStyle(.lightBlack)
                                            Spacer().frame(height: 80)
                                            Image(systemName: "checkmark.circle.fill")
                                                .resizable()
                                                .frame(width: 80, height: 80)
                                                .foregroundColor(.mainBlue)
                                            Spacer()
                                            
                                            okButton(name: "운동 리포트 다시보기", action: {
                                                print("onLogic = \(onLogic)")
                                                if onLogic{
                                                    onBoard = true
                                                }
                                                else{
                                                    store.send(.delegate(.goToRecentLog))
                                                }
                                            })
                                        }
                                        .padding(20)
                                    }
                                })
                            }
                        })
                        if onBoard {
                            ZStack{
                                Color.black.opacity(0.7)
                                    .background(BlackTransparentBackground())
                                    .ignoresSafeArea(.all)
                                VStack(spacing: 20) {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            } // Geometry
        }
    }
    
    @ViewBuilder
    private func testListView() -> some View {
        ScrollView{
            VStack(spacing: 25) {
                Spacer().frame(height: 15)
                
                ForEach(store.reportOrderList.indices, id: \.self){ i in
                    let reportType = store.reportOrderList[i]
                    let exercise: ExerciseDTO? = reportType.testType == .EXER ? ExerciseRepository.shared.getExercisesById(exerciseId: reportType.exid) : nil
                    var reports: [(any Report)?]? {
                        switch reportType.testType {
                        case .SPINE:
                            return store.stReports
                        case .FUNC:
                            return store.ftReports
                        case .EXER:
                            return store.etReports.first(where: {$0.exerciseId == reportType.exid})?.reportSets
                        case .BRIEF:
                            return store.btReports.first(where: {$0.name == reportType.name})?.reportSets
                        }
                    }
                    
                    if reports != nil {
                        testCard(
                            reportType: reportType,
                            reports: reports!
                        )
                        .padding(.horizontal, 25)
                    }
                }
                

                
            }
            
        }
        .background(.backgroundGray)
        .fullScreenCover(item: $store.scope(state: \.destination?.stReport, action: \.destination.stReport)) { store in
            WithPerceptionTracking {
                NavigationStack {
                    StReportView(store: store, swipeBack: false)
                }
            }
        }
        .fullScreenCover(item: $store.scope(state: \.destination?.ftReport, action: \.destination.ftReport)) { store in
            WithPerceptionTracking {
                NavigationStack {
                    FtReportView(store: store, swipeBack: false)
                }
            }
        }
        .fullScreenCover(item: $store.scope(state: \.destination?.etReport, action: \.destination.etReport)) { store in
            WithPerceptionTracking {
                NavigationStack {
                    EtReportView(store: store, swipeBack: false)
                }
            }
        }
        .fullScreenCover(item: $store.scope(state: \.destination?.btReport, action: \.destination.btReport)) { store in
            WithPerceptionTracking {
                NavigationStack {
                    BtReportView(store: store, swipeBack: false)
                }
            }
        }
    }
    
    @ViewBuilder
    private func testCard(
        reportType: ReportType,
        reports: [(any Report)?]
    ) -> some View {
        VStack(spacing: 0){
            HStack(spacing: 0){
                Image("exercise_picture")
                    .resizable()
                    .frame(width: 40, height: 40)
                Spacer().frame(width: 20)
                VStack(alignment: .leading, spacing: 10){
                    if reportType.testType == .BRIEF {
                        let name = store.btReports.count == 1 ? TestType.BRIEF.rawValue : reportType.name
                        Text(name)
                            .font(.m_16())
                            Button(action: {
                                store.send(.showBtMuscleName(reportType))
                            }, label: {
                                Text("부착 부위명 보기")
                                    .font(.r_12())
                                    .foregroundStyle(.lightGraySet)
                                    .underline(true, color: .lightGraySet)
                            })
                    }
                    else {
                        Text(reportType.name)
                            .font(.m_16())
                    }
                }
                Spacer()
                
                HStack(alignment: .center){
                    
                    Button(action: {
                        store.send(.remove(reportType))
                    }, label: {
                        HStack{
                            Spacer()
                            Image(systemName: "minus")
                                .frame(width: 18, height: 18)
                                .foregroundStyle(reports.filter({ $0 == nil }).isEmpty ? .lightGraySet : .lightBlack)
                            Spacer()
                        }
                    })
                    .disabled(reports.filter({ $0 == nil }).isEmpty)
                    
                    Rectangle()
                        .frame(width: 1, height: 18)
                        .foregroundStyle(.mediumGray)
                    
                    Button(action: {
                        store.send(.add(reportType))
                    }, label: {
                        HStack{
                            Spacer()
                            Image(systemName: "plus")
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.lightBlack)
                            Spacer()
                        }
                    })
                }
                .frame(width: 94, height: 32)
                .background(.whiteGray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.vertical, 25)
            .padding(.horizontal, 30)
            
            Divider()
            
            VStack(spacing: 25){
                ForEach(0..<reports.count, id: \.self){ i in
                    HStack(spacing: 0){
                        VStack(alignment: .leading, spacing: 10){
                            Text("\(i+1) 세트")
                                .font(.m_14())
                                .foregroundStyle(.lightBlack)
                        }
                        Spacer()
                        
                        if (i > 0 && reports[i-1] != nil) || i == 0 {
                            Button(action: {
                                if let report = reports[i]{
                                    switch reportType.testType {
                                    case .SPINE:
                                        store.send(.goToStReport(report as! ReportST))
                                    case .FUNC:
                                        store.send(.goToFtReport(report as! ReportFTDTO))
                                    case .EXER:
                                        store.send(.goToEtReport(report as! ReportETSetDTO))
                                    case .BRIEF:
                                        store.send(.goToBtReport(report as! ReportBTSetDTO))
                                    }
                                }
                                else {
                                    if reportType.testType == .SPINE || (reportType.testType == .BRIEF && !(reportType.testType == store.lastTestAttach?.testType && reportType.name == store.lastTestAttach?.name)) {
                                        Task {
                                            await bluetoothManager.refreshAll()
                                        }
                                    }
                                    store.send(.startTest(reportType ,bluetoothManager.bluetoothIsReady, bluetoothManager.clips.isEmpty))
                                }
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text(reports[i] != nil ? "분석 결과" : "측정하기")
                                        .font(.r_14())
                                        .foregroundStyle(reports[i] != nil ? .darkGraySet : .white)
                                    Spacer()
                                }
                            })
                            .frame(width: 106, height: 36)
                            .background(reports[i] != nil ? .white : .mainBlue)
                            .cornerRadius(5)
                            .overlay{
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.whiteGray, lineWidth: reports[i] != nil ? 1 : 0)
                            }
                        }
                        else{
                            Spacer().frame(height: 36)
                        }
                    }
                }
            }
            .padding(.leading, 35)
            .padding(.trailing, 20)
            .padding(.vertical, 20)
            
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow2()
    }
}

