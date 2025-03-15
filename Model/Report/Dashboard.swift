//
//  Dashboard.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 8/21/24.
//

import Foundation

struct DashboardDTO: Equatable {
    let who: String
    let time: Int
    let totTime: Int
    let st: Bool
    let ft: Bool
    let dashboardET: DashboardETDTO?
    let bt: Bool
    
    var reportSTs: [ReportST]?
    var reportFTs: [ReportFTDTO]?
    var reportETs: [ReportETDTO]?
    var reportBTs: [ReportBTDTO]?
    
    static func fromEntity(entity: DashboardEntity, reportSTs: [ReportST], reportFTs: [ReportFTDTO], reportETs: [ReportETDTO], reportBTs: [ReportBTDTO]) -> DashboardDTO {
        return DashboardDTO(
            who: entity.who,
            time: entity.time,
            totTime: entity.totTime,
            st: entity.st,
            ft: entity.ft,
            dashboardET: DashboardETDTO.fromEntity(entity: entity.et),
            bt: entity.bt ?? false,
            reportSTs: reportSTs,
            reportFTs: reportFTs,
            reportETs: reportETs,
            reportBTs: reportBTs
        )
    }
}

struct DashboardETDTO: Equatable {
    let averageScore: Float
    let totalWeight: Int
    let bestId: Int
    let bestScore: Float
    let worstId: Int
    let worstScore: Float
    
    static func fromEntity(entity: DashboardETEntity?) -> DashboardETDTO? {
        guard let entity else { return nil }
        return DashboardETDTO(
            averageScore: entity.averScr,
            totalWeight: entity.totWei,
            bestId: entity.bstId,
            bestScore: entity.bstScr,
            worstId: entity.wstId,
            worstScore: entity.wstScr
        )
    }
}


struct DashboardEntity: Equatable, Codable {
    let who: String
    let time: Int
    let totTime: Int
    let st: Bool
    let ft: Bool
    let et: DashboardETEntity?
    var bt: Bool?
}

struct DashboardETEntity: Equatable, Codable {
    let averScr: Float
    let totWei: Int
    let bstId: Int
    let bstScr: Float
    let wstId: Int
    let wstScr: Float
}
