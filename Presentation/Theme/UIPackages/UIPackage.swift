//
//  UIPackage.swift
//  LAYR
//
//  Created by 김성욱 on 2023/09/26.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import UIKit

struct DragHandle: View {
    
    let color: Color
    
    var body: some View {
        VStack(spacing: 4.0) {
            Rectangle()
                .frame(width: 15, height: 1)
            Rectangle()
                .frame(width: 15, height: 1)
        }
        .contentShape(Rectangle())
        .frame(width: 18, height: 18)
        .foregroundStyle(color)
    }
}

struct BarProgressStyle: ProgressViewStyle {
    
    var color: Color = .buttonBlue
    var height: Double = 20.0
    var labelFontStyle: Font = .body
    
    func makeBody(configuration: Configuration) -> some View {
        
        let progress = configuration.fractionCompleted ?? 0.0
        
        GeometryReader { geometry in
            
            VStack(alignment: .leading) {
                
                configuration.label
                    .font(labelFontStyle)
                
                RoundedRectangle(cornerRadius: 2.0)
                    .fill(Color(uiColor: .clear))
                    .frame(height: height)
                    .frame(width: geometry.size.width)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2.0)
                            .fill(color)
                            .frame(width: geometry.size.width * progress)
                            .overlay {
                                if let currentValueLabel = configuration.currentValueLabel {
                                    
                                    currentValueLabel
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                    }
                
            }
            
        }
    }
}

struct MyToggleStyle: ToggleStyle {
    private let width = 26.0
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .frame(width: width, height: width / 26 * 17)
                    .foregroundColor(configuration.isOn ? .buttonBlue : .clear)
                    .overlay {
                        if !configuration.isOn {
                            Capsule()
                                .stroke(.mediumGray, lineWidth: 2)
                        }
                    }
                
                Circle()
                    .frame(width: configuration.isOn ? (width / 2) - 2 : width / 3)
                    .padding(configuration.isOn ? 2 : 4)
                    .foregroundColor(configuration.isOn ? .white : .mediumGray)
                    .onTapGesture {
                        withAnimation {
                            configuration.$isOn.wrappedValue.toggle()
                        }
                    }
            }
        }
    }
}



struct BatteryView: View {
    let battery: Float?
    
    var body: some View {
        if let battery {
            var batteryPercent: Int {
                let batt = Int((battery - 3.3) / 0.7 * 100)
                if batt > 100 {
                    return 100
                } else if batt < 0 {
                    return 0
                } else {
                    return batt
                }
            }
            if battery < 3 {
                Image(systemName: "info.circle")
                    .foregroundStyle(.mainRed)
                    .frame(width: 16, height: 16)
            } else {
                let batteryLow: Bool = battery < 3.4
                HStack(spacing: 0){
                    ZStack(alignment: .center){
                        ZStack(alignment: .leading){
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(batteryLow ? .mainRed : .deepDarkGray, lineWidth: 1)
                                .frame(width: 24, height: 13)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(batteryLow ? .white : .gray)
                                .frame(width: 23.5, height: 12)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .frame(width: CGFloat(24*batteryPercent/100), height: 13)
                                .foregroundColor(batteryLow ? .mainRed : .deepDarkGray)
                        }
                        Text("\(batteryPercent)")
                            .font(.labelLarge())
                            .foregroundColor(batteryLow ? .mainRed : .white)
                            .onAppear(perform: {
                                print("batt = \(battery), battInt = \((battery - 3.3) / 0.7 * 100)")
                            })
                    }
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width:2, height:5)
                        .foregroundColor(batteryLow ? .mainRed : .deepDarkGray)
                }
            }
        }
    }
}

struct LogTutorialInfoText: View {
    let isTutorial: Bool
    var body: some View {
        if isTutorial {
            HStack {
                Image(systemName: "info.circle")
                Text("이해를 돕기 위한 예시 자료입니다. 운동 후 성장을 확인하세요!")
            }
            .padding(.horizontal, 10)
        }
    }
}


struct okButton: View{
    var name: String = "확인"
    var action: () -> Void
    var enable: Bool = true
    
    var body: some View{
        Button(action: {
            action()
        }, label: {
            HStack{
                Spacer()
                Text(name)
                    .font(.m_18())
                    .foregroundStyle(enable ? .white : .lightGraySet)
                Spacer()
            }
        })
        .frame(height: 60)
        .background(enable ? .black : .whiteGray)
        .cornerRadius(10)
        .disabled(!enable)
    }
}

struct twoButton: View{
    var geometry: GeometryProxy
    var leftName: String
    var leftAction: () -> Void
    var rightName: String
    var rightAction: () -> Void
    
    var enable: Bool = true
    
    var body: some View{
        HStack{
            Button(action: {
                leftAction()
            }, label: {
                HStack{
                    Spacer()
                    Text(leftName)
                        .font(.m_18())
                        .foregroundStyle(enable ? .lightGraySet : .white)
                    Spacer()
                }
                .padding(18)
            })
            .background(.whiteGray)
            .cornerRadius(5)
            .frame(width: geometry.size.width * 133 / 393)
            .disabled(!enable)
            
            Button(action: {
                rightAction()
            }, label: {
                HStack{
                    Spacer()
                    Text(rightName)
                        .font(.m_18())
                        .foregroundStyle(enable ? .white : .lightGraySet)
                    Spacer()
                }
                .padding(18)
            })
            .background(.lightBlack)
            .cornerRadius(5)
            .disabled(!enable)
        }
    }
}

