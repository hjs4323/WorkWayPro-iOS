//
//  StReport.swift
//  WorkwayVer2
//
//  Created by loyH on 7/22/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct StReport{
    @ObservableState
    struct State: Equatable{
        var report: ReportST
        var lastReport: ReportST?
        
        var stParams: [STParam]?
    }
    
    enum Action{
        case getSTParams
        case setSTParams([STParam])
        case getLastReport
        case setLastReport(ReportST?)
        
        case dismiss
        
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            case goToMainList(ReportST)
        }
    }
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.reportRepository) var reportRepository
    var body: some ReducerOf<Self>{
        Reduce{ state, action in
            switch action{
            case .getSTParams:
                return .run { send in
                    do {
                        if let stParam = try await reportRepository.getSTParams(){
                            await send(.setSTParams(stParam))
                        }
                    } catch {
                        print("STReport/getSTParams: error getting STParams \(error)")
                    }
                }
            case let .setSTParams(params):
                state.stParams = params
                return .none
                
            case .getLastReport:
                let who: String = state.report.who
                let time: Double = Double(state.report.time)
                return .run { send in
                    do {
                        await send(.setLastReport(try await reportRepository.getLastST(who: who, endUnixTime: time)))
                    } catch {
                        print("STReport/getLastReport: no lastReport \(error)")
                        await send(.setLastReport(nil))
                    }
                }
            case let .setLastReport(st):
                state.lastReport = st
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

struct StReportView: View {
    @Perception.Bindable var store: StoreOf<StReport>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var swipeBack: Bool = true
    
    var body: some View {
        WithPerceptionTracking{
            GeometryReader { geometry in
                WithPerceptionTracking {
                    if let stParams = store.stParams {
                        ScrollView {
                            VStack(spacing: 0){
                                    Spacer().frame(height: 25)
                                StReportPartView(
                                    report: store.report,
                                    lastReport: store.lastReport,
                                    stParams: stParams
                                )
                                Spacer()
                                okButton(action: {
                                    if !swipeBack {
                                        Task{
                                            await bluetoothManager.refreshAll()
                                        }
                                        store.send(.delegate(.goToMainList(store.report)))
                                    }
                                    else {
                                        store.send(.dismiss)
                                    }
                                    
                                })
                                .padding(20)
                            }
                            .frame(height: geometry.size.height)
                        }
                    } else {
                        VStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(width: geometry.size.width)
                        .task {
                            if store.stParams == nil {
                                store.send(.getSTParams)
                            }
                            if store.lastReport == nil {
                                store.send(.getLastReport)
                            }
                        }
                    }
                }
            }
            .basicToolbar(
                title: "척추근 평가",
                swipeBack: swipeBack,
                closeButtonAction: swipeBack ? nil : {
                    Task {
                        await bluetoothManager.refreshAll()
                    }
                    store.send(.delegate(.goToMainList(store.report)))
                }
            )
        }
    }
}

struct StReportPartView: View {
    var report: ReportST
    var lastReport: ReportST?
    var stParams: [STParam]
    
    var setNum: Int?
    
    var body: some View {
        VStack(spacing: 0){
            VStack(spacing: 0){
                SingleBar(
                    title: "척추근 평가",
                    unit: "점",
                    score: report.score,
                    lastScore: lastReport?.score,
                    standard: 80,
                    UIStandard: 70,
                    description: "척추근 평가는 평시 근긴장도를 기반으로 체형의 원인을 분석하는 검사입니다. 일반적인 경우에 2~3단계는 적절, 그 외는 주의로 분류됩니다."
                )
                .overlay(alignment: .topTrailing){
                    if let setNum = setNum{
                        Text("\(setNum)세트")
                            .font(.m_14())
                            .foregroundStyle(.lightGraySet)
                    }
                }
                Spacer().frame(height: 10)
            }
            .padding(20)
            .padding(.top, 10)
            
            Divider()
                .border(.whiteGray, width: 1)
            Spacer().frame(height: 10)
            
            STTensionBalanceView(report: report, stParams: stParams)
            .padding(20)
        }
    }
}

struct STTensionBalanceView: View {
    var report: ReportST
    var stParams: [STParam]
    var pickerDownside: Bool = false
    
    @State var tabIndex: Int = 0
    
    enum tabInfo : String, CaseIterable {
        case tension = "긴장도"
        case balance = "밸런스"
    }
    
    var body: some View {
        VStack(spacing: 0){
            if !pickerDownside{
                CustomSegmentedPicker(
                    selection: $tabIndex,
                    size: CGSize(width: 300, height: 38),
                    segmentLabels: ["긴장도", "밸런스"]
                )
                Spacer().frame(height: 50)
            }
            
            HStack{
                Spacer()
                let reportChartValue = getReportChartValue(reportST: report, params: stParams, barShape: tabIndex == 0 ? .RECT : .ARROW)
                
                MuscleBarGraph(barSizes: reportChartValue.map({ $0.0 }).chunked(into: 2), colors: reportChartValue.map({ $0.1 }).chunked(into: 2), barShape: tabIndex == 0 ? .RECT : .ARROW)
                    .frame(width: 220, height: 213)
                
                Spacer()
                    .if (tabIndex == 0){ view in
                        view.overlay{
                            VStack(spacing: 0){
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
                            }
                        }
                        
                    }
                
            }
            
            if pickerDownside{
                Spacer().frame(height: 25)
                CustomSegmentedPicker(
                    selection: $tabIndex,
                    size: CGSize(width: 300, height: 38),
                    segmentLabels: ["긴장도", "밸런스"]
                )
                .padding(.horizontal, 10)
            }
        }
    }
}

func getReportChartValue(reportST: ReportST, params: [STParam], barShape: MuscleBarGraph.BarShape = .RECT) -> [(Float, Color)] {
    if barShape == .RECT {
        return spineCode.flatMap { sCodeUppercase in
            let spineCode = sCodeUppercase.lowercased()
            guard let value: [Float] = reportST.value[sCodeUppercase] else {
                return [(Float(0), Color.whiteGray), (Float(0), Color.whiteGray)]
            }
            return value.enumerated().map { (leftRightIndex, fl) in
                let key = spineCode + (leftRightIndex == 0 ? "l" : "r")
                guard let uiBorder = params.first(where: { $0.spineCode == key })?.uiBorders else { return (0, Color.clear) }
                
                switch fl {
                case uiBorder[0] ..< uiBorder[1]:
                    return ((fl - uiBorder[0]) / 4 / uiBorder[1], stColors[3])
                case uiBorder[1] ..< uiBorder[2]:
                    return (0.25 + (fl - uiBorder[1]) / 4 / uiBorder[2], stColors[2])
                case uiBorder[2] ..< uiBorder[3]:
                    return (0.5 + (fl - uiBorder[2]) / 4 / uiBorder[3], stColors[1])
                case uiBorder[3] ..< uiBorder[4]:
                    return (0.75 + (fl - uiBorder[3]) / 4 / uiBorder[4], stColors[0])
                default:
                    return (0, Color.clear)
                }
            }
        }
    } else {
        return spineCode.flatMap { sCodeUppercase in
            let spineCode = sCodeUppercase.lowercased()
            guard let value = reportST.value[sCodeUppercase], let left = value.first, let right = value.last else { return [Float(0), Float(0)] }
            if left == right {
                return [0,0]
            } else if left < right {
                return [0, (right - left) / left]
            } else {
                return [(left - right) / right, 0]
            }
        }.map({ ($0, .mainBlue) })
    }
}

