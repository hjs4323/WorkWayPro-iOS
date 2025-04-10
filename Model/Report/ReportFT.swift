//
//  ReportFT.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/24/24.
//

import Foundation

struct ReportFTDTO: Equatable, Report {
    let who: String
    let muscles: [MuscleDTO]
    let time: Int
    let dashboardTime: Int
    
    let corrScore: Float
    let crRates: [Float]
    
    static func fromEntity(entity: ReportFTEntity, muscles: [MuscleDTO]) -> ReportFTDTO {
        let muscleList = entity.mids.compactMap { mid in muscles.first { $0.id == mid } }
        return ReportFTDTO(
            who: entity.who,
            muscles: muscleList,
            time: entity.time,
            dashboardTime: entity.dshTime,
            corrScore: entity.corrScore,
            crRates: entity.crRates
        )
    }
    
    func toEntity() -> ReportFTEntity {
        return ReportFTEntity(
            who: self.who,
            mids: self.muscles.map({ $0.id }),
            time: self.time,
            dshTime: self.dashboardTime,
            corrScore: self.corrScore,
            crRates: self.crRates
        )
    }
}

struct ReportFTEntity: Equatable, Codable {
    let who: String
    let mids: [Int]
    let time: Int
    let dshTime: Int
    
    let corrScore: Float
    let crRates: [Float]
}

struct FTParam: Equatable, Codable {
    let crBorder: [Int: [Float]]
    let rawBorder: [Int: Float]
    let wsBorder: [Int: [Float]]
}
