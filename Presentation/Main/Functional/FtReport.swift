//
//  DynamicReport.swift
//  WorkwayVer2
//
//  Created by loyH on 7/9/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct FtReport{
    @ObservableState
    struct State: Equatable{
        var setIndex: Int
        var reports: [ReportFTDTO]
        var lastReports: [ReportFTDTO?]
        var rawDatas: [ [[Float]]? ]
        
        var ftParam: FTParam?
        
        let isFromLog: Bool
        
        init(setIndex: Int, reports: [ReportFTDTO], lastReport: ReportFTDTO? = nil, rawDatas: [[Float]]? = nil, ftParam: FTParam? = nil, isFromLog: Bool) {
            self.setIndex = setIndex
            self.reports = reports
            var tempLastReports: [ReportFTDTO?] = reports
            self.lastReports = tempLastReports
            var tempRawDatas: [ [[Float]]? ] = Array(repeating: nil, count: reports.count)
            tempRawDatas[setIndex] = rawDatas
            self.rawDatas = tempRawDatas
            self.ftParam = ftParam
            self.isFromLog = isFromLog
        }
    }
    
    enum Action{
        case getFTParam
        case setFTParam(FTParam)
        case getFTRawData(Int)
        case setFTRawData(Int, [[Float]]?)
        case getLastReport(Int)
        case setLastReport(Int, ReportFTDTO?)
        
        case setReportIndex(Int)
        case dismiss
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case goToMainList(ReportFTDTO)
        }
    }
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.reportRepository) var reportRepository
    var body: some ReducerOf<Self>{
        Reduce{ state, action in
            switch action{
            case .getFTParam:
                return .run { send in
                    do {
                        if let ftParam = try await reportRepository.getFTParam(){
                            await send(.setFTParam(ftParam))
                        }
                    } catch {
                        print("FTReport/getFTParam: error getting FTParam \(error)")
                    }
                }
                
            case let .setFTParam(param):
                state.ftParam = param
                return .none
                
            case let .getFTRawData(setIndex):
                return .run { [report = state.reports[setIndex], setIndex] send in
                    reportRepository.getGraphData(dir: .FTGRAPH, who: report.who, time: report.time, muscleCount: report.muscles.count, callBack: { data in
                        DispatchQueue.main.async {
                            send(.setFTRawData(setIndex, data))
                        }
                    })
                }
                
            case let .setFTRawData(setIndex, raw):
                state.rawDatas[setIndex] = raw
                return .none
                
            case let .getLastReport(setIndex):
                let report = state.reports[setIndex]
                let who: String = report.who
                let time: Double = Double(report.time)
                return .run { [setIndex] send in
                    do {
                        await send(.setLastReport(setIndex, try await reportRepository.getLastFT(who: who, endUnixTime: time, muscles: ftMuscles)))
                    } catch {
                        print("FTReport/getLastReport: no lastReport")
                        await send(.setLastReport(setIndex, nil))
                    }
                }
                
            case let .setLastReport(setIndex, lastReport):
                state.lastReports[setIndex] = lastReport
                return .none
                
            case let .setReportIndex(newVal):
                state.setIndex = newVal
                print("setIndex = \(state.setIndex)")
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



struct FtReportView: View {
    @Perception.Bindable var store: StoreOf<FtReport>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var swipeBack: Bool = true
    
    var body: some View {
        WithPerceptionTracking{
            let report = store.reports[store.setIndex]
            let lastReport = store.lastReports[store.setIndex]
            GeometryReader { geometry in
                WithPerceptionTracking {
                    
                    if let ftParam = store.ftParam {
                        
                        VStack(spacing: 0){
                            ScrollView{
                                if store.isFromLog {
                                    ReportIndexRow(
                                        geometry: geometry,
                                        reportCount: store.reports.count,
                                        currentIndex: store.setIndex,
                                        selectIndex: { index in
                                            store.send(.setReportIndex(index))
                                        }
                                    )
                                }
                                
                                VStack(spacing: 0){
                                    SingleBar(
                                        title: "부위 적합성",
                                        unit: "p",
                                        score: report.corrScore,
                                        lastScore: lastReport?.corrScore,
                                        standard: 80,
                                        UIStandard: 70,
                                        description: "부위 적합성은 동작별 관여 근육의 활성화 비율을 통해 산출되며, 동작의 적정성 여부를 의미합니다."
                                    )
                                    .padding(25)
                                    
                                    
                                    ThickDivider()
                                    
                                    FTEvalueationByPart(geometry: geometry, report: report, ftParam: ftParam)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 30)
                                    
                                    ThickDivider()
                                    
                                    FTDetailByPart(geometry: geometry, report: report, lReport: lastReport, ftParam: ftParam)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 25)

                                    if let rawDatas = store.rawDatas[store.setIndex], rawDatas.filter({ $0.isEmpty }).isEmpty {
                                        
                                        ThickDivider()
                                        
                                        FTSingleRawByPart(geometry: geometry, report: report, rawDatas: rawDatas, ftParam: ftParam)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 25)
                                            .padding(.bottom, 30)
                                        
                                        Divider()
                                            .border(.whiteGray)
                                        
                                        FTPairRawByPart(geometry: geometry, report: report, rawDatas: rawDatas)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 25)
                                            .padding(.bottom, 30)
                                        
                                        Spacer().frame(height: 7)
                                    } else {
                                        VStack {
                                            Spacer()
                                            Divider()
                                                .foregroundStyle(.background)
                                            ProgressView()
                                                .onAppear(perform: {
                                                    if store.rawDatas.count > store.setIndex && store.rawDatas[store.setIndex] == nil {
                                                        store.send(.getFTRawData(store.setIndex))
                                                    }
                                                })
                                            Divider()
                                                .foregroundStyle(.background)
                                            Spacer()
                                        }
                                        .frame(height: 50)
                                    }
                                }
                            }
                            if !store.isFromLog {
                                okButton(action: {
                                    if !swipeBack {
                                        store.send(.delegate(.goToMainList(report)))
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
                        .onAppear(perform: {
                            if lastReport == nil {
                                print("getLastFT")
                                store.send(.getLastReport(store.setIndex))
                            }
                        })
                    } else {
                        VStack {
                            Spacer()
                            ProgressView()
                                .onAppear {
                                    if store.ftParam == nil {
                                        print("getFTParam")
                                        store.send(.getFTParam)
                                    }
                                }
                            Spacer()
                        }
                        .frame(width: geometry.size.width)
                    }
                }
            }
            .basicToolbar(
                title: "기능 평가",
                swipeBack: swipeBack,
                closeButtonAction: swipeBack ? nil : {
                    store.send(.delegate(.goToMainList(report)))
                }
            )
        }
    }
    
    private struct ReportIndexRow: View {
        let geometry: GeometryProxy
        @State var isExpanded: Bool = false
        let reportCount: Int
        let currentIndex: Int
        let selectIndex: (Int) -> ()
        
        var body: some View {
            ScrollView(.horizontal){
                HStack {
                    if isExpanded {
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
                        Button(action: {
                            isExpanded = true
                        }, label: {
                            HStack {
                                Triangle()
                                    .frame(width: 12, height: 11)
                                    .rotationEffect(.degrees(180))
                                Spacer().frame(width: 12)
                                Text("\(currentIndex + 1)세트")
                                    .font(.m_14())
                                    .foregroundStyle(.darkGraySet)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow2()
                        })
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

struct FTEvalueationByPart: View {
    let geometry: GeometryProxy
    let report: ReportFTDTO
    let ftParam: FTParam
    var setNum: Int?
    
    @State var index: Int = 0
    
    var body: some View{
        VStack(alignment: .leading ,spacing: 20){
            if let setNum = setNum{
                HStack{
                    Text("오버헤드 스쿼트")
                        .font(.m_16())
                        .foregroundStyle(.lightBlack)
                    Spacer()
                    Text("\(setNum)세트")
                        .font(.m_14())
                        .foregroundStyle(.lightGraySet)
                }
            }
            else{
                Text("부위별 평가")
                    .font(.m_16())
                    .foregroundStyle(.lightBlack)
            }
            
            HStack(spacing: 8){
                ForEach(0..<4) { i in
                    Button(action: {
                        index = i
                    }, label: {
                        HStack{
                            Spacer()
                            Text(report.muscles[i*2].name)
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
        
        HStack{
            if let leftWSBorder = ftParam.wsBorder[report.muscles[index*2].id],
               let rightWSBorder = ftParam.wsBorder[report.muscles[index*2 + 1].id],
               let leftSWStandard = leftWSBorder.first,
               let leftMax = leftWSBorder.last,
               let rightSWStandard = rightWSBorder.first,
               let rightMax = rightWSBorder.last
            {
                let leftESStandard = leftWSBorder[1]
                let rightESStandard = rightWSBorder[1]
                
                Spacer()
                MuscleSWView(
                    leftScore: report.crRates[index*2],
                    rightScore: report.crRates[index*2 + 1],
                    esStandard: [leftESStandard, rightESStandard],
                    swStandard: [leftSWStandard, rightSWStandard],
                    maxScore: [leftMax, rightMax]
                )
                .aspectRatio(307 / 231, contentMode: .fit)
                .frame(width: geometry.size.width * 307 / 393)
                .padding(.vertical, 30)
                Spacer()
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow2()
        .padding(.horizontal, 5)
    }
}

struct FTDetailByPart: View {
    let geometry: GeometryProxy
    let report: ReportFTDTO
    let lReport: ReportFTDTO?
    let ftParam: FTParam
    
    @State var index = 0
    
    var body: some View {
        VStack(alignment: .leading ,spacing: 20){
            VStack(alignment: .leading ,spacing: 20){
                Text("부위별 상세")
                    .font(.m_16())
                    .foregroundStyle(.lightBlack)
                
                VStack(spacing: 10){
                    HStack(spacing: 8){
                        ForEach(0..<4) { i in
                            Button(action: {
                                index = i
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text(report.muscles[i].fullName(multiLine: true))
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
                    HStack(spacing: 8){
                        ForEach(4..<8) { i in
                            Button(action: {
                                index = i
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text(report.muscles[i].fullName(multiLine: true))
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
            }
            .padding(.horizontal, 4)
            
            HStack{
                if let crBorder = ftParam.crBorder[report.muscles[index].id], let standard = crBorder.first, let maxScore = crBorder.last {
                    SingleBar(
                        title: "수축 이완비",
                        unit: "%",
                        score: report.crRates[index],
                        lastScore: lReport?.crRates[index],
                        maxScore: maxScore,
                        standard: standard,
                        description: "\(report.muscles[index].fullName(multiLine: false)) 적절 범위 : \(Int(standard)) ~ \(Int(maxScore)) %",
                        description2: "적절 범위 보다 수치가 작으면 해당 부위가 덜 활성화되고 있음을 의미합니다. 이것이 지속되면 근육의 약화로 해석할 수 있습니다.",
                        smallBar: true
                    )
                }
            }
            .padding(.vertical, 30)
            .padding(.leading, 20)
            .padding(.trailing, 15)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow2()
            .padding(.horizontal, 5)
            
        }
    }
}

struct FTSingleRawByPart: View {
    let geometry: GeometryProxy
    let report: ReportFTDTO
    let rawDatas: [[Float]]
    let ftParam: FTParam
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
                    HStack(spacing: 8){
                        ForEach(0..<4) { i in
                            Button(action: {
                                index = i
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text(report.muscles[i].fullName(multiLine: true))
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
                    HStack(spacing: 8){
                        ForEach(4..<8) { i in
                            Button(action: {
                                index = i
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text(report.muscles[i].fullName(multiLine: true))
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
                                names: [report.muscles[index].fullName(multiLine: false)],
                                rawDatas: [rawDatas[index]],
                                standard: ftParam.rawBorder[report.muscles[index].id] == nil ? nil : [ftParam.rawBorder[report.muscles[index].id]!, maxData],
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
                    Text(report.muscles[index].fullName(multiLine: false))
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

struct FTPairRawByPart: View {
    let geometry: GeometryProxy
    let report: ReportFTDTO
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
                    ForEach(0..<4) { i in
                        Button(action: {
                            index = i
                        }, label: {
                            HStack{
                                Spacer()
                                Text(report.muscles[i*2].name)
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
                                names: [report.muscles[index*2].fullName(multiLine: false), report.muscles[index*2 + 1].fullName(multiLine: false)],
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
                    Text(report.muscles[index * 2].fullName(multiLine: false))
                        .font(.m_14())
                        .foregroundColor(.lightGraySet)
                    
                    Spacer().frame(width: 14)
                    
                    Rectangle()
                        .frame(width: 17, height: 1)
                        .foregroundColor(.red)
                    Spacer().frame(width: 8)
                    Text(report.muscles[index * 2 + 1].fullName(multiLine: false))
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
