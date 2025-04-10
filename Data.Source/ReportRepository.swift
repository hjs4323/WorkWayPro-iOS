//
//  ReportRepository.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/24/24.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Dependencies

protocol ReportRepository {
    func getReportST(who: String, startUnixTime: Double?, endUnixTime: Double?) async throws -> [ReportST]
    func getReportFT(who: String, startUnixTime: Double?, endUnixTime: Double?, muscles: [MuscleDTO]?) async throws -> [ReportFTDTO]
    func getReportET(who: String, startUnixTime: Double?, endUnixTime: Double?, muscles: [MuscleDTO]) async throws -> [ReportETDTO]
    func getReportBT(who: String, startUnixTime: Double?, endUnixTime: Double?) async throws -> [ReportBTDTO]
    func getReportBTWithSet(who: String, startUnixTime: Double?, endUnixTime: Double?) async throws -> [ReportBTDTO]
    func getReportBTSet(who: String, startTime: Int, graphTogether: Bool, callBack: @escaping (ReportBTSetDTO) -> (), onFailure: @escaping () -> ()) async throws
    func getLastST(who: String, endUnixTime: Double?) async throws -> ReportST?
    func getLastFT(who: String, endUnixTime: Double?, muscles: [MuscleDTO]?) async throws -> ReportFTDTO?
    func getLastET(who: String, exerciseId: Int, endUnixTime: Int?, muscles: [MuscleDTO]) async throws -> ReportETDTO?
    func getLastETSet(who: String, exerciseId: Int, endUnixTime: Double?, muscles: [MuscleDTO]) async throws -> ReportETSetDTO?
    func getGraphData(dir: FBStorageDirs, who: String, time: Int, muscleCount: Int, callBack: @escaping ([[Float]]?) -> ())
    func getSTParams() async throws -> [STParam]?
    func getFTParam() async throws -> FTParam?
    func getETParam(exerciseId: Int) async throws -> ETParamDTO?
    func getBTParam() async throws -> BTParam?
    func uploadST(reportST: ReportST) throws
    func initReportET(reportET: ReportETDTO) async throws -> String
    func initReportBT(reportBT: ReportBTDTO) async throws -> String
    func setETWeightCount(setReportId: String, weight: Int, count: Int) async throws
    func setBTWeightCount(reportSetId: String, weight: Int?, count: Int?) async throws
    func setBTNames(reportBTId: String, muscleNames: [String]) async throws
    func setReportBT(reportBT: ReportBTDTO) async throws
    func getDashboards(who: String, startUnixTime: Int?, endUnixTime: Int?, muscles: [MuscleDTO]) async throws -> [DashboardDTO]
    func getDashboardCount(who: String) async throws -> Int 
}

struct ReportRepositoryImpl : ReportRepository{
    let fbStore = FbStore()
    let fbStorage = FbStorage()
    
    func getReportST(who: String, startUnixTime: Double?, endUnixTime: Double?) async throws -> [ReportST] {
        return try await fbStore.getReportST(who: who, startUnixTime: startUnixTime ?? 0, endUnixTime: endUnixTime ?? Date().timeIntervalSince1970)
    }
    
    func getReportFT(who: String, startUnixTime: Double?, endUnixTime: Double?, muscles: [MuscleDTO]?) async throws -> [ReportFTDTO] {
        let reportEntities = try await fbStore.getReportFT(who: who, startUnixTime: startUnixTime ?? 0, endUnixTime: endUnixTime ?? Date().timeIntervalSince1970)
        
        return reportEntities.map { rEntity in
            ReportFTDTO.fromEntity(entity: rEntity, muscles: muscles ?? totalMuscles)
        }
    }
    
    func getReportET(who: String, startUnixTime: Double?, endUnixTime: Double?, muscles: [MuscleDTO]) async throws -> [ReportETDTO] {
        let reportEntities = try await fbStore.getReportET(who: who, startUnixTime: startUnixTime ?? 0, endUnixTime: endUnixTime ?? Date().timeIntervalSince1970)
        
        return try await reportEntities.asyncMap { entity in
            let sets = try await fbStore.getReportETSet(reportId: entity.0)
            return ReportETDTO.fromEntity(reportId: entity.0, entity: entity.1, sets: sets, muscles: muscles)
        }
    }
    
