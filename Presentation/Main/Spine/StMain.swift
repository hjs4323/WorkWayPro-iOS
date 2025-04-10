//
//  StaticMain.swift
//  WorkwayVer2
//
//  Created by loyH on 7/12/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import CoreBluetooth

@Reducer
struct StMain{
    @Reducer(state: .equatable)
    enum Destination {
        case stReport(StReport)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        var endBottomSheetShown: Bool = false
        
        var who: String
        var time: Int?
        let dashboardTime: Int
        
        var values: [[Float]] = []
        var report: ReportST?
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
        
        case setTime
        case setValue([Float])
        case resetValue
        case setReport(ReportST)
        
        
        case goToReport
        case destination(PresentationAction<Destination.Action>)
        
        case delegate(Delegate)
        enum Delegate: Equatable {
            case goToMainList(ReportST?)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
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
                
            case let .setValue(value):
                state.values.append(value)
                return .none
                
            case .resetValue:
                state.values = []
                return .none
                
            case let .setReport(report):
                state.report = report
                return .none
                
            case .goToReport:
                if let report = state.report {
                    state.destination = .stReport(.init(report: report))
                }
                return .none
                
            case let .destination(.presented(.stReport(.delegate(delegateAction)))):
                switch delegateAction{
                case let .goToMainList(st):
                    return .send(.delegate(.goToMainList(st)))
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

struct StMainView: View {
    @Perception.Bindable var store: StoreOf<StMain>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    enum Mode{
        case ready
        case start
        case done
        case error
    }
    
    @State var mode: Mode = .ready
    
    @State var order: Int = 0
    @State var percent: Float = 0.0
    
    @State var isPrepare: Bool = true
    @State var isPlaying: Bool = true
    @State var task: Task<Void, Never>? = nil
    
    @State var colors: [[Color]] = Array(repeating: [.whiteGray, .whiteGray], count: 5)
    
    @State var onBoard: Bool = false
    @State var onLogic: Bool = false
    
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
                    title: "척추근 평가",
                    swipeBack: mode == .ready,
                    closeButtonAction: {
                        store.send(.toggleEndBottomSheetShown)
                    }
                )
                .navigationDestination(item: $store.scope(state: \.destination?.stReport, action: \.destination.stReport)) { store in
                    StReportView(store: store, swipeBack: false)
                }
                .sheet(isPresented: $store.endBottomSheetShown, content: {
                    MainEndBottomSheet(
                        testType: .SPINE,
                        cancel: {
                            store.send(.toggleEndBottomSheetShown)
                        },
                        end: {
                            Task {
                                if bluetoothManager.isReceivingData {
                                    await bluetoothManager.stopMeasurement(restart: true, callBack: {}, onFailure: {})
                                }
                                await bluetoothManager.refreshAll()
                            }
                            store.send(.delegate(.goToMainList(store.report)))
                        })
                    .presentationDetents([.height(230)])
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
    }
    
    @ViewBuilder
    private func readyView(geometry: GeometryProxy) -> some View{
        VStack(alignment: .center, spacing: 0){
            Spacer().frame(height: geometry.size.height * 90 / 830)
            MuscleBarGraph(colors: colors)
                .aspectRatio(136/132, contentMode: .fit)
                .frame(width: geometry.size.width * 136 / 393)
            Spacer().frame(height: 40)
            
            Text("아래의 순서에 따라")
                .font(.s_20())
                .foregroundColor(.lightBlack)
            Spacer().frame(height: 13)
            Text("측정을 진행해주세요")
                .font(.s_20())
                .foregroundColor(.lightBlack)
            Spacer().frame(height: 70)
            
            spineOrder()
            
            Spacer()
            
            okButton(
                name: "측정 시작하기",
                action: {
                    store.send(.setTime)
                    withAnimation(.easeInOut(duration: 0.2)){
                        mode = .start
                        
                    }})
        }
        .padding(20)
    }
    
    
    @ViewBuilder
    private func startView(geometry: GeometryProxy) -> some View{
        VStack(alignment: .center, spacing: 0){
            Spacer().frame(height: geometry.size.height * 65 / 830)
            Text("아래 부위에 클립을")
                .font(.s_20())
                .foregroundColor(.lightBlack)
            Spacer().frame(height: 18)
            HStack(spacing: 7){
                Text("10초")
                    .font(.s_30())
                    .foregroundColor(.mainBlue)
                Text("이상")
                    .font(.s_20())
                    .foregroundColor(.lightBlack)
            }
            Spacer().frame(height: 18)
            Text("접촉해주세요")
                .font(.s_20())
                .foregroundColor(.lightBlack)
            
            Spacer().frame(height: 40)
            
            MuscleBarGraph(barSizes: Array(repeating: [0.35, 0.35], count: 5), colors: Array(colors))
                .aspectRatio(136/132, contentMode: .fit)
                .frame(width: geometry.size.width * 136 / 393)
            Spacer().frame(height: 50)
            
            spineOrder(order: order)
                .padding([.leading, .trailing], 20)
            Spacer()
            
            
            if isPlaying {
                ProgressView(value: percent)
                    .progressViewStyle(BarProgressStyle(color: isPrepare ? .darkGraySet : .mainBlue, height: 8))
                    .background(.whiteGray)
                    .frame(height: 8)
                    .onChange(of: percent){ newValue in
                        if newValue == 1.0 {
                            if !(order == 5) {
                                task = Task {
                                    await handlePercentChange()
                                }
                            }
                            else{
                                withAnimation{
                                    mode = .done
                                }
                            }
                        }
                        
                    }
                    .onAppear {
                        task = Task {
                            await handlePercentChange()
                        }
                    }
            
                HStack{
                    Text(isPrepare ? "준비" : "측정")
                        .font(.s_16())
                        .foregroundColor(.lightBlack)
                    Spacer()
                    Text("\(10 - Int(percent * 10))")
                        .font(.s_30())
                        .foregroundColor(.lightBlack)
                        .animation(nil)
                    
                    Spacer()
                    Spacer().frame(width: 4)
                    
                    Button(action: {
                        isPlaying.toggle()
                        task?.cancel()
                        percent = 0
                        isPrepare = true
                        Task{
                            await bluetoothManager.stopMeasurement(restart: true, callBack: {}, onFailure: {})
                        }
                    }, label: {
                        Image(systemName: isPlaying ? "pause.fill" : "arrow.clockwise")
                            .frame(width: 24, height: 24)
                    })
                }
                .padding([.leading, .trailing], 30)
                .frame(height: 55)
            } else {
                twoButton(
                    geometry: geometry,
                    leftName: "전체 재측정",
                    leftAction: {
                        order = 0
                        isPlaying.toggle()
                        store.send(.resetValue)
                        mode = .ready
                    },
                    rightName: "현재 부위 재측정",
                    rightAction: {
                        isPlaying.toggle()
                        bluetoothManager.startMeasurement(exercise: nil, weight: nil)
                    }
                )
                .padding(20)
            }
            
        }
        .onAppear{
            if isPlaying{
                bluetoothManager.startMeasurement(exercise: nil, weight: nil)
            }
        }
        .onDisappear{
            Task{
                await bluetoothManager.stopMeasurement(restart: false, callBack: {}, onFailure: {})
            }
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
                    isPrepare = true
                    order = 0
                    percent = 0.0
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
                    Task{
                        await bluetoothManager.refreshAll()
                    }
                }
            )
            
        }
        .padding(20)
    }
    
