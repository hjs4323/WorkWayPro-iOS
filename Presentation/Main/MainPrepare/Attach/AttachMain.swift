//
//  EtPrepare.swift
//  WorkwayVer2
//
//  Created by loyH on 8/8/24.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct AttachMain {
    @Reducer(state: .equatable)
    enum Destination {
        case clip(AttachClip)
        case muscle(AttachMuscle)
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        var endBottomSheetShown: Bool = false
        
        var exercise: ExerciseDTO?
        var originalClips: [Clip] = []
        
        var editingClips: [Clip]?
        var removeModalShownController: Bool?
        var removeModalShown: Bool = false
        
        var clipExitModalShown: Bool = false
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case toggleEndBottomSheetShown
       
        case setRemoveModalShown
        case removeModalToggle
        
        case setEditingClips([Clip]?)
        case setClipExitModalShown(Bool)
        
        case setOriginalClips([Clip])
        
        case goToClip(MuscleDTO)
        
        case cancelModify
        case done
        
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case goToMainList
            case startFt
            case startEt
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action {
            case .toggleEndBottomSheetShown:
                state.endBottomSheetShown.toggle()
                return .none
                
            case .setRemoveModalShown:
                state.removeModalShown = state.removeModalShownController ?? false
                return .none
                
            case .removeModalToggle:
                state.removeModalShown.toggle()
                return .none
                
            case let .setEditingClips(clips):
                state.editingClips = clips
                if clips == nil {
                    state.removeModalShown = false
                } else {
                    return .send(.removeModalToggle)
                }
                return .none
                
            case let .setClipExitModalShown(newVal):
                state.clipExitModalShown = newVal
                return .none
                
            case let .setOriginalClips(clips):
                state.originalClips = clips
                return .none
                
            case let .goToClip(attachMuscle):
                state.destination = .clip(.init(
                    attachMuscle: attachMuscle, 
                    testType: state.exercise != nil ? .EXER : .FUNC
                ))
                return .none
                
            case .cancelModify:
                state.destination = nil
                return .none
                
            case .done:
                if state.exercise != nil {
                    return .send(.delegate(.startEt))
                }
                return .send(.delegate(.startFt))
                
                
            case let .destination(.presented(.clip(.delegate(delegateAction)))):
                switch delegateAction {
                case .goToMain:
                    state.destination = nil
                    return .none
                case .goToMainList:
                    return .send(.delegate(.goToMainList))
                }
                
            case let .destination(.presented(.muscle(.delegate(delegateAction)))):
                switch delegateAction {
                case .goToMain:
                    state.destination = nil
                    return .none
                    
                case .goToMainList:
                    return .send(.delegate(.goToMainList))
                }
                
                
            case .destination:
                return .none
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}


struct AttachMainView: View {
    @Perception.Bindable var store: StoreOf<AttachMain>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    let exerciseRepository = ExerciseRepository.shared
    
    var body: some View {
        WithPerceptionTracking {
            let mainMuscles: [MuscleDTO] = store.exercise?.mainMuscles ?? ftMuscles
            let subMuscles: [MuscleDTO] =  store.exercise?.subMuscles ?? []
            VStack(spacing: 0) {
                ScrollView(.vertical){
                    VStack(spacing: 0) {
                        Spacer().frame(height: 22)
                        NextSetInfoView(exercise: store.exercise, clips: bluetoothManager.clips)
                        Spacer()
                            .frame(height: 30)
                        CurrentAttachView(
                            clips: bluetoothManager.clips,
                            mainMuscles: mainMuscles,
                            subMuscles: subMuscles,
                            removeClip: { store.send(.setEditingClips($0)) },
                            addClip: { store.send(.goToClip($0)) }
                        )
                    }
                    .padding(.horizontal, 16)
                }
                
                let islastBtnClickable: Bool = mainMuscles.map({$0.id}).filter({ mid in !bluetoothManager.clips.map({ $0.muscleId }).contains(where: { $0 == mid }) }).isEmpty &&
                bluetoothManager.clips.map({ $0.muscleId })
                    .filter({ mid in !(mainMuscles.map({$0.id}).contains(where: { $0 == mid }) || subMuscles.map({$0.id}).contains(where: { $0 == mid })) })
                    .isEmpty

                Spacer().frame(height: 10)
                
                okButton(action: {
                    store.send(.done)
                }, enable: islastBtnClickable)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 19)
            }//최외곽 VStack
            .onAppear {
                bluetoothManager.requestBattInfo()
                store.send(.setOriginalClips(bluetoothManager.clips))
            }
            .basicToolbar(
                title: "부착 위치 설정",
                swipeBack: false,
                closeButtonAction: {
                    store.send(.toggleEndBottomSheetShown)
                }
            )
            .navigationDestination(item: $store.scope(state: \.destination?.clip, action: \.destination.clip)) { store in
                AttachClipView(store: store)
            }
            .navigationDestination(item: $store.scope(state: \.destination?.muscle, action: \.destination.muscle)) { store in
                AttachMuscleView(store: store)
            }
            .task({
                store.send(.setRemoveModalShown)
            })
            .sheet(isPresented: $store.endBottomSheetShown, content: {
                WithPerceptionTracking{
                    MainEndBottomSheet(
                        testType: store.exercise != nil ? .EXER : .FUNC,
                        cancel: {
                            store.send(.toggleEndBottomSheetShown)
                        },
                        end: {
                            store.send(.delegate(.goToMainList))
                        })
                    .presentationDetents([.height(230)])
                }
            })
            .doubleBtnAlert(isPresented: $store.removeModalShown) { 
                DoubleBtnAlertView(content: {
                    VStack {
                        HStack(spacing: 0) {
                            if let editingClips = store.editingClips {
                                ForEach(editingClips, id: \.macAddress) { clip in
                                    let muscle = exerciseRepository.getMusclesById(mid: clip.muscleId)
                                    Text("(\(muscle?.leftRightStr() ?? "?")) \(muscle?.name ?? "오류")")
                                        .foregroundStyle(.deepDarkGray)
                                        .font(.labelMedium())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3.5)
                                        .background(.whiteGray)
                                        .clipShape(RoundedRectangle(cornerRadius: 2))
                                    Spacer()
                                        .frame(width: 9)
                                }
                            }
                            Text("클립을")
                            
                        }
                        HStack(spacing: 0){
                            Text("제거")
                                .font(.system(size: 16, weight: .bold))
                            Text("하시겠어요?")
                        }
                    }
                }, leftBtn: AlertButtonView(type: .CANCEL, isPresented: $store.removeModalShown, action: {
                    store.send(.setEditingClips(nil))
                }), rightBtn: AlertButtonView(type: .DELETEMODIFY, isPresented: $store.removeModalShown, action: {
                    store.send(.removeModalToggle)
                    Task{
                        if let clips = store.editingClips {
                            for clip in clips {
                                bluetoothManager.removeClip(clip: clip)
                                try? await Task.sleep(nanoseconds: 300_000_000)
                            }
                        }
                    }
                }))
            }
            .doubleBtnAlert(isPresented: $store.clipExitModalShown) {
                DoubleBtnAlertView(content: {
                    VStack {
                        HStack(spacing: 0){
                            Text("\(store.exercise != nil ? "운동 평가" : "기능평가")")
                                .font(.s_18())
                                .foregroundStyle(.mainBlue)
                            Text("를 종료하시겠어요?")
                                .font(.s_18())
                                .foregroundStyle(.darkGraySet)
                        }
                        
                        Spacer()
                            .frame(height: 10)
                        Text("클립 부착 위치 수정이\n아직 완료되지 않았어요")
                            .font(.r_16())
                            .foregroundStyle(.mediumGray)
                    }
                }, leftBtn: AlertButtonView(type: .CANCEL, isPresented: $store.clipExitModalShown, action: {
                    store.send(.setClipExitModalShown(false))
                }), rightBtn: AlertButtonView(type: .CONFIRM, isPresented: $store.clipExitModalShown, action: {
                    store.send(.setClipExitModalShown(false))
                    if store.destination == nil {
                        store.send(.delegate(.goToMainList))
                    } else {
                        store.send(.cancelModify)
                    }
                }))
            }
            
            
        }
    }
    
    private struct NextSetInfoView: View {
        
        let exercise: ExerciseDTO?
        let clips: [Clip]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("다음 세트 정보")
                    .font(.m_18())
                    .padding(.leading, 4)
                VStack(alignment: .leading, spacing: 0) {
                    Text(exercise?.name ?? "오버헤드 스쿼트")
                        .font(.r_16())
                    Spacer().frame(height: 14)
                    
                    HStack(spacing: 10){
                        var leftMainMuscles: [MuscleDTO] {
                            let mainMuscles = exercise?.mainMuscles ?? ftMuscles
                            return mainMuscles.chunked(into: 2).map({ $0.first! })
                        }
                        
                        Text("필수")
                            .font(.m_14())
                            .foregroundStyle(.lightGraySet)
                        Spacer()
                        ForEach(leftMainMuscles, id: \.self) { leftMuscle in
                            let mName = leftMuscle.name
                            let isAttached = clips.map({ $0.muscleId }).contains(leftMuscle.id)
                            Text(mName)
                                .font(.body_M_medium())
                                .foregroundStyle(isAttached ? .white : .mainBlue)
                                .padding(6.5)
                                .background {
                                    RoundedRectangle(cornerRadius: 20)
                                        .if(!isAttached) { view in
                                            view.stroke(.mainBlue, lineWidth: 1)
                                        }
                                        .if(isAttached, transform: { view in
                                            view
                                                .foregroundStyle(.mainBlue)
                                        })
                                }
                        }
                    }
                    .padding(.leading, 8)
                    
                    if let subMuscles = exercise?.subMuscles {
                        if !subMuscles.isEmpty{
                            Spacer().frame(height: 10)
                            
                            HStack(spacing: 10){
                                var leftSubMuscles: [MuscleDTO] {
                                    return subMuscles.chunked(into: 2).map({ $0.first! })
                                }
                                
                                Text("선택")
                                    .font(.m_14())
                                    .foregroundStyle(.lightGraySet)
                                Spacer()
                                ForEach(leftSubMuscles, id: \.self) { leftMuscle in
                                    let mName = leftMuscle.name
                                    let isAttached = clips.map({ $0.muscleId }).contains(leftMuscle.id)
                                    Text(mName)
                                        .font(.body_M_medium())
                                        .foregroundStyle(isAttached ? .white : .mainBlue)
                                        .padding(6.5)
                                        .background {
                                            RoundedRectangle(cornerRadius: 20)
                                                .if(!isAttached) { view in
                                                    view.stroke(.mainBlue, lineWidth: 1)
                                                }
                                                .if(isAttached, transform: { view in
                                                    view
                                                        .foregroundStyle(.mainBlue)
                                                })
                                        }
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }
                    
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 23)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow2()
            }
            
        }
    }
    
    private struct CurrentAttachView: View {
        let clips: [Clip]
        var mainMuscles: [MuscleDTO]
        var subMuscles: [MuscleDTO]
        let removeClip: ([Clip]) -> Void
        let addClip: (MuscleDTO) -> Void
        
        var body: some View {
            VStack(alignment: .leading) {
                let exerciseMuscles: [MuscleDTO] = mainMuscles + subMuscles
                var leftMuscles: [MuscleDTO] {
                    return exerciseMuscles.chunked(into: 2).map({ $0.first! })
                }
                var attachMuscle : MuscleDTO? {for muscle in leftMuscles {
                    if !clips.map({$0.muscleId}).contains(muscle.id) {
                        return muscle
                    }
                }
                    return nil
                }
                
                HStack {
                    Text("현재 부착 위치")
                        .foregroundStyle(.deepDarkGray)
                        .font(.m_18())
                        .padding(.leading, 4)
                    Spacer()
                    if clips.count < min(8, exerciseMuscles.count) {
                        Button(action: {
                            addClip(attachMuscle!)
                        }, label: {
                            HStack(spacing: 8) {
                                Text("추가 부착하기")
                                    .font(.r_14())
                                ZStack{
                                    Image(systemName: "circle.fill")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.whiteGray)
                                        .opacity(0.5)
                                    Image(systemName: "plus")
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(.mediumGray)
                                }
                                
                            }
                            .foregroundStyle(.mediumGray)
                        })
                    }
                }
                
                Spacer().frame(height: 20)
                
                if clips.isEmpty {
                    VStack {
                        Spacer()
                        Text("연결된 기기가 없습니다")
                            .font(.r_16())
                            .foregroundStyle(.mediumGray)
                        Spacer()
                    }
                    .frame(height: 320)
                    .frame(maxWidth: .infinity)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .shadow2()
                    .overlay{
                        if clips.isEmpty{
                            ChatBubbleTopTriangle(
                                backgroundColor: .mainBlue,
                                text: "여기를 눌러 기기를 연결해주세요",
                                width: 230,
                                triangleOffset: 130
                            )
                            .offset(x: 60, y: -150)
                        }
                    }
                } else {
                    let wrongClips: [Clip] = clips.filter{ !exerciseMuscles.map{$0.id}.contains($0.muscleId) }.reversed()
                    let rightClips: [Clip] = clips.filter{ exerciseMuscles.map{$0.id}.contains($0.muscleId) }.reversed()
                    VStack(spacing: 16) {
                        
                        ForEach(wrongClips.chunked(into: 2), id: \.first!.macAddress) { doubleClip in
                            CurrentAttachPartView(
                                clips: doubleClip,
                                removeClip: {
                                    removeClip(doubleClip)
                                },
                                isWrongAttach: true
                            )
                        }
                        ForEach(rightClips.chunked(into: 2), id: \.first!.macAddress) { doubleClip in
                            CurrentAttachPartView(
                                clips: doubleClip,
                                removeClip: {
                                    removeClip(doubleClip)
                                },
                                isWrongAttach: false
                            )
                        }
                    }
                    .padding(.vertical, 16)
                    .background(.background)
                }
            }
        }
        
        struct CurrentAttachPartView: View {
            
            let clips: [Clip]
            let removeClip: () -> Void
            var isWrongAttach: Bool = false
            
            var body: some View {
                VStack {
                    HStack {
                        Image("clip")
                            .resizable()
                            .aspectRatio(62/70, contentMode: .fit)
                            .frame(height: 43)
                            .padding(.vertical, 20)
                        Spacer().frame(width: 30)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack() {
                                Text("근육")
                                    .font(.r_14())
                                    .foregroundStyle(.mediumGray)
                                    .frame(width: 40, alignment: .leading)
                                if let mid = clips.first?.muscleId {
                                    Text(muscleDictionary[mid]?.name ?? "오류")
                                        .font(.s_14())
                                }
                            }
                            HStack {
                                Text("배터리")
                                    .font(.r_14())
                                    .foregroundStyle(.mediumGray)
                                    .frame(width: 40, alignment: .leading)
                                ForEach(clips, id: \.muscleId) { clip in
                                    HStack(spacing: 5) {
                                        let muscle = ExerciseRepository.shared.getMusclesById(mid: clip.muscleId)
                                        Text("\(muscle?.leftRightStr() ?? "?")")
                                            .font(.r_14())
                                        BatteryView(battery: clip.battery)
                                            .frame(width: 25, height: 13)
                                        if clip.muscleId % 2 == 1 {
                                            Text("|")
                                                .foregroundStyle(.graySet)
                                                .font(.r_14())
                                                .padding(.horizontal, 3)
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                    Button(action: {
                        removeClip()
                    }, label: {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(.whiteGray, lineWidth: 1)
                            .overlay {
                                Text("제거")
                                    .foregroundStyle(.mediumGray)
                                    .font(.r_16())
                            }
                            .frame(height: 32)
                    })
                    if !clips.filter({ $0.battery != nil && $0.battery! < 3 }).isEmpty {
                        Spacer().frame(height: 16)
                        HStack {
                            Image(systemName: "info.circle")
                                .frame(width: 16, height: 16)
                            Text("배터리 정보를 읽어오려면 전원을 껐다 켜주세요")
                                .font(.r_12())
                        }
                        .foregroundStyle(.mainRed)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 13)
                .padding(.bottom, 20)
                .padding(.horizontal, 20)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow2(color: isWrongAttach ? .mainRed : .black)
            }
        }
    }
    
}
