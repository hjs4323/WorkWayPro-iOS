//
//  BarGraph.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/5/24.
//


import Foundation
import SwiftUI
import Charts

struct ActivationGraph: View {
    let activation: [Float]
    let muscles: [MuscleDTO]
    let activBorder: [Int: [Float]]
    
    var barWidth: CGFloat = 14
    
    var height: CGFloat?
    var width: CGFloat?
    
    let labelHeight: CGFloat = 45
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geometry in
                let chartMaxHeight: CGFloat = geometry.size.height - labelHeight
                
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0){
                        HStack{
                            Text("과다")
                                .frame(width: 40, height: chartMaxHeight / 3)
                                .font(.headlineSmall())
                                .foregroundStyle(.white)
                                .background(activColors[0])
                            Spacer()
                        }
                        HStack{
                            Text("적절")
                                .frame(width: 40, height: chartMaxHeight / 3)
                                .font(.headlineSmall())
                                .foregroundStyle(.white)
                                .background(activColors[1])
                            Spacer()
                        }.background(.whiteGray)
                        HStack{
                            Text("부족")
                                .frame(width: 40, height: chartMaxHeight / 3)
                                .font(.headlineSmall())
                                .foregroundStyle(.white)
                                .background(activColors[2])
                            Spacer()
                        }
                        Spacer().frame(height: labelHeight)
                    }
                    var colors: [Color]{
                        return activation.enumerated().map { (index, val) in
                            let mid = muscles[index].id
                            if let border = activBorder[mid] {
                                
                                if val < border[0] {
                                    return activColors[2]
                                } else if val < border[1] {
                                    return activColors[1]
                                } else {
                                    return activColors[0]
                                }
                            } else {
                                return .mediumGray
                            }
                        }
                    }
                    HStack {
                        Spacer().frame(width: 40)
                        var graphVal: [Float] {
                            return activation.enumerated().map { (index, val) in
                                let mid = muscles[index].id
                                if let border = activBorder[mid] {
                                    var chartHeight: Float = 0.0
                                    let maxHeight = Float(chartMaxHeight)
                                    
                                    let minValue: Float = 0
                                    let lowerBorder = border.first!
                                    let upperBorder = border[1]
                                    let maxValue = border.last!
                                    
                                    if val < lowerBorder {
                                        chartHeight = maxHeight / 3.0 * (val - minValue) / (lowerBorder - minValue)
                                        if chartHeight < 5.0 {
                                            chartHeight = 5.0
                                        }
                                    } else if val > upperBorder {
                                        chartHeight = maxHeight * 2.0 / 3.0 + maxHeight / 3.0 * (val - upperBorder) / (maxValue - upperBorder)
                                        if chartHeight > maxHeight {
                                            chartHeight = maxHeight
                                        }
                                    } else {
                                        chartHeight = maxHeight * 1.0 / 3.0 + maxHeight / 3.0 * (val - lowerBorder) / (upperBorder - lowerBorder)
                                    }
                                    
                                    return chartHeight / maxHeight
                                } else {
                                    return 0.05
                                }
                            }
                        }
                        BarGraph(
                            label: muscles.map{ $0.name },
                            subLabel: muscles.map{ $0.isLeft ? "좌" : "우" },
                            heightRatio: graphVal,
                            colors: colors,
                            barwidth: barWidth,
                            labelHeight: labelHeight,
                            selected: .constant(-1)
                        )
                        .frame(height: chartMaxHeight + labelHeight)
                    }
                }
            }//HStack
        }//GeometryReader
        .frame(height: height ?? 237)
    }
    
}

struct TwoBarGraph: View {
    var label : [String]
    var subLabel : [String]
    var score : [Float]
    var score2 : [Float]
    
    var barWidth: CGFloat = 20
    
    @Binding var select : Int
    
    var height: CGFloat?
    var width: CGFloat?
    
    var body: some View{
        VStack{
            let maxValue = (score + score2).max() ?? 100
            BarGraph(
                label: label,
                subLabel: subLabel,
                heightRatio: score.map({ $0 / maxValue }),
                values: score,
                colors: Array(repeating: .mainBlue, count: label.count),
                heightRatio2: score2.map({ $0 / maxValue }),
                values2: score2,
                colors2: Array(repeating: .darkGraySet, count: label.count),
                barwidth: barWidth,
                selected: $select,
                scoreRequired: true
            )
            .frame(width: width, height: height)
        }
        
    }
}

