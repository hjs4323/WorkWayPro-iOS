//
//  RadarGraph.swift
//  WorkwayVer2
//
//  Created by loyH on 7/5/24.
//

import Foundation
import SwiftUI

struct RadarChart: View {
    let data: [Double]
    var lastAvg: Double?

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height)
            let height = width
            let radius = width / 3
            let levels: Int = 10
            let angleOffset = -Double.pi / 2 // 중앙에 맞추기 위해 시작 각도를 조정
            let avg = Double(data.reduce(into:0) {$0 += $1}) / Double(data.count)
            let labels = (lastAvg != nil) ? ["부위 적합성", "오른쪽", "수축-이완비", "긴장도", "왼쪽"] : ["부위 적합성", "최대 활성도", "수축-이완비", "긴장도", "좌우 균형"]
            
            ZStack(alignment: .center){
                ZStack(alignment: .center) {
                    ForEach(3..<levels) { level in
                        let ratio = Double(level + 1) / Double(levels)
                        let path = PolygonPath(sides: data.count, radius: radius * ratio, angleOffset: angleOffset)
                        if(level == 6){
                            path.stroke(.whiteLightGray, lineWidth: 1)
                        }
                        else{
                            path.stroke(.whiteGray, lineWidth: 1)
                        }
                    }
                    
                    let dataPath = PolygonPath(sides: data.count, radiusRatios: data.map { $0 / 100.0 }, maxRadius: radius, angleOffset: angleOffset)
                    if(avg < 50){
                        dataPath.fill(.lightGraySet)
                    }
                    else{
                        dataPath.fill(.graphBlue)
                    }
                    
                    VStack{
                        if(lastAvg == nil){
                            Text("총합")
                                .font(.s_14())
                                .foregroundStyle(.white)
                        }
                        else{
                            HStack(spacing:1){
                                Text(String(Int(avg)))
                                    .font(.s_14())
                                    .foregroundStyle(.white)
                                Text("점")
                                    .font(.r_12())
                                    .foregroundStyle(.white)
                            }
                            HStack(spacing:2){
                                if(lastAvg! > avg){
                                    Text("+")
                                        .font(.r_10())
                                        .foregroundStyle(.white)
                                }
                                else{
                                    Text("+")
                                        .font(.r_10())
                                        .foregroundStyle(.white)
                                }
                                Text(String(Int(abs(lastAvg! - avg))))
                                    .font(.r_10())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    
                    
                    
                    LabelMark(data: data, labels: labels, radius: radius + 40, angleOffset: angleOffset)
                    
                }
                .frame(width: radius * 2 + 80, height: radius * 2 + 80)
            }
            .padding()
            .frame(width: width, height: height)
        }
    }
}

struct LabelMark: View{
    let data: [Double]
    let labels: [String]
    let radius: Double
    let angleOffset: Double // 중앙에 맞추기 위해 시작 각도를 조정
    
    var body: some View{
        ZStack{
            ForEach(0..<data.count) { index in
                let angle = Double(index) * (360.0 / Double(data.count)) * .pi / 180 + angleOffset
                let x: CGFloat = (radius + 5) * cos(angle) + radius
                let y: CGFloat = (radius) * sin(angle) + radius + 5
                
                
                VStack(spacing: 6){
                    Text(labels[index])
                        .foregroundStyle(.lightGraySet)
                        .font(.s_12())
                    if(labels[index] == "왼쪽" || labels[index] == "오른쪽"){
                        if(data[index] >= 50){
                            Text("STRONG")
                                .font(.s_14())
                                .foregroundStyle(.mainBlue)
                        }
                        else{
                            Text("WEAK")
                                .font(.s_14())
                                .foregroundStyle(.darkGraySet)
                        }
                    }
                    else{
                        if(data[index] >= 60){
                            Text("적절")
                                .font(.s_14())
                                .foregroundStyle(.mainBlue)
                        }
                        else{
                            Text("주의")
                                .font(.s_14())
                                .foregroundStyle(.darkGraySet)
                        }
                    }
                    
                }
                .position(x: x, y: y)
            }
        }
    }
}

struct PolygonPath: Shape {
    var sides: Int
    var radius: Double
    var radiusRatios: [Double]?
    var maxRadius: Double?
    var angleOffset: Double
    
    init(sides: Int, radius: Double, angleOffset: Double) {
        self.sides = sides
        self.radius = radius
        self.angleOffset = angleOffset
    }
    
    init(sides: Int, radiusRatios: [Double], maxRadius: Double, angleOffset: Double) {
        self.sides = sides
        self.radiusRatios = radiusRatios
        self.maxRadius = maxRadius
        self.radius = maxRadius
        self.angleOffset = angleOffset
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        var path = Path()
        
        for i in 0..<sides {
            let angle = Double(i) * (360.0 / Double(sides)) * .pi / 180 + angleOffset
            let radius = radiusRatios != nil ? (radiusRatios![i] * maxRadius!) : self.radius
            let point = CGPoint(x: center.x + CGFloat(radius * cos(angle)), y: center.y + CGFloat(radius * sin(angle)))
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}


#Preview {
    ZStack{
        VStack{
            RadarChart(
                data: [50, 70, 30, 90, 60]
            ).frame(width: 300, height: 300)
            Spacer()
        }
    }
}





