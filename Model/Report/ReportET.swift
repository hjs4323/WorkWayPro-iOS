//
//  ReportET.swift
//  WorkwayVer2
//
//  Created by loyH on 8/14/24.
//

import Foundation
import SwiftUI

struct ReportETDTO: Equatable {
    var reportId: String
    let who: String
    let exerciseId: Int
    let dashboardTime: Int
    var exerciseTime: Int
    var reportSets: [ReportETSetDTO?]?
    
    static func fromEntity(reportId: String, entity: ReportETEntity, sets: [(String, ReportETSetEntity)]?, muscles: [MuscleDTO]) -> ReportETDTO {
        return ReportETDTO(
            reportId: reportId,
            who: entity.who,
            exerciseId: entity.exid,
            dashboardTime: entity.dshTime,
            exerciseTime: entity.exTime,
            reportSets: sets?.map({ ReportETSetDTO.fromEntity(reportSetId: $0.0, who: entity.who, entity: $0.1, muscles: muscles) })
        )
    }
    
    mutating func addReportSet(rSet: ReportETSetDTO) {
        // reportSets 배열에서 nil 값을 찾음
        print("addedReport")
        if let reportIndex = self.reportSets?.firstIndex(of: nil) {
            // 해당 위치에 새로운 report 할당
            self.reportSets?[reportIndex] = rSet
            // exercisTime 값 재설정
            self.exerciseTime = self.reportSets!.compactMap({ $0?.exTime }).reduce(0, +)
            print("ReportETDTO/addReportSet: done. reportSetCount = \(reportSets?.count)")
        }
    }
    
    func toEntity() -> ReportETEntity {
        return ReportETEntity(who: self.who, exid: self.exerciseId, dshTime: self.dashboardTime, exTime: self.exerciseTime)
    }
}

struct ReportETSetDTO: Equatable, Report  {
    let reportETId: String
    let reportId: String
    let who: String
    let time: Int
    let exTime: Int
    
    var weight: Int
    var repCount: Int
    var muscles: [MuscleDTO]
    
    let score: Float
    let activation: [Float]
    let mainMean: Float
    let mainMax: Float
    
    static func fromEntity(reportSetId: String, who: String, entity: ReportETSetEntity, muscles: [MuscleDTO]) -> ReportETSetDTO {
        let muscleList = entity.mids.compactMap { mid in muscles.first { $0.id == mid } }
        return ReportETSetDTO(
            reportETId: entity.rptId,
            reportId: reportSetId,
            who: who,
            time: entity.stime,
            exTime: entity.exTime,
            weight: entity.weight,
            repCount: entity.repCnt,
            muscles: muscleList,
            score: entity.scr,
            activation: entity.activ,
            mainMean: entity.mainMean,
            mainMax: entity.mainMax
        )
    }
    
    func toEntity() -> ReportETSetEntity {
        return ReportETSetEntity(
            rptId: self.reportETId,
            stime: self.time,
            exTime: self.exTime,
            weight: self.weight,
            repCnt: self.repCount,
            mids: self.muscles.map({ $0.id }),
            scr: self.score,
            activ: self.activation,
            mainMax: self.mainMax,
            mainMean: self.mainMean
        )
    }
}

struct ReportETEntity: Equatable, Codable  {
    let who: String
    let exid: Int
    let dshTime: Int
    let exTime: Int
}

struct ReportETSetEntity: Equatable, Codable  {
    let rptId: String
    let stime: Int //startTime
    let exTime: Int // 초 단위 총 운동 시간
    
    let weight: Int
    let repCnt: Int
    let mids: [Int]
    
    let scr: Float
    let activ: [Float]
    let mainMax: Float
    let mainMean: Float
}

struct ETParamEntity: Equatable, Codable {
    let activBor: [Int: [Float]]
    let mainMaxBor: [Float]
    let mainMeanBor: [Float]
    let rawBor: [Int: [Float]]
}

struct ETParamDTO: Equatable, Codable {
    let exid: Int
    let activBor: [Int: [Float]]
    let mainMaxBor: [Float]
    let mainMeanBor: [Float]
    let rawBor: [Int: [Float]]
    
    static func fromEntity(exid: Int, entity: ETParamEntity) -> ETParamDTO {
        return ETParamDTO(exid: exid, activBor: entity.activBor, mainMaxBor: entity.mainMaxBor, mainMeanBor: entity.mainMeanBor, rawBor: entity.rawBor)
    }
}