struct ClickBarGraph: View {
    var label : [String]
    var subLabel : [String]
    var score : [Float]
    var color: Color
    
    var barWidth: CGFloat = 20
    
    @Binding var select : Int
    
    var height: CGFloat?
    var width: CGFloat?
    
    var body: some View {
        VStack{
            let maxValue = score.max() ?? 100
            BarGraph(
                label: label,
                subLabel: subLabel,
                heightRatio: score.map({ $0 / maxValue }),
                values: score,
                colors: Array(repeating: color, count: label.count),
                barwidth: barWidth,
                selected: $select,
                scoreRequired: true
            )
            .frame(width: width, height: height)
        }
    }
}


struct LineAndBarGraph: View{
    var label : [String]
    var subLabel : [String]
    var score : [Float]
    var border: Float
    
    @Binding var select : Int
    
    var barWidth: CGFloat = 28
    
    var height: CGFloat?
    var width: CGFloat?
    
    var body: some View{
        var colors : [Color] {
            score.map{ s in
                if s >= border{
                    return .buttonBlue
                }
                else{
                    return .darkGraySet
                }
            }
        }
        ZStack(alignment: .topLeading){
            let maxScore = score.max() ?? 100
            BarGraph(
                label: label,
                subLabel: subLabel,
                heightRatio: score.map({ $0 / maxScore }),
                values: score,
                colors: colors,
                barwidth: barWidth,
                selected: $select,
                lineGraphRequired: true,
                scoreRequired: true
            )
            .padding(.top, 20)
            .frame(width: width, height: height)
        }
    }
}

struct BarGraph: View {
    var label: [String]
    var subLabel: [String]
    var heightRatio: [Float]
    var values: [Float]?
    var colors: [Color]
    
    var heightRatio2: [Float]?
    var values2: [Float]?
    var colors2: [Color]?
    
    var barwidth : CGFloat
    var labelHeight: CGFloat = 40
    
    @Binding var selected: Int // 사용하지 않을때는 parent에서 .constant(-1) 전달
    var lineGraphRequired: Bool = false
    var scoreRequired: Bool = false
    