    @ViewBuilder
    private func spineOrder(order: Int = -1) -> some View{
        let locations = ["귀 아래", "상부 승모근", "날개뼈 윗쪽", "날개뼈 아래쪽", "상부 기립근"]
        let labels = ["C3", "C7", "T4", "T8", "T12"]
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
                                .foregroundColor((order == index || order == -1) ? .mainBlue : .whiteGray)
                            Spacer().frame(width: 29)
                            Text(locations[index])
                                .font(order == index ? .m_16() : .m_14())
                                .foregroundColor((order == index || order == -1) ? .darkGraySet : .whiteLightGray)
                            Spacer()
                            Text(labels[index])
                                .font(order == index ? .m_16() : .m_14())
                                .foregroundColor((order == index || order == -1) ? .darkGraySet : .whiteLightGray)
                                .frame(width: 29)
                        }
                    }
                }
                .padding(40)
            }
        }.frame(height: 178)
    }
    
    
    
    private func handlePercentChange() async {
        guard isPlaying else { return }
        if !isPrepare {
            bluetoothManager.clearAverageArray()
        }
        percent = 0
        withAnimation(.linear(duration: 1)) {
            percent = 0.099
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
        } catch {
            print("Task.sleep failed10: \(error)")
        }
        
        guard isPlaying else { return }
        withAnimation(.linear(duration: 1)) {
            percent = 0.199
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
        } catch {
            print("Task.sleep failed9: \(error)")
        }
        
        guard isPlaying else { return }
        withAnimation(.linear(duration: 1)) {
            percent = 0.299
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
        } catch {
            print("Task.sleep failed8: \(error)")
        }
        
        guard isPlaying else { return }
        withAnimation(.linear(duration: 1)) {
            percent = 0.399
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
        } catch {
            print("Task.sleep failed7: \(error)")
        }
        
        guard isPlaying else { return }
        withAnimation(.linear(duration: 1)) {
            percent = 0.499
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
        } catch {
            print("Task.sleep failed6: \(error)")
        }
        
        guard isPlaying else { return }
        withAnimation(.linear(duration: 1)) {
            percent = 0.599
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
        } catch {
            print("Task.sleep failed5: \(error)")
        }
        
        guard isPlaying else { return }
        withAnimation(.linear(duration: 1)) {
            percent = 0.699
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
        } catch {
            print("Task.sleep failed4: \(error)")
        }
        
        guard isPlaying else { return }
        withAnimation(.linear(duration: 1)) {
            percent = 0.799
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
        } catch {
            print("Task.sleep failed3: \(error)")
        }
        
        guard isPlaying else { return }
        withAnimation(.linear(duration: 1)) {
            percent = 0.899
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
        } catch {
            print("Task.sleep failed2: \(error)")
        }
        
        guard isPlaying else { return }
        withAnimation(.linear(duration: 1)) {
            percent = 0.999
        }
        do {
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.mainBlue, .mainBlue]
            try await Task.sleep(nanoseconds: 450_000_000)
            colors[order] = [.whiteGray, .whiteGray]
            percent = 1.0
            if(!isPrepare) {
                let setOrder = order
                Task{
                    if setOrder == 4{
                        onLogic = true
                    }
                    await bluetoothManager.stDataLogicTrigger(
                        who: store.who,
                        time: store.time!,
                        dshTime: store.dashboardTime,
                        order: setOrder,
                        callBack: { value in
                            DispatchQueue.main.async{
                                store.send(.setValue(value))
                            }
                            if setOrder == 4{
                                Task{
                                    await bluetoothManager.stScoreTrigger(
                                        who: store.who,
                                        time: store.time!,
                                        dashboardTime: store.dashboardTime,
                                        value: store.values,
                                        callBack: { report in
                                            DispatchQueue.main.async{
                                                store.send(.setReport(report))
                                                onLogic = false
                                                if onBoard {
                                                    onBoard = false
                                                    store.send(.goToReport)
                                                }
                                            }
                                        },
                                        onFailure: {
                                            mode = .error
                                            onLogic = false
                                            onBoard = false
                                        }
                                    )
                                }
                            }
                        },
                        onFailure: {
                            mode = .error
                            Task(priority: .high){
                                await bluetoothManager.stopMeasurement(restart: true, callBack: {}, onFailure: {})
                            }
                        }
                    )
                    
                }
                order += 1
            }
            isPrepare = !isPrepare
        } catch {
            print("Task.sleep failed1: \(error)")
        }
    }
}
