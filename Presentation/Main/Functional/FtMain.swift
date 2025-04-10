//
//  FtMain.swift
//  WorkwayVer2
//
//  Created by loyH on 7/24/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


@Reducer
struct FtMain{
    @Reducer(state: .equatable)
    enum Destination {
        case ftReport(FtReport)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        var endBottomSheetShown: Bool = false
        
        var who: String
        
        var time: Int?
        let dashboardTime: Int
        var report: ReportFTDTO?
        var rawDatas: [[Float]]?
        
        let setIndex: Int
        
        var retryCount: Int = 0
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        
        case setTime
        case add1RetryCount
        case setReport(ReportFTDTO)
        case setRawDatas([[Float]])
        
        case goToReport
        case destination(PresentationAction<Destination.Action>)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case goToMainList(ReportFTDTO?)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
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
                
            case let .setReport(report):
                state.report = report
                return .none
                
            case let .setRawDatas(rawDatas):
                state.rawDatas = rawDatas
                return .none
                
            case .goToReport:
                if let report = state.report, let rawDatas = state.rawDatas{
                    state.destination = .ftReport(.init(setIndex: 0, reports: [report], rawDatas: rawDatas, isFromLog: false))
                }
                return .none
                
            case let .destination(.presented(.ftReport(.delegate(delegateAction)))):
                switch delegateAction{
                case let .goToMainList(ft):
                    return .send(.delegate(.goToMainList(ft)))
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



struct FtMainView: View {
    @Perception.Bindable var store: StoreOf<FtMain>
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
                    title: "기능 평가",
                    swipeBack: mode == .ready,
                    closeButtonAction: {
                        store.send(.toggleEndBottomSheetShown)
                    }
                )
                .navigationDestination(item: $store.scope(state: \.destination?.ftReport, action: \.destination.ftReport)) { store in
                    FtReportView(store: store, swipeBack: false)
                }
                .sheet(isPresented: $store.endBottomSheetShown, content: {
                    MainEndBottomSheet(
                        testType: .FUNC,
                        cancel: {
                            store.send(.toggleEndBottomSheetShown)
                        },
                        end: {
                            Task {
                                if bluetoothManager.isReceivingData {
                                    await bluetoothManager.stopMeasurement(restart: true, callBack: {}, onFailure: {})
                                }
                            }
                            store.send(.delegate(.goToMainList(store.report)))
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
            VStack(alignment: .leading, spacing: 0){
                Spacer()
                Text("측정을 시작합니다")
                    .font(.s_20())
                    .foregroundStyle(.lightBlack)
                Spacer().frame(height: 13)
                Text("아래의 순서대로 동작을 측정해주세요")
                    .font(.m_16())
                    .foregroundStyle(.lightGraySet)
                Spacer()
                functionalOrder()
                Spacer()
                
                HStack(spacing: 20) {
                    Image("exercise_picture")
                        .resizable()
                        .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("오버헤드 스쿼트")
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
                        Text("오버헤드 스쿼트")
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
                    Task(priority: .userInitiated){
                        await bluetoothManager.stopMeasurement(restart: true, callBack: {}, onFailure: {})
                    }
                    withAnimation{
                        mode = .ready
                    }
                },
                rightName: "1세트 완료",
                rightAction: {
                    if !onLogic {
                        Task{
                            onLogic = true
                            await bluetoothManager.ftDataLogicTrigger(
                                who: store.who,
                                time: store.time!,
                                dashboardTime: store.dashboardTime,
                                retryCount: store.retryCount,
                                callBack: { report, rawDatas in
                                    DispatchQueue.main.async{
                                        store.send(.setReport(report))
                                        store.send(.setRawDatas(rawDatas))
                                        onLogic = false
                                        if onBoard {
                                            onBoard = false
                                            store.send(.goToReport)
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
                        store.send(.goToReport)
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
    
    @ViewBuilder
    private func functionalOrder() -> some View{
        let actions = ["차렷 자세", "양쪽 팔 들기", "스쿼트", "양쪽 팔 내리기", "차렷 자세"]
        GeometryReader{ geometry in
            Path{ path in
                path.move(to: CGPoint(x: 49, y: 0))
                path.addLine(to: CGPoint(x: 49, y: geometry.size.height))
            }
            .stroke(.whiteLightGray)
            .overlay{
                VStack(spacing: 22){
                    ForEach(Range(0...4)){ index in
                        HStack(alignment: .center, spacing: 0){
                            Circle()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.mainBlue)
                            Spacer().frame(width: 29)
                            Text(actions[index])
                                .font(.m_14())
                                .foregroundColor(.lightBlack)
                            Spacer()
                        }
                    }
                }
                .padding(40)
            }
        }.frame(height: 178)
    }
}