    let horizontalPadding: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            let maxHeight = (scoreRequired ? geometry.size.height - 10 : geometry.size.height) - labelHeight
            let maxWidth = geometry.size.width - horizontalPadding * 2
            VStack{
                HStack(alignment: .bottom, spacing: 0) {
                    Spacer().frame(width: horizontalPadding)
                    if(!(label.count == subLabel.count && label.count == heightRatio.count)){
                        Text("Error")
                        Text("label = \(label), count = \(label.count)")
                        Text("subLabel = \(subLabel), count = \(subLabel.count)")
                        Text("heightRatio = \(heightRatio), count = \(heightRatio.count)")
                    } else {
                        ForEach(label.indices, id: \.self){ i in
                            let height1: CGFloat = maxHeight * CGFloat(heightRatio[i])
                            Rectangle()
                                .frame(height: geometry.size.height)
                                .foregroundStyle(.clear)
                                .overlay(alignment: .bottom){
                                    HStack(alignment: .bottom, spacing: 4){
                                        Spacer()
                                        Rectangle()
                                            .frame(width: barwidth, height: height1)
                                            .padding(.bottom, labelHeight)
                                            .foregroundStyle(colors[i])
                                            .overlay(alignment: .top){
                                                if(scoreRequired){
                                                    Text("\(Int(values?[i] ?? 0.0 ))")
                                                        .font(.r_12())
                                                        .frame(width: 20)
                                                        .foregroundStyle(i == selected ? .lightBlack : .whiteLightGray)
                                                        .offset(y: -20)
                                                }
                                            }
                                            .opacity(
                                                (selected != -1 && selected != i) ? 0.2 : 1
                                            )
                                        
                                        if((heightRatio2) != nil){
                                            let height2 = maxHeight * CGFloat(Float(heightRatio2![i]))
                                            Rectangle()
                                                .frame(width: barwidth, height: height2)
                                                .padding(.bottom, labelHeight)
                                                .foregroundStyle((colors2?[i]) ?? colors[i])
                                                .overlay(alignment: .top){
                                                    if(scoreRequired){
                                                        Text("\(Int(values2![i]))")
                                                            .font(.r_12())
                                                            .frame(width: 20)
                                                            .foregroundStyle(i == selected ? .lightBlack : .whiteLightGray)
                                                            .offset(y: -20)
                                                    }
                                                }
                                                .opacity(
                                                    (selected != -1 && selected != i) ? 0.2 : 1
                                                )
                                        }
                                        Spacer()
                                    }
                                    .onTapGesture {
                                        if self.selected != -1{
                                            self.selected = i
                                            print(maxHeight * CGFloat(heightRatio[i]))
                                            print(selected)
                                        }
                                    }
                                }
                                .overlay(alignment: .bottom) {
                                    Divider().foregroundStyle(.whiteGray)
                                        .padding(.bottom, labelHeight)
                                    VStack(spacing: 0){
                                        if subLabel[i] == "좌" || subLabel[i] == "우" {
                                            Spacer().frame(height: 1)
                                            Text(subLabel[i])
                                                .font(.s_10())
                                                .foregroundStyle(.mediumGray)
                                            Spacer().frame(height: 1)
                                        }
                                        var name: String {
                                            var temp = label[i]
                                            if temp.contains(where: { $0 == "근"}), let index = temp.lastIndex(where: { $0 == "근"}) {
                                                temp.remove(at: index)
                                            }
                                            return temp
                                        }
                                        var subMainName: [String] {
                                            var temp = name.split(separator: " ")
                                            if let first = temp.first, first.first?.isLetter == true && first.count > 3 {
                                                temp[0] = first.dropLast(first.count - 3)
                                            }
                                            return temp.map({ String($0) })
                                        }
                                        
                                        if subMainName.count > 1 {
                                            
                                            Text(subMainName[1])
                                                .font(.m_12())
                                                .foregroundStyle(.deepDarkGray)
                                            Text("(\(subMainName[0]))")
                                                .font(.m_10())
                                                .foregroundStyle(.lightGraySet)
                                        } else {
                                            Text(subMainName[0])
                                                .font(.m_12())
                                                .foregroundStyle(.deepDarkGray)
                                            if subLabel[i] == "좌" || subLabel[i] == "우" {
                                                Text("(공백)")
                                                    .font(.m_10())
                                                    .foregroundStyle(.clear)
                                            }
                                        }
                                        
                                        Spacer().frame(height: 1)
                                        
                                        if subLabel[i] != "좌" && subLabel[i] != "우" {
                                            Spacer().frame(height: 1)
                                            Text(subLabel[i])
                                                .font(.body_M_medium())
                                                .foregroundStyle(.mediumGray)
                                        }
                                    }
                                }
                        }
                    }
                    Spacer().frame(width: horizontalPadding)
                }
                .overlay {
                    if lineGraphRequired {
                        let interval: CGFloat = (maxWidth) / CGFloat(heightRatio.count)
                        let xStart:CGFloat = interval / CGFloat(2) + horizontalPadding
                        let yStart:CGFloat = maxHeight - maxHeight * CGFloat(heightRatio[0]) + 10
                        
                        Path { path in
                            path.move(to: CGPoint(x: xStart,
                                                  y: yStart))
                            for j in 1..<heightRatio.count{
                                let x = interval * CGFloat(j) + xStart
                                let y = maxHeight - (maxHeight * CGFloat(heightRatio[j])) + 10
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(lineWidth: 1.5)
                        .fill(.lightGraySet)
                    }
                }
                .overlay(alignment: .topLeading){
                    if lineGraphRequired {
                        let interval: CGFloat = (maxWidth) / CGFloat(heightRatio.count)
                        let xStart:CGFloat = interval / CGFloat(2) + horizontalPadding
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10, alignment: .top)
                            .overlay(
                                    Circle()
                                        .stroke(.lightGraySet, lineWidth: 2) // 테두리 색상 및 두께 설정
                                )
                            .offset(
                                x: xStart + interval * CGFloat(selected) - 5,
                                y: maxHeight - maxHeight * CGFloat(heightRatio[selected]) + 11 - 5
                            )
                        
                    }
                }
                Spacer().frame(height: 40)
            }
        }
    }
}


struct SingleBar: View{
    var title: String?
    let unit: String
    var compareUnit: String?
    var label: String?
    
