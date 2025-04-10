//
//  TraineeSearch.swift
//  WorkwayVer2
//
//  Created by loyH on 7/26/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct TraineeSearch{
    @Reducer(state: .equatable)
    enum Destination {
        case stReport(StReport)
        case ftReport(FtReport)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        
        var number: String = ""
        var okBtnClickable: Bool = false
        
        var searchedStReports: [ReportST]?
        var searchedFtReports: [ReportFTDTO]?
        
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case goToStReport(ReportST)
        case goToFtReport(ReportFTDTO)
        case search
        case setReports([ReportST]?, [ReportFTDTO]?)
        
        case destination(PresentationAction<Destination.Action>)
        
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.reportRepository) var reportRepository
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action{
            case .search:
                //                db에 검색
                return .run { [number = state.number] send in
                    do{
                        let sts = try await reportRepository.getReportST(who: number, startUnixTime: nil, endUnixTime: nil)
                        let fts = try await reportRepository.getReportFT(who: number, startUnixTime: nil, endUnixTime: nil, muscles: nil)
                        
                        await send(.setReports(sts, fts))
                    } catch {
                        print("TraineeSearch/search: error getting reports \(error)")
                        await send(.setReports(nil, nil))
                    }
                }
                
            case .binding(\.number):
                let newNumber = state.number
                
                if newNumber.prefix(3) == "010" && newNumber.count == 11 {
                    state.okBtnClickable = true
                } else {
                    state.okBtnClickable = false
                }
                return .none
                
            case .binding:
                return .none
                
            case let .goToStReport(st):
                let lastReport: ReportST? = {
                    if let index = state.searchedStReports!.firstIndex(of: st), index > 0 {
                        return state.searchedStReports![index - 1]
                    }
                    return nil
                }()
                
                state.destination = .stReport(.init(report: st, lastReport: lastReport))
                return .none
                
            case let .goToFtReport(ft):
                let lastReport: ReportFTDTO? = {
                    if let index = state.searchedFtReports!.firstIndex(of: ft), index > 0 {
                        return state.searchedFtReports![index - 1]
                    }
                    return nil
                }()
                
                return .none
                
            case let .setReports(sts, fts):
                state.searchedStReports = sts
                state.searchedFtReports = fts
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}


struct TraineeSearchView: View {
    @Perception.Bindable var store: StoreOf<TraineeSearch>
    
    @FocusState private var focused: Bool
    
    var body: some View {
        WithPerceptionTracking{
            GeometryReader{ geometry in
                VStack(spacing: 0){
                    HStack{
                        Image(systemName: "magnifyingglass")
                        TextField("핸드폰 번호를 입력해주세요", text: $store.number)
                            .foregroundStyle(focused ? .lightBlack : .mediumGray)
                            .font(.r_16())
                            .autocorrectionDisabled()
                            .focused($focused)
                            .keyboardType(.numberPad)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow2()
                    .padding(20)
                    
                    Spacer().frame(height: 20)
                    
                    VStack(spacing: 0){
                        let reports: [any Report]? = (store.searchedStReports ?? []) + (store.searchedFtReports ?? [])
                        let sortedReports: [any Report]? = reports?.sorted{ $0.time > $1.time }
                        HStack{
                            Text("검색 결과")
                                .font(.m_16())
                                .foregroundColor(.lightBlack)
                            
                            Spacer()
                            
                            Text("\(String(sortedReports?.count ?? 0))개")
                                .font(.r_14())
                                .foregroundStyle(.darkGraySet)
                        }
                        .padding(.horizontal, 30)
                        Spacer().frame(height: 15)
                        
                        ScrollView{
                            if let reports = sortedReports {
                                ForEach(reports, id: \.time){ report in
                                    Button {
                                        if let report = report as? ReportST{
                                            store.send(.goToStReport(report))
                                        }
                                        else if let report = report as? ReportFTDTO{
                                            store.send(.goToFtReport(report))
                                        }
                                    } label: {
                                        HStack(spacing:0){
                                            VStack(alignment: .leading, spacing: 6){
                                                if let report = report as? ReportST{
                                                    var time: String {
                                                        let timeInterval = Double(report.time)
                                                        let formattedString = timeInterval.unixTimeToDateStr("yy.MM.dd (E) hh:mm")
                                                        return formattedString
                                                    }
                                                    Text(String(time))
                                                        .font(.r_16())
                                                        .foregroundStyle(.lightBlack)
                                                    Text("척추근 평가")
                                                        .font(.r_12())
                                                        .foregroundStyle(.lightGraySet)
                                                }
                                                else if let report = report as? ReportFTDTO{
                                                    var time: String {
                                                        let timeInterval = Double(report.time)
                                                        let formattedString = timeInterval.unixTimeToDateStr("yy.MM.dd (E) hh:mm")
                                                        return formattedString
                                                    }
                                                    Text(String(time))
                                                        .font(.r_16())
                                                        .foregroundStyle(.lightBlack)
                                                    Text("기능 평가")
                                                        .font(.r_12())
                                                        .foregroundStyle(.lightGraySet)
                                                    
                                                }
                                                
                                            }
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .frame(width: 16, height: 27)
                                                .foregroundStyle(.whiteGray)
                                        }
                                        .padding([.leading, .trailing], 25)
                                        .padding([.top, .bottom], 30)
                                        .background(.white)
                                        .cornerRadius(5)
                                        .shadow2()
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                    }
                    
                    if focused {
                        okButton(name: "검색", action: {
                            store.send(.search)
                            self.focused = false
                        }, enable: store.okBtnClickable)
                        .padding(20)
                    }
                    
                }
                .basicToolbar(title: "레포트 검색")
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.hideKeyboard()
                }
                .onAppear{
                    if store.number.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.focused = true
                        }
                    }
                }
                .navigationDestination(item: $store.scope(state: \.destination?.stReport, action: \.destination.stReport)) { store in
                    StReportView(store: store)
                }
                .navigationDestination(item: $store.scope(state: \.destination?.ftReport, action: \.destination.ftReport)) { store in
                    FtReportView(store: store)
                }
            }
        }
    }
}

#Preview {
    TraineeSearchView(store: Store(initialState: TraineeSearch.State(), reducer:{
        TraineeSearch()
    }))
}