enum TestType: String, Equatable{
    case SPINE = "척추근 평가"
    case FUNC = "기능 평가"
    case EXER = "운동 평가"
    case BRIEF = "자율 측정"
}


struct ReportType: Equatable, Hashable {
    let testType: TestType
    let exid: Int
    var name: String
}

struct Arrow: Shape {
    var width: CGFloat
    var height: CGFloat
    var direction: ArrowDirection
    
    enum ArrowDirection {
        case left, right
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arrowWidth: CGFloat = height * 20 / 19
        let arrowHeight: CGFloat = height * 30 / 19
        let rectWidth = width - arrowWidth
        let rectHeight = height
        
        switch direction {
        case .right:
            path.move(to: CGPoint(x: 0, y: (rect.height - rectHeight) / 2))
            path.addLine(to: CGPoint(x: rectWidth, y: (rect.height - rectHeight) / 2))
            path.addLine(to: CGPoint(x: rectWidth, y: rect.midY - arrowHeight / 2))
            path.addLine(to: CGPoint(x: rectWidth + arrowWidth, y: rect.midY))
            path.addLine(to: CGPoint(x: rectWidth, y: rect.midY + arrowHeight / 2))
            path.addLine(to: CGPoint(x: rectWidth, y: (rect.height + rectHeight) / 2))
            path.addLine(to: CGPoint(x: 0, y: (rect.height + rectHeight) / 2))
            path.closeSubpath()
        case .left:
            path.move(to: CGPoint(x: arrowWidth + rectWidth, y: (rect.height - rectHeight) / 2))
            path.addLine(to: CGPoint(x: arrowWidth, y: (rect.height - rectHeight) / 2))
            path.addLine(to: CGPoint(x: arrowWidth, y: rect.midY - arrowHeight / 2))
            path.addLine(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: arrowWidth, y: rect.midY + arrowHeight / 2))
            path.addLine(to: CGPoint(x: arrowWidth, y: (rect.height + rectHeight) / 2))
            path.addLine(to: CGPoint(x: arrowWidth + rectWidth, y: (rect.height + rectHeight) / 2))
            path.closeSubpath()
        }
        
        return path
    }
}


struct CustomSegmentedPicker: View {
    
    @Binding public var selection: Int
    
    private let size: CGSize
    private let segmentLabels: [String]
    var pad: CGFloat = 4
    
    var body: some View {
        
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: size.width, height: size.height)
                .foregroundColor(.whiteGray)
            
            RoundedRectangle(cornerRadius: 10)
                .padding(pad)
                .frame(width: segmentWidth(size), height: size.height)
                .foregroundColor(.white)
                .offset(x: calculateSegmentOffset(size))
            
            HStack(spacing: 0) {
                ForEach(0..<segmentLabels.count, id: \.self) { idx in
                    SegmentLabel(title: segmentLabels[idx], width: segmentWidth(size))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selection = idx
                            }
                        }
                }
            }
        }
    }
    
    public init(selection: Binding<Int>, size: CGSize, segmentLabels: [String]) {
        self._selection = selection
        self.size = size
        self.segmentLabels = segmentLabels
    }
    
    private func segmentWidth(_ mainSize: CGSize) -> CGFloat {
        var width = (mainSize.width / CGFloat(segmentLabels.count))
        if width < 0 {
            width = 0
        }
        return width
    }
    
    private func calculateSegmentOffset(_ mainSize: CGSize) -> CGFloat {
        return (segmentWidth(mainSize)) * CGFloat(selection)
    }
    
    fileprivate struct SegmentLabel: View {
        let title: String
        let width: CGFloat
        
        var body: some View {
            
            Text(title)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: false)
                .font(.r_12())
                .foregroundColor(.lightBlack)
                .frame(width: width)
                .contentShape(Rectangle())
        }
    }
}

struct ThickDivider: View{
    var height: CGFloat = 16
    
    var body: some View{
        Rectangle()
            .frame(height: height)
            .foregroundStyle(.backgroundGray)
    }
}


struct ChatBubbleTopTriangle: View {
    
    let backgroundColor: Color
    let text: String
    var width: CGFloat = 200
    let triangleOffset: CGFloat
    var body: some View {
        
        ZStack(alignment: .bottomLeading){
            Triangle()
                .fill(backgroundColor)
                .frame(width: 70, height: 55)
                .offset(x: triangleOffset)
            RoundedRectangle(cornerRadius: 5)
                .frame(width: width, height: 42)
                .foregroundStyle(backgroundColor)
                .overlay {
                    Text(text)
                        .font(.m_14())
                        .foregroundStyle(backgroundColor == .whiteGray ? .black : .white)
                }
        }
    }
}









#Preview{
    VStack {
        ChatBubbleTopTriangle(
            backgroundColor: .mainBlue,
            text: "여기를 눌러 기기를 연결해주세요",
            width: 230,
            triangleOffset: 130
        )
    }
}
