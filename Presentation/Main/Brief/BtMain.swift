//
//  BtMain.swift
//  WorkwayVer2
//
//  Created by loyH on 9/13/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Combine

@Reducer
struct BtMain{
    @Reducer(state: .equatable)
    enum Destination {
        case weightCount(BtWeightCount)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        var endBottomSheetShown: Bool = false
        
        let who: String
        var time: Int?
        let dashboardTime: Int
        var selectedBTName: String
        var selectedReport: ReportBTDTO {
            self.todayReports.first(where: { $0.name == selectedBTName })!
        }
        let setIndex: Int
        
        var retryCount: Int = 0
        
        var todayReports: [ReportBTDTO]
        var reportBTsNotToday: [ReportBTDTO]?
        
        let movePrevAvailable: Bool
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        
        case setTime
        case add1RetryCount
        case initReportBT
        case setReportId(String)
        case setReport(ReportBTSetDTO)
        
        case goToWeightCount
        case destination(PresentationAction<Destination.Action>)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case setReport(ReportBTDTO)
            case goToMainList(ReportBTDTO?)
            case setReportBTsNotToday([ReportBTDTO])
        }
    }
    
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
                
            case .setTime:
                state.time = Int(Date().timeIntervalSince1970)
                return .none
                
            case .add1RetryCount:
                state.retryCount += 1
                return .none
                
            case .initReportBT:
                return .run { [report = state.selectedReport] send in
                    do {
                        let reportId = try await reportRepository.initReportBT(reportBT: report)
                        await send(.setReportId(reportId))
                    } catch {
                        print("ETMain/initReportET: error \(error)")
                    }
                }
                
            case let .setReportId(reportId):
                if let selectedIndex = state.todayReports.firstIndex(where: { $0.name == state.selectedBTName }) {
                    state.todayReports[selectedIndex].reportId = reportId
                    return .send(.delegate(.setReport(state.todayReports[selectedIndex])))
                }
                return .none
                
            case let .setReport(btSet):
                if let selectedIndex = state.todayReports.firstIndex(where: { $0.name == state.selectedBTName }) {
                    state.todayReports[selectedIndex].addReportSet(rSet: btSet)
                    return .send(.delegate(.setReport(state.todayReports[selectedIndex])))
                }
                return .none
                
            case .goToWeightCount:
                state.destination = .weightCount(.init(
                    who: state.who,
                    reportBTs: state.todayReports,
                    reportBTsNotToday: state.reportBTsNotToday,
                    selectedBTName: state.selectedBTName,
                    setIndex: state.setIndex
                ))
                return .none
                
            case let .destination(.presented(.weightCount(.delegate(delegateAction)))):
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

struct BtMainView: View {
    @Perception.Bindable var store: StoreOf<BtMain>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    @State var mode: Mode = .ready
    @State var onBoard: Bool = false
    @State var onLogic: Bool = false
    
    @State private var cancellable: AnyCancellable?
    @State var chartArray: [[Int]] = Array(repeating: [], count: 8)
    
    enum Mode{
        case ready
        case start
        case done
        case error
    }
    