    let score: Float
    var lastScore: Float? = nil
    
    var lastTime: String?
    
    var minScore: Float = 0
    var maxScore: Float = 100
    
    var standard: Float = 80    // 주의 적절 기준
    var UIStandard: Float?      // UI상 표시되는 기준
    
    var standard2: Float?
    var UIStandard2: Float?
    
    var description: String?
    var description2: String?
    
    var smallBar: Bool = false
    
    var body: some View{
        VStack(alignment: .leading, spacing: 0){
            if let title = title{
                HStack(spacing: 2) {
                    
                    Text(title)
                        .font(.m_18())
                        .foregroundStyle(.lightBlack)
                    if(title != "척추근 평가"){
                        Text("(\(unit))")
                            .font(.r_12())
                            .foregroundStyle(.darkGraySet)
                    }
                    Spacer()
                    if let label = label {
                        Text(label)
                            .font(.s_12())
                            .foregroundStyle(.lightBlack)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.whiteGray)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 0){
                Spacer().frame(height: 14)
                
                GeometryReader{ geometry in
                    VStack(alignment: .leading, spacing: 5){
                        HStack(alignment: .bottom, spacing: 0){
                            let barWidth: CGFloat =  smallBar ? geometry.size.width * 232 / 306 : geometry.size.width * 271 / 333
                            Text(String(Int(score)))
                                .font(.s_20())
                                .foregroundColor(.darkGraySet)
                            Spacer().frame(width: 4)
                            Text(unit)
                                .font(.r_12())
                                .foregroundColor(.darkGraySet)
                                .offset(y: -3)
                            Spacer()
                            var barValueWidth: CGFloat {
                                let tempWidth = barWidth / CGFloat(maxScore - minScore) * CGFloat(UIStandard == nil ? score : regulation(value: score, standard: standard, UIstandard: UIStandard!))
                                return tempWidth > barWidth ? barWidth : tempWidth
                            }
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: barWidth, height: 16)
                                .foregroundColor(.whiteGray)
                                .overlay(alignment: .leading){
                                    RoundedRectangle(cornerRadius: 5)
                                        .frame(width: barValueWidth, height: 16)
                                        .foregroundColor(.whiteLightGray)
                                }
                                .overlay{
                                    if(lastTime == nil){
                                        HStack(spacing: 0){
                                            Text("주의")
                                                .font(.r_10())
                                                .foregroundColor(.lightGraySet)
                                                .frame(width: barWidth / CGFloat(maxScore - minScore) * CGFloat(UIStandard ?? standard) - 2)
                                            Text("|")
                                                .font(.m_12())
                                                .foregroundColor(.darkGraySet)
                                                .offset(y: -6)
                                            
                                            if let standard2 = standard2 {
                                                Text("적절")
                                                    .font(.r_10())
                                                    .foregroundColor(.lightGraySet)
                                                    .frame(width: barWidth / CGFloat(maxScore - minScore) * CGFloat(standard2 - standard) - 2)
                                                Text("|")
                                                    .font(.m_12())
                                                    .foregroundColor(.darkGraySet)
                                                    .offset(y: -6)
                                            }
                                            
                                            Spacer()
                                            Text("\(standard2 == nil ? "적절" : "주의")")
                                                .font(.r_10())
                                                .foregroundColor(.lightGraySet)
                                            Spacer()
                                        }.offset(y: 20)
                                    }
                                    else{
                                        HStack{
                                            Spacer()
                                            Spacer()
                                            Text(lastTime!)
                                                .font(.r_12())
                                                .foregroundColor(.lightGraySet)
                                                .overlay{
                                                    Text("|")
                                                        .font(.r_10())
                                                        .foregroundColor(.darkGraySet)
                                                        .offset(y: 8.5)
                                                }
                                            Spacer()
                                        }.offset(y: -20)
                                    }
                                }
                        }
                        if let lastScore, let plusMinus = (score - lastScore >= 0) ? "+" : "-" {
                            Text("\(plusMinus) \(abs(Int(score - lastScore)))\(compareUnit ?? unit)")
                                .font(.r_10())
                                .padding([.top, .bottom], 5)
                                .padding([.leading], 6)
                                .padding([.trailing], 8)
                                .background(.whiteGray)
                                .cornerRadius(5)
                                .offset(x: 2)
                        }
                    }
                }
                .frame(height: 50)
                .padding(.trailing, smallBar ? 10 : 0)
                
                Spacer().frame(height: 10)
                
                if let description = description {
                    Text(description)
                        .font(.r_12())
                        .foregroundStyle(.darkGraySet)
                }
                if let description2 = description2 {
                    Text(description2)
                        .font(.r_12())
                        .foregroundStyle(.darkGraySet)
                }
            }
            .padding(.leading, smallBar ? 2 : 5)
        }
        
    }
    
    
    private func regulation(value: Float, standard: Float, UIstandard: Float) -> Float{
        let regulatedValue: Float = {
            if value < standard{
                return value / standard * UIstandard
            }
            else{
                return UIstandard + ((value - standard) / (maxScore - minScore - standard) * (maxScore - minScore - UIstandard))
            }
        }()
        print(regulatedValue)
        return regulatedValue
    }
}


