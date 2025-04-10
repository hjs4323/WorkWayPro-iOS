//
//  MuscleView.swift
//  UIpackage
//
//  Created by loyH on 7/5/24.
//

import Foundation
import SwiftUI

struct MuscleBarGraph: View {
    var barSizes: [[Float]]?
    var colors: [[Color]]
    
    var barShape: BarShape = .RECT
    
    
    enum BarShape{
        case RECT
        case ARROW
    }
    
    var body: some View {
        GeometryReader{ geometry in
            let recIntervals: [CGFloat] = [3, 5, 10, 16, 25].map { $0 * geometry.size.height / 132 }
            let arrowIntervals: [CGFloat] = [3, 19, 22, 33, 43].map { $0 * geometry.size.height / 213 }
            
            let barHeight: CGFloat = geometry.size.height * 10 / 132
            
            HStack{
                Spacer()
                MuscleView(tabIndex: 1)
                    .overlay(alignment: .center){
                        HStack(alignment: .center, spacing: 8) {
                            VStack(alignment: .trailing, spacing: 0) {
                                let maxWidth: CGFloat = (geometry.size.width - 8) / 2
                                ForEach(0..<5){ i in
                                    let data: CGFloat = CGFloat(barSizes?[i][0] ?? 0.15)
                                    
                                    switch barShape {
                                    case .RECT:
                                        let barWidth: CGFloat = maxWidth * data
                                        
                                        Spacer().frame(width: maxWidth, height: recIntervals[i])
                                        Rectangle()
                                            .frame(width: barWidth, height: barHeight)
                                            .foregroundColor(colors[i][0])
                                    case .ARROW:
                                        let barWidth: CGFloat = maxWidth * CGFloat((data == 0) ? 0 : (data  > 0.9) ? 1 : (data < 0.05) ? 0.35 : (data * 0.65 / 0.85) + 0.3)
                                        
                                        Spacer().frame(width: maxWidth, height: arrowIntervals[i])
                                        if(barWidth == 0){
                                            Spacer().frame(height: barHeight)
                                        }
                                        else{
                                            Arrow(width: barWidth, height: barHeight, direction: .left)
                                                .fill(colors[i][0])
                                                .frame(width: barWidth, height: barHeight)
                                                .overlay{
                                                    HStack{
                                                        let percent: Int = Int(barSizes![i][0] * 100 * 0.4)
                                                        Text("\(percent)%")
                                                            .font(.r_12())
                                                            .foregroundStyle(.white)
                                                        Spacer()
                                                    }
                                                    .padding(.leading, 10)
                                                    .frame(width: barWidth)
                                                }
                                        }
                                    }
                                }
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                let maxWidth: CGFloat = (geometry.size.width - 8) / 2
                                ForEach(0..<5){ i in
                                    let data: CGFloat = CGFloat(barSizes?[i][1] ?? 0.15)
                                    
                                    switch barShape {
                                    case .RECT:
                                        let barWidth: CGFloat = maxWidth * data
                                        
                                        Spacer().frame(width: maxWidth, height: recIntervals[i])
                                        Rectangle()
                                            .frame(width: barWidth, height: barHeight)
                                            .foregroundColor(colors[i][1])
                                    case .ARROW:
                                        let barWidth: CGFloat = maxWidth * CGFloat((data == 0) ? 0 : (data  > 0.9) ? 1 : (data < 0.05) ? 0.35 : (data * 0.65 / 0.85) + 0.3)
                                        
                                        Spacer().frame(width: maxWidth, height: arrowIntervals[i])
                                        if(barWidth == 0){
                                            Spacer().frame(height: barHeight)
                                        }
                                        else{
                                            Arrow(width: barWidth, height: barHeight, direction: .right)
                                                .fill(colors[i][1])
                                                .frame(width: barWidth, height: barHeight)
                                                .overlay{
                                                    HStack{
                                                        let percent: Int = Int(barSizes![i][1] * 100 * 0.4)
                                                        Spacer()
                                                        Text("\(percent)%")
                                                            .font(.r_12())
                                                            .foregroundStyle(.white)
                                                    }
                                                    .padding(.trailing, 10)
                                                    .frame(width: barWidth)
                                                }
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                Spacer()
            }
        }
    }
}

struct MuscleSWView: View {
    let leftScore: Float
    let rightScore: Float
    
    let esStandard: [Float]
    let swStandard: [Float]
    
    let minScore: Float = 0
    let maxScore: [Float]
    
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
    
    
    var body: some View{
        GeometryReader { geometry in
            HStack{
                Text("좌")
                    .font(.body_M_medium())
                    .foregroundStyle(.darkGraySet)
                Spacer()
                
                MuscleView(tabIndex: 0, singleColor: .whiteGray, markRequired: false)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(alignment: .bottom){
                        HStack(alignment: .bottom, spacing: 0){
                            if let leftSWStandard = swStandard.first, let leftMaxScore = maxScore.first, let leftESStandard = esStandard.first {
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
                                Rectangle()
                                    .frame(height: geometry.size.height * CGFloat(min(1, max(0.1, leftScore / (leftMaxScore - minScore)))))
                                    .foregroundColor(leftSw.color)
                                    .opacity(0.3)
                                    .overlay(alignment: .center){
                                        VStack{
                                            Spacer()
                                            Text(leftSw.rawValue)
                                                .font(.s_20())
                                                .foregroundColor(leftSw.color)
                                            Spacer().frame(height: geometry.size.height * 30 / 231)
                                        }
                                    }
                            }
                            
                            if let rightSWStandard = swStandard.last, let rightMaxScore = maxScore.last, let rightESStandard = esStandard.last {
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
                                
                                Rectangle()
                                    .frame(height: geometry.size.height * CGFloat(min(1, max(0.1, rightScore / (rightMaxScore - minScore)))))
                                    .foregroundColor(rightSw.color)
                                    .opacity(0.3)
                                    .overlay(alignment: .center){
                                        VStack{
                                            Spacer()
                                            Text(rightSw.rawValue)
                                                .font(.s_20())
                                                .foregroundColor(rightSw.color)
                                            Spacer().frame(height: geometry.size.height * 30 / 231)
                                        }
                                    }
                            }
                        }
                    }
                
                Spacer()
                Text("우")
                    .font(.body_M_medium())
                    .foregroundStyle(.darkGraySet)
            }
        }
    }
}




struct MuscleView: View{
    var tabIndex: Int
    var colors: [Int: Color]?
    var singleColor: Color?
    var markRequired: Bool = false
    
    var body: some View{
        GeometryReader { upperGeometry in
            HStack {
                if(markRequired){
                    Text("좌")
                        .font(.body_M_medium())
                        .foregroundStyle(.darkGraySet)
                    
                    Spacer()
                }
                GeometryReader { geometry in
                    ZStack{
                        Image("muscles/\(bodies[tabIndex])")
                            .resizable()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        
                        ForEach(muscleViewImgs[self.tabIndex].indices, id: \.self) { index in
                            
                            let muscleId = MuscleNameIdMap[muscleViewImgs[tabIndex][index]] ?? 0
                            
                            let color : Color? =  colors?[muscleId] ?? singleColor
                            
                            Image("muscles/\(muscleViewImgs[tabIndex][index])")
                                .renderingMode((color != nil) ? .template : .original)
                                .resizable()
                                .muscleSizeMap(tabIndex * 10 + index, maxwidth: geometry.size.width, maxheight: geometry.size.width)
                                .foregroundStyle(color != nil ? AnyShapeStyle(color!) : AnyShapeStyle(Color.clear))
                                .muscleAlignMap(tabIndex * 10 + index, maxwidth: geometry.size.width, maxheight: geometry.size.height)
                        }
                    }//근육그림 ZStack
                }//근육그림 geometry
                .frame(width: min(upperGeometry.size.width, upperGeometry.size.height)  * (markRequired ? 0.7 : 1), height: min(upperGeometry.size.width, upperGeometry.size.height) * (markRequired ? 0.67 : 1))
                
                
                if(markRequired){
                    Spacer()
                    Text("우")
                        .font(.body_M_medium())
                        .foregroundStyle(.darkGraySet)
                }
            }
        }
        
    }
}


let muscleViewImgs: [[String]] = [
    ["frtrapezius", "fltrapezius", "frshoulder", "flshoulder", "frchest", "flchest", "frbicep", "flbicep"/*, "frabs", "flabs"*/],
    ["bllatissimusdorsi", "brlatissimusdorsi", "blshoulder", "brshoulder", "bltrapezius", "brtrapezius", "bltriceps", "brtriceps"]
]

extension View {
    func muscleAlignMap(_ muscleIndex: Int, maxwidth: CGFloat, maxheight: CGFloat) -> some View {
        switch muscleIndex {
            //전면
        case 0:
            return self.offset(x: maxwidth * 0.15, y: maxheight * -0.405)//오른승모
        case 1:
            return self.offset(x: maxwidth * -0.15, y: maxheight * -0.405)//왼승모
        case 2:
            return self.offset(x: maxwidth * 0.35, y: maxheight * -0.22)//오른어깨
        case 3:
            return self.offset(x: maxwidth * -0.35, y: maxheight * -0.22)//왼어깨
        case 4:
            return self.offset(x: maxwidth * 0.19, y: maxheight * -0.14)//오른가슴
        case 5:
            return self.offset(x: maxwidth * -0.19, y: maxheight * -0.14)//왼가슴
        case 6:
            return self.offset(x: maxwidth * 0.415, y: maxheight * 0.08)//오른이두
        case 7:
            return self.offset(x: maxwidth * -0.415, y: maxheight * 0.08)//왼이두
        case 8:
            return self.offset(x: maxwidth * 0.1, y: maxheight * 0.29)//오른복근
        case 9:
            return self.offset(x: maxwidth * -0.1, y: maxheight * 0.29)//왼복근
            //후면
        case 10:
            return self.offset(x: maxwidth * -0.2, y: maxheight * 0.175)//왼광배
        case 11:
            return self.offset(x: maxwidth * 0.2, y: maxheight * 0.175)//오른광배
        case 12:
            return self.offset(x: maxwidth * -0.35, y: maxheight * -0.22)//왼어깨
        case 13:
            return self.offset(x: maxwidth * 0.35, y: maxheight * -0.22)//오른어깨
        case 14:
            return self.offset(x: maxwidth * -0.15, y: maxheight * -0.405)//왼승모
        case 15:
            return self.offset(x: maxwidth * 0.15, y: maxheight * -0.405)//오른승모
        case 16:
            return self.offset(x: maxwidth * -0.425, y: maxheight * 0.085)//왼삼두
        case 17:
            return self.offset(x: maxwidth * 0.425, y: maxheight * 0.085)//오른삼두
            
            
        default:
            return self.offset()
        }
    }
    //241  236
    func muscleSizeMap(_ muscleIndex: Int, maxwidth: CGFloat, maxheight: CGFloat) -> some View {
        switch muscleIndex {
            //전면
        case 0, 1, 14, 15:
            return self.frame(width: maxwidth * 0.238, height: maxheight * 0.182)//승모
        case 2, 3, 12, 13:
            return self.frame(width: maxwidth * 0.264, height: maxheight * 0.292)//어꺠
        case 4, 5:
            return self.frame(width: maxwidth * 0.343, height: maxheight * 0.347)//가슴
        case 6, 7:
            return self.frame(width: maxwidth * 0.12, height: maxheight * 0.44)//이두
        case 8, 9:
            return self.frame(width: maxwidth * 0.148, height: maxheight * 0.405)//복근
            //후면
        case 10, 11:
            return self.frame(width: maxwidth * 0.238, height: maxheight * 0.643)//광배
        case 16, 17:
            return self.frame(width: maxwidth * 0.121, height: maxheight * 0.44)//삼두
            
        default:
            return self.frame(width: 0, height: 0)
        }
    }
}