    func getReportBT(who: String, startUnixTime: Double?, endUnixTime: Double?) async throws -> [ReportBTDTO] {
        let reportEntities = try await fbStore.getReportBT(who: who, startUnixTime: startUnixTime ?? 0, endUnixTime: endUnixTime ?? Date().timeIntervalSince1970)
        
        print("reportEntities = \(reportEntities)")
        
        return reportEntities.map { entity in
            let sets: [(String, ReportBTSetEntity)?] = entity.1.setTime.map({ _ in nil })
            return ReportBTDTO.fromEntity(reportId: entity.0, entity: entity.1, rSets: sets)
        }
    }
    
    func getReportBTSet(who: String, startTime: Int, graphTogether: Bool, callBack: @escaping (ReportBTSetDTO) -> (), onFailure: @escaping () -> ()) async throws {
        
        if let entity = try await fbStore.getReportBTSet(who: who, startUnixTime: Double(startTime), endUnixTime: Double(startTime)).first {
            if graphTogether {
                getGraphData(dir: .BTGRAPH, who: who, time: startTime, muscleCount: entity.1.top.count) { rawDatas in
                    callBack(ReportBTSetDTO.fromEntity(reportSetId: entity.0, who: who, entity: entity.1, rawData: rawDatas))
                }
            } else {
                callBack(ReportBTSetDTO.fromEntity(reportSetId: entity.0, who: who, entity: entity.1, rawData: nil))
            }
        } else {
            onFailure()
        }
    }
    
    func getReportBTWithSet(who: String, startUnixTime: Double?, endUnixTime: Double?) async throws -> [ReportBTDTO] {
        let reportEntities = try await fbStore.getReportBT(who: who, startUnixTime: startUnixTime ?? 0, endUnixTime: endUnixTime ?? Date().timeIntervalSince1970)
        
        return try await reportEntities.asyncMap { entity in
            let sets = try await fbStore.getReportBTSet(reportId: entity.0)
            return ReportBTDTO.fromEntity(reportId: entity.0, entity: entity.1, rSets: sets)
        }
    }
    
    func getLastST(who: String, endUnixTime: Double?) async throws -> ReportST? {
        return try await fbStore.getLastReportST(who: who, endUnixTime: endUnixTime ?? Date().timeIntervalSince1970)
    }
    
    func getLastFT(who: String, endUnixTime: Double?, muscles: [MuscleDTO]?) async throws -> ReportFTDTO? {
        return try await fbStore.getLastReportFT(who: who, endUnixTime: endUnixTime ?? Date().timeIntervalSince1970).map { rEntity in
            ReportFTDTO.fromEntity(entity: rEntity, muscles: muscles ?? totalMuscles)
        }
    }
    
    func getLastET(who: String, exerciseId: Int, endUnixTime: Int?, muscles: [MuscleDTO]) async throws -> ReportETDTO? {
        guard let entity = try await fbStore.getLastReportET(who: who, exerciseId: exerciseId, endUnixTime: endUnixTime ?? Int(Date().timeIntervalSince1970)) else { return nil }
        let sets = try await fbStore.getReportETSet(reportId: entity.0)
        return ReportETDTO.fromEntity(reportId: entity.0, entity: entity.1, sets: sets, muscles: muscles)
    }
    
    func getLastETSet(who: String, exerciseId: Int, endUnixTime: Double?, muscles: [MuscleDTO]) async throws -> ReportETSetDTO? {
        guard let entity = try await fbStore.getLastReportETSet(who: who, exerciseId: exerciseId, endUnixTime: endUnixTime ?? Date().timeIntervalSince1970) else { return nil }
        return ReportETSetDTO.fromEntity(reportSetId: entity.0, who: who, entity: entity.1, muscles: muscles)
    }
    
    func getGraphData(dir: FBStorageDirs, who: String, time: Int, muscleCount: Int, callBack: @escaping ([[Float]]?) -> ()) {
        print("ReportRepository/getGraphData: triggered")
        fbStorage.getGraphData(dir: dir, who: who, time: time) { data in
            let floatArr = data?.toFloatArray(arrayCount: muscleCount)
            print("ReportRepository/getGraphData: counts = \(floatArr.map({ $0.count }))")
            callBack(floatArr)
        }
    }
    