struct SWBarGraph: View {
    let labels: [String]
    let scores: [[Float]]
    
    let esStandard: [[Float]]
    let swStandard: [[Float]]
    
    let minScore: Float = 0
    let maxScore: [[Float]]
    
    enum StrongWeak: String{
        case STRONG = "STRONG"
        case WEAK = "WEAK"
        case EXTREME = "EXTREME"
        
        var color: Color {
            switch self{
            case .STRONG:
                 return .mainBlue
            case .WEAK:
                return .darkGraySet
            case .EXTREME:
                return .extremePurple
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 25){
            ForEach(labels.indices){ index in
                HStack(spacing: 25){
                    Text(labels[index])
                        .font(.s_14())
                        .foregroundStyle(.lightBlack)
                        .frame(width: 100)
                    
                    
                    VStack(spacing: 8){
                        HStack(spacing: 16){
                            Text("(좌)")
                                .font(.m_12())
                                .foregroundStyle(.darkGraySet)
                            if let leftScore = scores[index].first, let leftSWStandard = swStandard[index].first, let leftMaxScore = maxScore[index].first, let leftESStandard = esStandard[index].first {
                                var leftSw: StrongWeak {
                                    if leftScore >= leftESStandard {
                                        return .EXTREME
                                    }
                                    else if leftScore >= leftSWStandard {
                                        return .STRONG
                                    }
                                    else{
                                        return .WEAK
                                    }
                                }
                                GeometryReader{ geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .foregroundStyle(leftSw.color)
                                            .opacity(0.3)
                                            .frame(width: (geometry.size.width - 10) * CGFloat(min(1, max(0.1, leftScore / (leftMaxScore - minScore)))), height: 10)
                                        HStack(spacing: 0){
                                            Spacer().frame(width: 10)
                                            Text(leftSw.rawValue)
                                                .font(.s_14())
                                                .foregroundColor(leftSw.color)
                                            Spacer()
                                        }
                                    }
                                }
                                .frame(height: 10)
                            }
                        }
                        
                        HStack(spacing: 16){
                            Text("(우)")
                                .font(.m_12())
                                .foregroundStyle(.darkGraySet)
                            if let rightScore = scores[index].last, let rightSWStandard = swStandard[index].last, let rightMaxScore = maxScore[index].last, let rightESStandard = esStandard[index].last {
                                var rightSw: StrongWeak {
                                    if rightScore >= rightESStandard {
                                        return .EXTREME
                                    }
                                    else if rightScore >= rightSWStandard {
                                        return .STRONG
                                    }
                                    else{
                                        return .WEAK
                                    }
                                }
                                GeometryReader{ geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .foregroundStyle(rightSw.color)
                                            .opacity(0.3)
                                            .frame(width: (geometry.size.width - 10) * CGFloat(min(1, max(0.1, rightScore / (rightMaxScore - minScore)))), height: 10)
                                        HStack(spacing: 0){
                                            Spacer().frame(width: 10)
                                            Text(rightSw.rawValue)
                                                .font(.s_14())
                                                .foregroundColor(rightSw.color)
                                            Spacer()
                                        }
                                    }
                                }
                                .frame(height: 10)
                            }
                        }
                    }
                }
                
            }
        }
        .overlay(alignment: .leading){
            Rectangle()
                .frame(width: 1, height: 220)
                .foregroundStyle(.whiteGray)
                .offset(x: 100)
        }
    }
}

