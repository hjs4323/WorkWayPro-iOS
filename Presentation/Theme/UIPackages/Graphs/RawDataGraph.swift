//
//  RawDataGraph.swift
//  WorkwayVer2
//
//  Created by loyH on 7/8/24.
//

import Foundation
import SwiftUI
import Charts

struct RawDataGraph: View {
    let names: [String]
    let rawDatas: [[Float]]
    var colors: [Color] = [.workwayBlue, .red, .green, .purple, .brown, .orange, .whiteLightGray, .black]
    
    var standard: [Float]?
    
    var minData: Float
    var maxData: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Chart(0..<(rawDatas.map { $0.count }.max() ?? 0), id: \.self) { index in
                    if let first = standard?.first, let last = standard?.last {
                        AreaMark(
                            x: .value("Label", index),
                            yStart: .value("Min", min(maxData - 2, max(minData, first))),
                            yEnd: .value("Max", max(minData + 2, min(maxData, last)))
                        )
                        .foregroundStyle(.mainBlue)
                        .opacity(0.1)
                    }
                    
                    ForEach(0..<names.count, id: \.self) { i in
                        if let y = rawDatas[i][safe: index] {
                            LineMark(
                                x: .value("Time", index),
                                y: .value("RawData", y)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(colors[i])
                            .foregroundStyle(by: .value("Type", names[i]))
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                        }
                    }
                }
                .chartYScale(domain: minData...maxData)
                .chartXAxis { }
                .chartYAxis { }
                .chartLegend(position: .bottom, alignment: .center) { }
            }
        }
    }
}
