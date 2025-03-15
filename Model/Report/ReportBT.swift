//
//  ReportBT.swift
//  WorkwayVer2
//
//  Created by loyH on 9/13/24.
//

import Foundation
import SwiftUI

struct ReportBTDTO: Equatable {
    var reportId: String
    let who: String
    var name: String
    let dashboardTime: Int
    var setTimes: [Int]
    
    var muscleName: [String]
    var exerciseTime: Int
    var reportSets: [ReportBTSetDTO?]
    
    mutating func addReportSet(rSet: ReportBTSetDTO) {
        
        // reportSets 배열에서 nil 값을 찾음
        print("current reportSets = \(self.reportSets)")
        if let reportIndex = self.reportSets.firstIndex(of: nil) {
            // 해당 위치에 새로운 report 할당
            self.reportSets[reportIndex] = rSet
            self.reportSets.sort(by: { $0?.time ?? 0 < $1?.time ?? 1 })
            self.setTimes = self.reportSets.compactMap({ $0?.time })
            // exercisTime 값 재설정
            self.exerciseTime = self.reportSets.compactMap({ $0?.exerciseTime }).reduce(0, +)
            print("ReportBTDTO/addReportSet: done.")
            print("ReportBTDTO/addReportSet: setTimes = \(setTimes)")
            print("ReportBTDTO/addReportSet: exTime = \(exerciseTime)")
            print("ReportBTDTO/addReportSet: reportSetCount = \(reportSets.count)")
        }
    }
    
    static func fromEntity(reportId: String, entity: ReportBTEntity, rSets: [(String, ReportBTSetEntity)?]) -> ReportBTDTO {
        return ReportBTDTO(
            reportId: reportId,
            who: entity.who,
            name: entity.name,
            dashboardTime: entity.dshTime,
            setTimes: entity.setTime,
            muscleName: entity.msName.enumerated().map({ (index, name) in
                if name == nil {
                    return "\(index + 1)번 근육"
                } else {
                    return name!
                }
            }),
            exerciseTime: entity.exTime,
            reportSets: rSets.map({
                if let rSet = $0 {
                    return ReportBTSetDTO.fromEntity(reportSetId: rSet.0, who: entity.who, entity: rSet.1)
                } else {
                    return nil
                }
            })
        )
    }
    
    func toEntity() -> ReportBTEntity {
        return ReportBTEntity(
            who: self.who,
            name: self.name,
            dshTime: self.dashboardTime,
            setTime: self.setTimes,
            msName: self.muscleName,
            exTime: self.exerciseTime
        )
    }
}

struct ReportBTSetDTO: Equatable, Report {
    let reportBTId: String
    let reportId: String
    let who: String
    let time: Int
    let exerciseTime: Int
    
    var weight: Int?
    var count: Int?
    
    let topRaw: [Float]
    var top: [Float] {
        return topRaw.map({ valueToqV($0) })
    }
    
    let lowRaw: [Float]
    var low: [Float] {
        return lowRaw.map { valueToqV($0) }
    }
    
    var rawData: [[Float]]?
    
    static func fromEntity(reportSetId: String, who: String, entity: ReportBTSetEntity, rawData: [[Float]]? = nil) -> ReportBTSetDTO {
        return ReportBTSetDTO(
            reportBTId: entity.rptId,
            reportId: reportSetId,
            who: who,
            time: entity.stime,
            exerciseTime: entity.exTime,
            weight: entity.weight,
            count: entity.cnt,
            topRaw: entity.top,
            lowRaw: entity.low,
            rawData: rawData
        )
    }
    
    func toEntity() -> ReportBTSetEntity {
        return ReportBTSetEntity(
            rptId: self.reportBTId,
            stime: self.time,
            exTime: self.exerciseTime,
            weight: self.weight,
            cnt: self.count,
            top: self.topRaw,
            low: self.lowRaw
        )
    }
}

struct ReportBTEntity: Equatable, Codable {
    let who: String
    let name: String
    let dshTime: Int
    let setTime: [Int]
    
    let msName: [String?]
    let exTime: Int
}

struct ReportBTSetEntity: Equatable, Codable {
    let rptId: String
    let stime: Int
    let exTime: Int
    
    let weight: Int?
    let cnt: Int?
    
    let top: [Float]
    let low: [Float]
}

struct BTParam: Equatable, Codable {
    let maxBor: [Float]
    let meanBor: [Float]
}
