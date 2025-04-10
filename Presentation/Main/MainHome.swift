//
//  MeasurementMain.swift
//  WorkwayVer2
//
//  Created by loyH on 7/9/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


@Reducer
struct MainHome{
    @ObservableState
    struct State: Equatable{
        
    }
    
    enum Action{
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            case goToTraineeList
            case startTest(TestType)
            case goToTraineeSearch
        }
    }
    
    var body: some ReducerOf<Self>{
        Reduce{ state, action in
            switch action{
            case .delegate:
                return .none
            }
        }
    }
}

struct MainHomeView: View {
    @Perception.Bindable var store: StoreOf<MainHome>
    
    var body: some View {
        WithPerceptionTracking{
            GeometryReader{ geometry in
                ScrollView {
                    VStack(spacing: 20){
                        Spacer().frame(height: 10)
                        
                        Button{
                            store.send(.delegate(.startTest(.SPINE)))
                        } label: {
                            HStack(alignment: .top){
                                VStack(alignment: .leading, spacing: 10){
                                    Text("상태 평가")
                                        .font(.m_18())
                                        .foregroundColor(.black)
                                    
                                    Text("체형 원인 분석하기")
                                        .font(.r_16())
                                        .foregroundColor(.lightGraySet)
                                }
                                Spacer()
                                Image("st_example")
                                    .resizable()
                                    .aspectRatio(110/107, contentMode: .fit)
                                    .frame(width: geometry.size.width * 110/393)
                                Spacer().frame(width: 10)
                            }
                            .padding(30)
                            .padding(.top, 15)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow2()
                        
                        Button{
                            //                            store.send(.delegate(.navigateToTraineeList))
                            store.send(.delegate(.startTest(.FUNC)))
                        } label: {
                            HStack(alignment: .top){
                                VStack(alignment: .leading, spacing: 10){
                                    Text("기능 평가")
                                        .font(.m_18())
                                        .foregroundColor(.black)
                                    
                                    Text("동작별 근기능 검사")
                                        .font(.r_16())
                                        .foregroundColor(.lightGraySet)
                                }
                                Spacer()
                                Image("ft_example")
                                    .resizable()
                                    .aspectRatio(110/107, contentMode: .fit)
                                    .frame(width: geometry.size.width * 110/393)
                                Spacer().frame(width: 10)
                            }
                            .padding(30)
                            .padding(.top, 15)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow2()
                        
                        Button{
                            store.send(.delegate(.startTest(.EXER)))
                        } label: {
                            HStack(alignment: .top){
                                VStack(alignment: .leading, spacing: 10){
                                    Text("운동 평가")
                                        .font(.m_18())
                                        .foregroundColor(.black)
                                    
                                    Text("부위별 근활성 평가")
                                        .font(.r_16())
                                        .foregroundColor(.lightGraySet)
                                }
                                Spacer()
                                Image("et_example")
                                    .resizable()
                                    .aspectRatio(110/107, contentMode: .fit)
                                    .frame(width: geometry.size.width * 110/393)
                                Spacer().frame(width: 10)
                            }
                            .padding(30)
                            .padding(.top, 15)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow2()
                        
                        Spacer()
                    }
                    .padding(20)
                    .toolbar{
                        ToolbarItem(placement: .principal){
                            Image("workway_logo")
                                .resizable()
                                .frame(width: 136, height: 26)
                        }
                    }
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.lightBlack)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                }
                .background(.backgroundGray)
                .onAppear{
                    let _ = ExerciseRepository.shared
                }
            }
        }
    }
}
