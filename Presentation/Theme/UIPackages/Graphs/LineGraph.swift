//
//  LineGraph.swift
//  WorkwayVer2
//
//  Created by loyH on 7/5/24.
//

import Foundation
import SwiftUI
import Charts

struct LineGraph: View{
    var title: String?
    var unit: String?
    var labels: [String]
    var subLabels: [String]?
    var scores: [Float]
    
    var minStandard: Float?
    var maxStandard: Float?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            if let title = title {
                HStack(spacing: 2){
                    Text(title)
                        .font(.m_14())
                        .foregroundStyle(.lightBlack)
                    if let unit = unit {
                        Text("(\(unit))")
                            .font(.m_12())
                            .foregroundStyle(.darkGraySet)
                    }
                }
            }
            
            let spare = (scores.max()! - scores.min()!) * 0.2
            let minData = scores.min()!-spare
            let maxData = scores.max()!+spare
            
            GeometryReader{ geometry in
                Chart {
                    if let minStandard = minStandard, let maxStandard = maxStandard {
                        ForEach(0..<labels.count, id: \.self) { index in
                            AreaMark(
                                x: .value("Labal", String(format: "%02d", index) + labels[index]),
                                yStart: .value("Min", min(maxData - (spare / 2), max(minData, minStandard))),
                                yEnd: .value("Max", max(minData + (spare / 2), min(maxData, maxStandard)))
                            )
                            .foregroundStyle(.mainBlue)
                            .opacity(0.1)
                        }
                    }
                    
                    ForEach(0..<labels.count, id: \.self) { index in
                        LineMark(
                            x: .value("Label", String(format: "%02d", index) + labels[index]),
                            y: .value("Score", scores[index])
                        )
                        .foregroundStyle(.whiteGray)
                        .lineStyle(StrokeStyle(lineWidth: 4))
                    }
                    
                    ForEach(0..<labels.count, id: \.self) { index in
                        PointMark(
                            x: .value("Label", String(format: "%02d", index) + labels[index]),
                            y: .value("Score", scores[index])
                        )
                        .symbol(Circle())
                        .foregroundStyle(.lightBlack)
                        .symbolSize(30)
                        .annotation(position: .top) {
                            Text(String(format: "%.2f", scores[index]))
                                .font(.body_M_medium())
                                .foregroundStyle(.darkGraySet)
                                .fixedFont()
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks() { value in
                        AxisGridLine(centered: true)
                        AxisValueLabel {
                            VStack(spacing: 0){
                                Spacer().frame(height: 5)
                                Text(labels[value.index])
                                    .font(.body_M_medium())
                                    .foregroundStyle(.deepDarkGray)
                                    .fixedFont()
                                if let subLabels = subLabels{
                                    Spacer().frame(height: 2)
                                    Text(subLabels[value.index])
                                        .font(.body_M_medium())
                                        .foregroundStyle(.mediumGray)
                                        .fixedFont()
                                }
                            }
                        }
                        
                    }
                }
                .chartYScale(domain: minData...maxData)
                .chartYAxis {
                    AxisMarks(values: [minData]){
                        AxisGridLine()
                    }
                }
            }
        }
    }
    
}