    func getSTParams() async throws -> [STParam]? {
        print("ReportRepository/getSTParams: triggered")
        guard let dict = try await fbStore.getSTParams() else { return nil }
        return dict.keys.map({ str in
            STParam(spineCode: str, values: dict[str]!)
        })
    }
    
    func getFTParam() async throws -> FTParam? {
        let param = try await fbStore.getFTParams()
        return param
    }
    
    func getETParam(exerciseId: Int) async throws -> ETParamDTO? {
        let entity = try await fbStore.getETParam(exerciseId: exerciseId)
        print("entity = \(entity)")
        return ETParamDTO.fromEntity(exid: exerciseId, entity: entity)
    }
    
    func getBTParam() async throws -> BTParam? {
        let testBTParam: BTParam = BTParam(maxBor: [1000, 500], meanBor: [400, 1000])
        return testBTParam // test
    }
    
    func uploadST(reportST: ReportST) throws {
        print("upload")
        try fbStore.uploadST(reportST: reportST)
    }
    
    func initReportET(reportET: ReportETDTO) async throws -> String {
        return try await fbStore.initReportET(reportETEntity: reportET.toEntity())
    }
    
    func initReportBT(reportBT: ReportBTDTO) async throws -> String {
        return try await fbStore.initReportBT(reportBTEntity: reportBT.toEntity())
    }
    
    func setETWeightCount(setReportId: String, weight: Int, count: Int) async throws {
        try await fbStore.setETWeightCount(setReportId: setReportId, weight: weight, count: count)
    }
    
    func setBTWeightCount(reportSetId: String, weight: Int?, count: Int?) async throws {
        try await fbStore.setBTWeightCount(reportSetId: reportSetId, weight: weight, count: count)
    }
    
    func setBTNames(reportBTId: String, muscleNames: [String]) async throws {
        let optinalNames: [String?] = muscleNames.enumerated().map { (index, name) in
            if name == "\(index + 1)번 근육" {
                return nil
            } else {
                return name
            }
        }
        try await fbStore.setBTMuscleName(reportBTId: reportBTId, muscleNames: optinalNames)
    }
    
    func setReportBT(reportBT: ReportBTDTO) async throws {
        try await fbStore.setReportBT(reportId: reportBT.reportId, reportBT: reportBT.toEntity())
    }
    
    func getDashboards(who: String, startUnixTime: Int?, endUnixTime: Int?, muscles: [MuscleDTO]) async throws -> [DashboardDTO] {
        let entities = try await fbStore.getDashboards(who: who, startUnixTime: startUnixTime ?? 0, endUnixTime: endUnixTime ?? Int(Date().timeIntervalSince1970))
        
        var dashboards: [DashboardDTO] = []
        
        for i in entities.indices {
            let entity = entities[i]
            let reportSTs = entity.st ? try await getReportST(who: who, startUnixTime: Double(entity.time), endUnixTime: Double(entity.time)) : []
            let reportFTs = entity.ft ? try await getReportFT(who: who, startUnixTime: Double(entity.time), endUnixTime: Double(entity.time), muscles: muscles) : []
            let reportETs = entity.et == nil ? [] : try await getReportET(who: who, startUnixTime: Double(entity.time), endUnixTime: Double(entity.time), muscles: muscles)
            let reportBTs = entity.bt == true ? try await getReportBTWithSet(who: who, startUnixTime: Double(entity.time), endUnixTime: Double(entity.time)) : []
            
            let dashboard = DashboardDTO.fromEntity(
                entity: entity,
                reportSTs: reportSTs,
                reportFTs: reportFTs,
                reportETs: reportETs,
                reportBTs: reportBTs
            )
            
            dashboards.append(dashboard)
        }
        
        dashboards.sort(by: { $0.time < $1.time})
        
        print("entities count = \(entities.count)")
        print("dshboard count = \(dashboards.count)")
        
        return dashboards.sorted(by: { $0.time > $1.time })
    }
    
    func getDashboardCount(who: String) async throws -> Int {
        return try await fbStore.getDashboardCount(who: who)
    }
}

enum ReportRepositoryKey: DependencyKey {
    static var liveValue: ReportRepository = ReportRepositoryImpl()
}

extension DependencyValues {
    var reportRepository: ReportRepository {
        get { self[ReportRepositoryKey.self] }
        set { self[ReportRepositoryKey.self] = newValue }
    }
}

