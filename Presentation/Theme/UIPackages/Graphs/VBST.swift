//
//  VBST.swift
//  UIpackage
//
//  Created by loyH on 7/2/24.
//


import Foundation
import SwiftUI

let ringColors: [Color] = [.workwayBlue, .mainRed, Color(red: 102/255, green: 204/255, blue: 51/255)]

struct VBST: Codable, Equatable {
    let volume: Int // 무게 * 횟수
    let balance: Int // leftBadCount*1000000 + rightBadCount*1000 + normalCount
    let score: Float // 점수
    let time: Int // 순 운동시간
}

extension VBST {
    func fromString(str: String) -> Self{
        let intList = str.split(separator: "/")
        return VBST(volume: Int(intList[0])!, balance: Int(intList[4])!, score: Float(intList[2])!, time: Int(intList[3])!)
    }
    
    static func acc(vbsts: [VBST]) -> Self{
        return VBST(
            volume: vbsts.map{$0.volume}.reduce(0, +),
            balance: vbsts.map{$0.balance}.reduce(0, +),
            score: vbsts.map{$0.score}.reduce(0.0, +)/Float(vbsts.count),
            time: vbsts.map{$0.time}.reduce(0, +)
        )
    }
}

struct VBSTBox: View {
    
    let score: Float?
    let volume: Int
    let exerciseTime: Int
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                VStack(alignment: .leading) {
                    Spacer()
                    Text("평균 점수")
                        .font(.headlineSmall())
                    HStack(alignment: .bottom, spacing: 0){
                        Text("\(score != nil ? String(Int(score!)) : "-")")
                            .font(.headline_L_semibold())
                            .foregroundStyle(ringColors[0])
                        Text("점")
                            .font(.r_14())
                            .foregroundStyle(ringColors[0])
                            .offset(x: 2, y: -4)
                    }
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text("총 무게")
                        .font(.headlineSmall())
                    HStack(alignment: .bottom, spacing: 0){
                        Text("\(volume)")
                            .font(.headline_L_semibold())
                            .foregroundStyle(ringColors[1])
                        Text("kg")
                            .font(.r_14())
                            .foregroundStyle(ringColors[1])
                            .offset(x: 2, y: -4)
                    }
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text("운동 시간")
                        .font(.headlineSmall())
                    HStack(alignment: .bottom, spacing: 0){
                        Text("\(exerciseTime / 60)")
                            .font(.headline_L_semibold())
                            .foregroundStyle(ringColors[2])
                        Text("분")
                            .font(.r_14())
                            .foregroundStyle(ringColors[2])
                            .offset(x: 2, y: -4)
                    }
                    Spacer()
                }//textbox
                Spacer()
                
                VBSTCircle(
                    score: score ?? 0,
                    volume: volume,
                    exerciseTime: exerciseTime
                )
                .frame(width: 140, height: 140)
            }
        }
    }
}

struct VBSTCircle: View {
    let score: Float
    let volume: Int
    let exerciseTime: Int
    
    var body: some View {
        GeometryReader { geo in
            let diameter = geo.size.width
            ZStack {
                Circle()
                    .stroke(ringColors[0], style: StrokeStyle(
                        lineWidth: diameter * 0.12,
                        lineCap: .round
                    ))
                    .frame(width: diameter)
                    .rotationEffect(.degrees(-90))
                    .opacity(0.2)
                Circle()
                    .trim(from: 0, to: CGFloat(score)/100)
                    .stroke(ringColors[0], style: StrokeStyle(
                        lineWidth: diameter * 0.12,
                        lineCap: .round
                    ))
                    .frame(width: diameter)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .stroke(ringColors[1], style: StrokeStyle(
                        lineWidth: diameter * 0.12,
                        lineCap: .round
                    ))
                    .frame(width: diameter * 0.74)
                    .rotationEffect(.degrees(-90))
                    .opacity(0.2)
                Circle()
                    .trim(from: 0, to: CGFloat(volume)/1000)
                    .stroke(ringColors[1], style: StrokeStyle(
                        lineWidth: diameter * 0.12,
                        lineCap: .round
                    ))
                    .frame(width: diameter * 0.74)
                    .rotationEffect(.degrees(-90))
                
                
                Circle()
                    .stroke(ringColors[2], style: StrokeStyle(
                        lineWidth: diameter * 0.12,
                        lineCap: .round
                    ))
                    .frame(width: diameter * 0.48)
                    .rotationEffect(.degrees(-90))
                    .opacity(0.2)
                Circle()
                    .trim(from: 0, to: CGFloat(exerciseTime) / 60/60)
                    .stroke(ringColors[2], style: StrokeStyle(
                        lineWidth: diameter * 0.12,
                        lineCap: .round
                    ))
                    .frame(width: diameter * 0.48)
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

struct CircleGraph: View {
    let data: Float?
    let maxData: Float
    let unit: String
    let color: Color
    
    var body: some View {
        GeometryReader{ geometry in
            Circle()
                .stroke(.whiteGray, style: StrokeStyle(
                    lineWidth: 5,
                    lineCap: .round
                ))
                .frame(width: geometry.size.width)
                .overlay{
                    Circle()
                        .trim(from: 0, to: CGFloat(1))
                        .stroke(color, style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        ))
                        .frame(width: geometry.size.width)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(x: -1)
                }
                .overlay{
                    HStack(spacing: 1){
                        Text(data != nil ? String(format: "%.2f", data!) : "-")
                            .font(.s_22())
                            .foregroundStyle(.lightBlack)
                        Spacer().frame(width: 1)
                        Text(unit)
                            .font(.r_12())
                            .foregroundStyle(.darkGraySet)
                            .offset(y: 3)
                    }
                }
        }
    }
}


#Preview {
    ZStack{
        VBSTBox(score: 80, volume: 500, exerciseTime: 1000)
    }
    .padding(30)
    
}