    var body: some View {
        WithPerceptionTracking{
            GeometryReader{ geometry in
                WithPerceptionTracking {
                    VStack(alignment: .center, spacing: 0){
                        switch mode {
                        case .ready:
                            readyView(geometry: geometry)
                        case .start:
                            startView(geometry: geometry)
                        case .done:
                            doneView(geometry: geometry)
                        case .error:
                            errorView(geometry: geometry)
                        }
                    }
                    .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                    .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
                    .if(AppDelegate.orientationLock == .portrait) { view in
                        view.basicToolbar(
                            title: "운동 평가",
                            swipeBack: mode == .ready && store.movePrevAvailable,
                            closeButtonAction: {
                                store.send(.toggleEndBottomSheetShown)
                            }
                        )
                    }
                    .if(AppDelegate.orientationLock == .landscapeRight) { view in
                        view.navigationBarBackButtonHidden(true)
                    }
                    .onAppear(perform: {
                        if store.setIndex == 0 && store.selectedReport.reportId == "" {
                            store.send(.initReportBT)
                        }
                    })
                    .navigationDestination(item: $store.scope(state: \.destination?.weightCount, action: \.destination.weightCount)) { store in
                        BtWeightCountView(store: store)
                    }
                    .sheet(isPresented: $store.endBottomSheetShown, content: {
                        MainEndBottomSheet(
                            testType: .EXER,
                            cancel: {
                                store.send(.toggleEndBottomSheetShown)
                            },
                            end: {
                                Task {
                                    if bluetoothManager.isReceivingData {
                                        await bluetoothManager.stopMeasurement(restart: true, callBack: {}, onFailure: {})
                                    }
                                }
                                store.send(.delegate(.goToMainList(nil)))
                            })
                        .presentationDetents([.height(230)])
                    })
                    if onBoard{
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
        }
    }
    
    @ViewBuilder
    private func readyView(geometry: GeometryProxy) -> some View{
        VStack(alignment: .center, spacing: 0){
            VStack(alignment: .center, spacing: 0){
                Spacer()
                Spacer().frame(height: 40)
                
                
                Image("sonometer")
                    .resizable()
                    .frame(width: 100, height: 100)
                Spacer().frame(height: 50)
                
                Text("측정을 시작해주세요")
                    .font(.s_20())
                    .foregroundStyle(.lightBlack)
                
                
                Spacer()
                
                HStack(spacing: 20) {
                    Image("exercise_picture")
                        .resizable()
                        .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("자율 측정")
                            .font(.m_16())
                            .foregroundStyle(.lightBlack)
                        Text("\(store.setIndex + 1) 세트")
                            .font(.r_14())
                            .foregroundStyle(.darkGraySet)
                    }
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 30)
                .padding(.vertical, 16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow2()
                
                Spacer().frame(height: 40)
            }
            .padding(10)
            
            okButton(
                name: "\(store.setIndex + 1)세트 시작하기",
                action: {
                    store.send(.setTime)
                    withAnimation(.easeInOut(duration: 0.2)){
                        mode = .start
                    }
                    bluetoothManager.startMeasurement(exercise: nil, weight: nil)
                }
            )
            
        }
        .padding(20)
        
    }
    
    @ViewBuilder
    private func startView(geometry: GeometryProxy) -> some View{
        VStack(alignment: .center, spacing: 0){
            
            VStack(alignment: .center, spacing: 0){
                Spacer()
                let rawDatasAll = bluetoothManager.clips.map{chartArray[$0.hubIndex].map({ Float($0) })}
                
                let minData = 0
                let maxData = min(10000, max(4150, bluetoothManager.averageArray.flatMap({ $0 }).max() ?? 0 ))
                
                let colors: [Color] = [.workwayBlue, .red, .green, .purple, .brown, .orange, .whiteLightGray, .black]
                var labels: [String] {
                    var label: [String] = []
                    for name in store.selectedReport.muscleName {
                        if let range = name.range(of: "번 근육") {
                                let number = String(name[..<range.lowerBound])
                                label.append("\(number)번")
                            } else {
                                label.append(name)
                            }
                    }
                    return label
                }
                
                
                VStack(alignment: .trailing ,spacing: 0){
                    Spacer().frame(height: 20)
                    
                    if AppDelegate.orientationLock == .portrait {
                        Image(systemName: "viewfinder")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .onTapGesture {
                                if AppDelegate.orientationLock == .landscapeRight {
                                    AppDelegate.orientationLock = .portrait
                                } else {
                                    AppDelegate.orientationLock = .landscapeRight
                                }
                            }
                            .padding(.horizontal, 20)
                    }
                    else {
                        HStack{
                            Spacer()
                            ForEach(0..<labels.count){ i in
                                Rectangle()
                                    .frame(width: 17, height: 1)
                                    .foregroundColor(colors[i])
                                Spacer().frame(width: 8 )
                                Text(labels[i])
                                    .font(.m_14())
                                    .foregroundColor(.lightGraySet)
                                    .lineLimit(1)
                                
                                if i != labels.count - 1 {
                                    Spacer().frame(width: 14 )
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    Spacer().frame(height: 13)
                    
                    ZStack(alignment: .leading){
                        VStack(spacing: 0){
                            HStack(spacing: 9){
                                Rectangle()
                                    .frame(width: 1, height: 220)
                                    .foregroundColor(.whiteLightGray)
                                VStack(alignment: .leading){
                                    Text("\(Int(ceil(valueToqV(Float(maxData)))))")
                                        .font(.r_10())
                                        .foregroundColor(.whiteLightGray)
                                        .offset(y: -8)
                                    Spacer()
                                    Text("\(Int(minData))")
                                        .font(.r_10())
                                        .foregroundColor(.whiteLightGray)
                                        .offset(y: 8)
                                }
                            }
                            .frame(height: 220)
                        }
                        RawDataGraph(
                            names: store.selectedReport.muscleName,
                            rawDatas: rawDatasAll,
                            colors: colors,
                            minData: Float(minData),
                            maxData: Float(maxData)
                        )
                        .frame(width: geometry.size.width - (AppDelegate.orientationLock == .landscapeRight ? 0 : 63), height: 220)
                        .onAppear {
                            if cancellable == nil {
                                print("onAppear to sink chartArray, chartARray = \(chartArray.map({ $0.count }))")
                                cancellable = Timer.publish(every: 0.05, on: .main, in: .common)
                                    .autoconnect()
                                    .sink(receiveValue: { _ in
                                        chartArray = bluetoothManager.averageArray.map({ $0.takeLast(600).map({ min($0, 10000) }) })
                                    })
                            }
                        }
                    }
                    
                    if AppDelegate.orientationLock == .portrait {
                        VStack(alignment: .center, spacing: 0){
                            let multiRowIndex: Int = labels.count <= 4 ? labels.count : labels.count / 2
                            HStack{
                                Spacer()
                                ForEach(0..<multiRowIndex, id: \.self){ i in
                                    HStack(spacing: 0){
                                        Rectangle()
                                            .frame(width: 17, height: 1)
                                            .foregroundColor(colors[i])
                                        Spacer().frame(width: 8 )
                                        Text(labels[i])
                                            .font(.m_14())
                                            .foregroundColor(.lightGraySet)
                                            .lineLimit(1)
                                    }
                                    
                                    if i != multiRowIndex - 1 {
                                        Spacer().frame(width: 14 )
                                    }
                                }
                                Spacer()
                            }
                            
                            if multiRowIndex != labels.count {
                                HStack{
                                    Spacer()
                                    ForEach(multiRowIndex..<labels.count, id: \.self){ i in
                                        Rectangle()
                                            .frame(width: 17, height: 1)
                                            .foregroundColor(colors[i])
                                        Spacer().frame(width: 8 )
                                        Text(labels[i])
                                            .font(.m_14())
                                            .foregroundColor(.lightGraySet)
                                            .lineLimit(1)
                                        
                                        if i != labels.count - 1 {
                                            Spacer().frame(width: 14 )
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 25)
                    }
                    else {
                        Image("normal_screen")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.lightBlack)
                            .onTapGesture {
                                if AppDelegate.orientationLock == .landscapeRight {
                                    AppDelegate.orientationLock = .portrait
                                } else {
                                    AppDelegate.orientationLock = .landscapeRight
                                }
                            }
                            .padding(.vertical, 16)
                    }
                }
                .background(.background)
                .if(AppDelegate.orientationLock == .portrait) { view in
                    view
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow2()
                        .padding(.horizontal, 5)
                }
                .if(AppDelegate.orientationLock == .landscapeRight) { view in
                    view.frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                
                Spacer()
                
                HStack(spacing: 20) {
                    Image("exercise_picture")
                        .resizable()
                        .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("자율 측정")
                            .font(.m_16())
                            .foregroundStyle(.lightBlack)
                        Text("\(store.setIndex + 1) 세트")
                            .font(.r_14())
                            .foregroundStyle(.darkGraySet)
                    }
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 30)
                .padding(.vertical, 16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow2()
                
                Spacer().frame(height: 40)
            }
            .padding(AppDelegate.orientationLock == .portrait ? 10 : 0)
            
            twoButton(
                geometry: geometry,
                leftName: "다시하기",
                leftAction: {
                    cancellable?.cancel()
                    cancellable = nil
                    Task{
                        await bluetoothManager.stopMeasurement(restart: true, callBack: {}, onFailure: {})
                    }
                    withAnimation{
                        mode = .ready
                    }
                },
                rightName: "\(store.setIndex + 1)세트 완료",
                rightAction: {
                    cancellable?.cancel()
                    cancellable = nil
                    Task {
                        if !onLogic {
                            onLogic = true
                            await bluetoothManager.btDataLogicTrigger(
                                reportBT: store.selectedReport,
                                time: store.time!,
                                retryCount: store.retryCount,
                                callBack: { report in
                                    DispatchQueue.main.async{
                                        store.send(.setReport(report))
                                        onLogic = false
                                        if onBoard {
                                            onBoard = false
                                            store.send(.goToWeightCount)
                                            mode = .ready
                                        }
                                    }
                                },
                                onFailure: { retry in
                                    if retry == store.retryCount {
                                        mode = .error
                                    }
                                    onLogic = false
                                    onBoard = false
                                }
                            )
                        }
                    }
                    withAnimation{
                        mode = .done
                    }
                }
            )
        }
        .padding(AppDelegate.orientationLock == .portrait ? 20 : 0)
    }
    
    @ViewBuilder
    private func doneView(geometry: GeometryProxy) -> some View{
        VStack(spacing: 0){
            Spacer()
            HStack{
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.mainBlue)
                Spacer()
            }
            Spacer().frame(height: 50)
            Text("측정을 완료했어요")
                .font(.s_20())
                .foregroundColor(.lightBlack)
            Spacer()
            
            twoButton(
                geometry: geometry,
                leftName: "다시하기",
                leftAction: {
                    store.send(.add1RetryCount)
                    Task{
                        await bluetoothManager.stopMeasurement(restart: false, callBack: {}, onFailure: {})
                    }
                    
                    withAnimation{
                        mode = .ready
                    }
                    onLogic = false
                    onBoard = false
                },
                rightName: "리포트 보기",
                rightAction: {
                    if onLogic{
                        onBoard = true
                    }
                    else{
                        store.send(.goToWeightCount)
                        mode = .ready
                    }
                }
            )
        }
        .padding(20)
    }
    
    
    @ViewBuilder
    private func errorView(geometry: GeometryProxy) -> some View{
        VStack(spacing: 0){
            Spacer()
            HStack{
                Spacer()
                Image("error")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.mainBlue)
                Spacer()
            }
            Spacer().frame(height: 50)
            Text("에러가 발생했어요")
                .font(.s_20())
                .foregroundColor(.lightBlack)
            Spacer()
            
            okButton(
                name: "다시하기",
                action: {
                    store.send(.delegate(.goToMainList(nil)))
                }
            )
            
        }
        .padding(20)
    }
}
