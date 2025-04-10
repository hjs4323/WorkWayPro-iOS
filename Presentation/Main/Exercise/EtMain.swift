//
//  ExerciseMain.swift
//  WorkwayVer2
//
//  Created by loyH on 8/14/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct EtMain{
    @Reducer(state: .equatable)
    enum Destination {
        case weightCount(EtWeightCount)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        var endBottomSheetShown: Bool = false
        
        var who: String
        var time: Int?
        var report: ReportETDTO
        var rawDatas: [[Float]]?
        var exercise: ExerciseDTO?
        let setIndex: Int
        
        var retryCount: Int = 0
        
        init(who: String, report: ReportETDTO, exercise: ExerciseDTO? = nil) {
            self.who = who
            self.report = report
            self.exercise = exercise
            self.setIndex = report.reportSets?.filter({$0 != nil}).count ?? 0
            self.retryCount = 0
        }
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        
        case setTime
        case add1RetryCount
        case setReport(ReportETSetDTO)
        case setRawDatas([[Float]])
        
        case initReportET
        case setReportId(String)
        case goToWeightCount
        case destination(PresentationAction<Destination.Action>)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case setReportId(String)
            case goToMainList(ReportETSetDTO?)
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
                
            case let .setReport(etSet):
                if let index = state.report.reportSets?.firstIndex(where: { $0 == nil }) {
                    state.report.reportSets![index] = etSet
                }
                return .none
                
            case let .setRawDatas(rawDatas):
                state.rawDatas = rawDatas
                return .none
                
            case .initReportET:
                return .run { [report = state.report] send in
                    do {
                        let reportId = try await reportRepository.initReportET(reportET: report)
                        await send(.setReportId(reportId))
                    } catch {
                        print("ETMain/initReportET: error \(error)")
                    }
                }
                
            case let .setReportId(reportId):
                state.report.reportId = reportId
                return .send(.delegate(.setReportId(reportId)))
                
            case .goToWeightCount:
                
                if let rawDatas = state.rawDatas{
                    state.destination = .weightCount(.init(
                        who: state.who,
                        report: state.report,
                        rawDatas: rawDatas,
                        exercise: state.exercise,
                        setIndex: state.setIndex
                    ))
                }
                return .none
                
            case let .destination(.presented(.weightCount(.delegate(delegateAction)))):
                switch delegateAction{
                case let .goToMainList(et):
                    return .send(.delegate(.goToMainList(et)))
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


struct EtMainView: View {
    @Perception.Bindable var store: StoreOf<EtMain>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    @State var mode: Mode = .ready
    @State var onBoard: Bool = false
    @State var onLogic: Bool = false
    
    enum Mode{
        case ready
        case start
        case done
        case error
    }
    
    var body: some View {
        WithPerceptionTracking{
            GeometryReader{ geometry in
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
                .basicToolbar(
                    title: "운동 평가",
                    swipeBack: mode == .ready,
                    closeButtonAction: {
                        store.send(.toggleEndBottomSheetShown)
                    }
                )
                .onAppear(perform: {
                    if store.setIndex == 0 && store.report.reportId == "" {
                        store.send(.initReportET)
                    }
                })
                .navigationDestination(item: $store.scope(state: \.destination?.weightCount, action: \.destination.weightCount)) { store in
                    EtWeightCountView(store: store)
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
                
                VStack(spacing: 13){
                    HStack(spacing: 0){
                        Text("최대 수축 지점")
                            .font(.s_20())
                            .foregroundStyle(.mainBlue)
                        Text("에서")
                            .font(.s_20())
                            .foregroundStyle(.lightBlack)
                    }
                    Text("측정을 시작해주세요")
                        .font(.s_20())
                        .foregroundStyle(.lightBlack)
                }
                
                
                Spacer()
                
                HStack(spacing: 20) {
                    Image("exercise_picture")
                        .resizable()
                        .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.exercise?.name ?? "오류")
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
                name: "1세트 시작하기", 
                action: {
                    store.send(.setTime)
                    withAnimation(.easeInOut(duration: 0.2)){
                        mode = .start
                    }
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
                Spacer().frame(height: 40)
                
                ProgressView()
                    .tint(.mainBlue)
                    .controlSize(.large)
                    .frame(width: 80, height: 80)
                Spacer().frame(height: 44)
                Text("측정 중")
                    .font(.s_20())
                    .foregroundStyle(.lightBlack)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Image("exercise_picture")
                        .resizable()
                        .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.exercise?.name ?? "오류")
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
            
            twoButton(
                geometry: geometry,
                leftName: "다시하기",
                leftAction: {
                    Task{
                        await bluetoothManager.stopMeasurement(restart: true, callBack: {}, onFailure: {})
                    }
                    withAnimation{
                        mode = .ready
                    }
                },
                rightName: "\(store.setIndex + 1)세트 완료",
                rightAction: {
                    Task{
                        if !onLogic {
                            onLogic = true
                            await bluetoothManager.etDataLogicTrigger(
                                reportET: store.report,
                                time: store.time!,
                                retryCount: store.retryCount,
                                callBack: { report, rawDatas in
                                    DispatchQueue.main.async{
                                        store.send(.setReport(report))
                                        store.send(.setRawDatas(rawDatas))
                                        onLogic = false
                                        if onBoard {
                                            onBoard = false
                                            store.send(.goToWeightCount)
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
        .padding(20)
        .onAppear{
            bluetoothManager.startMeasurement(exercise: nil, weight: nil)
        }
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
                },
                rightName: "리포트 보기",
                rightAction: {
                    if onLogic{
                        onBoard = true
                    }
                    else{
                        store.send(.goToWeightCount)
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
