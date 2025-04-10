//
//  FbStore.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/24/24.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

enum FBStoreCollection: String {
    case Exercise = "ex"
    case Muscle = "mscl"
    case ST = "st"
    case FT = "ft"
    case ET = "et"
    case ETSet = "etset"
    case BT = "bt"
    case BTSet = "btset"
    case ReportParams = "reportParams"
    case Dashboard = "dshbrd"
}

struct FbStore {
    let store: Firestore = Firestore.firestore()
    
    func uploadST(reportST: ReportST) throws {
        try store.collection(FBStoreCollection.ST.rawValue)
            .document()
            .setData(from: reportST)
    }
    
    func initReportET(reportETEntity: ReportETEntity) async throws -> String {
        let document = store.collection(FBStoreCollection.ET.rawValue)
            .document()
        try document.setData(from: reportETEntity)
        return document.documentID
    }
    
    func initReportBT(reportBTEntity: ReportBTEntity) async throws -> String {
        let document = store.collection(FBStoreCollection.BT.rawValue)
            .document()
        try document.setData(from: reportBTEntity)
        return document.documentID
    }
    
    func getReportST(who: String, startUnixTime: Double, endUnixTime: Double) async throws -> [ReportST] {
        let snapshot = try await store
            .collection(FBStoreCollection.ST.rawValue)
            .whereField("who", isEqualTo: who)
            .whereField("dshTime", isGreaterThanOrEqualTo: startUnixTime)
            .whereField("dshTime", isLessThanOrEqualTo: endUnixTime)
            .order(by: "time")
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: ReportST.self) }
    }
    
    func getReportFT(who: String, startUnixTime: Double, endUnixTime: Double) async throws -> [ReportFTEntity] {
        let snapshot = try await store
            .collection(FBStoreCollection.FT.rawValue)
            .whereField("who", isEqualTo: who)
            .whereField("dshTime", isGreaterThanOrEqualTo: startUnixTime)
            .whereField("dshTime", isLessThanOrEqualTo: endUnixTime)
            .order(by: "time")
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: ReportFTEntity.self) }
    }
    
    func getReportET(who: String, startUnixTime: Double, endUnixTime: Double) async throws -> [(String, ReportETEntity)] {
        let snapshot = try await store
            .collection(FBStoreCollection.ET.rawValue)
            .whereField("who", isEqualTo: who)
            .whereField("dshTime", isGreaterThanOrEqualTo: startUnixTime)
            .whereField("dshTime", isLessThanOrEqualTo: endUnixTime)
            .order(by: "dshTime")
            .getDocuments()
        
        return snapshot.documents.compactMap {
            let id = $0.documentID
            guard let report = try? $0.data(as: ReportETEntity.self) else { return nil }
            
            return (id, report)
        }
    }
    
    func getReportETSet(reportId: String) async throws -> [(String, ReportETSetEntity)] {
        let snapshot = try await store
            .collection(FBStoreCollection.ETSet.rawValue)
            .whereField("rptId", isEqualTo: reportId)
            .order(by: "stime")
            .getDocuments()
        
        return snapshot.documents.compactMap {
            let id = $0.documentID
            guard let report = try? $0.data(as: ReportETSetEntity.self) else { return nil }
            
            return (id, report)
        }
    }
    
    func getReportBT(who: String, startUnixTime: Double, endUnixTime: Double) async throws -> [(String, ReportBTEntity)] {
        let snapshot = try await store
            .collection(FBStoreCollection.BT.rawValue)
            .whereField("who", isEqualTo: who)
            .whereField("dshTime", isGreaterThanOrEqualTo: startUnixTime)
            .whereField("dshTime", isLessThanOrEqualTo: endUnixTime)
            .order(by: "dshTime")
            .getDocuments()
        
        return snapshot.documents.compactMap {
            let id = $0.documentID
            guard let report = try? $0.data(as: ReportBTEntity.self) else { return nil }
            
            return (id, report)
        }
    }
    
    func getReportBTSet(who: String, startUnixTime: Double, endUnixTime: Double) async throws -> [(String, ReportBTSetEntity)] {
        let snapshot = try await store
            .collection(FBStoreCollection.BTSet.rawValue)
            .whereField("stime", isGreaterThanOrEqualTo: startUnixTime)
            .whereField("stime", isLessThanOrEqualTo: endUnixTime)
            .order(by: "stime")
            .getDocuments()
        
        return snapshot.documents.compactMap {
            let id = $0.documentID
            guard let report = try? $0.data(as: ReportBTSetEntity.self) else { return nil }
            
            return (id, report)
        }
    }
    
    func getReportBTSet(reportId: String) async throws -> [(String, ReportBTSetEntity)] {
        let snapshot = try await store
            .collection(FBStoreCollection.BTSet.rawValue)
            .whereField("rptId", isEqualTo: reportId)
            .order(by: "stime")
            .getDocuments()
        
        return snapshot.documents.compactMap {
            let id = $0.documentID
            guard let report = try? $0.data(as: ReportBTSetEntity.self) else { return nil }
            
            return (id, report)
        }
    }
    
    func getLastReportST(who: String, endUnixTime: Double) async throws -> ReportST? {
        let snapshot = try await store
            .collection(FBStoreCollection.ST.rawValue)
            .whereField("who", isEqualTo: who)
            .whereField("time", isLessThan: endUnixTime)
            .order(by: "time", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: ReportST.self)
    }
    
    func getLastReportFT(who: String, endUnixTime: Double) async throws -> ReportFTEntity? {
        let snapshot = try await store
            .collection(FBStoreCollection.FT.rawValue)
            .whereField("who", isEqualTo: who)
            .whereField("time", isLessThan: endUnixTime)
            .order(by: "time", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: ReportFTEntity.self)
    }
    
    func getLastReportET(who: String, exerciseId: Int, endUnixTime: Int) async throws -> (String, ReportETEntity)? {
        let snapshot = try await store
            .collection(FBStoreCollection.ET.rawValue)
            .whereField("who", isEqualTo: who)
            .whereField("exid", isEqualTo: exerciseId)
            .whereField("dshTime", isLessThan: endUnixTime)
            .order(by: "dshTime", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        let report = try document.data(as: ReportETEntity.self)
        
        return (document.documentID, report)
    }
    
    func getLastReportETSet(who: String, exerciseId: Int, endUnixTime: Double) async throws -> (String, ReportETSetEntity)? {
        let snapshot = try await store
            .collection(FBStoreCollection.ETSet.rawValue)
            .whereField("who", isEqualTo: who)
            .whereField("exid", isEqualTo: exerciseId)
            .whereField("dshTime", isLessThanOrEqualTo: endUnixTime)
            .order(by: "dshTime", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        guard let docuId = snapshot.documents.first?.documentID else { return nil }
        
        guard let setSnapshot = try await store
            .collection(FBStoreCollection.ETSet.rawValue)
            .whereField("rptId", isEqualTo: docuId)
            .order(by: "stime", descending: true)
            .limit(to: 1)
            .getDocuments()
            .documents
            .first else { return nil }
        
        let entity = try setSnapshot.data(as: ReportETSetEntity.self)
        
        return (setSnapshot.documentID, entity)
    }
    
    func getSTParams() async throws -> [String: [Float]]? {
        print("FbStore/getSTParams: triggered")
        let snapshot = try await store
            .collection(FBStoreCollection.ReportParams.rawValue)
            .document("STUI")
            .getDocument()
        
        return snapshot.data() as? [String: [Float]]
    }
    
    func getFTParams() async throws -> FTParam? {
        print("FbStore/getFTParams: triggered")
        let snapshot = try await store
            .collection(FBStoreCollection.ReportParams.rawValue)
            .document("FTUI")
            .getDocument()
        
        return try snapshot.data(as: FTParam.self)
    }
    
    func getETParam(exerciseId: Int) async throws -> ETParamEntity {
        let snapshot = try await store
            .collection(FBStoreCollection.ReportParams.rawValue)
            .document("ET\(exerciseId)")
            .getDocument()
        
        return try snapshot.data(as: ETParamEntity.self)
    }
    
    func setETWeightCount(setReportId: String, weight: Int, count: Int) async throws {
        if setReportId.isEmpty {
            return
        }
        try await store
            .collection(FBStoreCollection.ETSet.rawValue)
            .document(setReportId)
            .updateData([
                "weight": weight,
                "repCnt": count
            ])
    }
    
    func setReportBT(reportId: String, reportBT: ReportBTEntity) async throws {
        try await store.collection(FBStoreCollection.BT.rawValue)
            .document(reportId)
            .setData(from: reportBT)
    }
    
    func setBTWeightCount(reportSetId: String, weight: Int?, count: Int?) async throws {
        if reportSetId.isEmpty {
            return
        }
        try await store
            .collection(FBStoreCollection.BTSet.rawValue)
            .document(reportSetId)
            .updateData([
                "weight": weight,
                "cnt": count
            ])
    }
    
    func setBTMuscleName(reportBTId: String, muscleNames: [String?]) async throws {
        if reportBTId.isEmpty {
            return
        }
        try await store
            .collection(FBStoreCollection.BT.rawValue)
            .document(reportBTId)
            .updateData([
                "msName": muscleNames
            ])
    }
    
    func getExercises() async throws -> [ExerciseEntity] {
        let snapshot = try await store
            .collection(FBStoreCollection.Exercise.rawValue)
            .getDocuments()
        
        return snapshot.documents.compactMap({ try? $0.data(as: ExerciseEntity.self) })
    }
    
    func getMuscles() async throws -> [MuscleEntity] {
        let snapshot = try await store
            .collection(FBStoreCollection.Muscle.rawValue)
            .getDocuments()
        
        return snapshot.documents.compactMap({ try? $0.data(as: MuscleEntity.self) })
    }
    
    func getDashboards(who: String, startUnixTime: Int, endUnixTime: Int) async throws -> [DashboardEntity] {
        let snapshot = try await store
            .collection(FBStoreCollection.Dashboard.rawValue)
            .whereField("who", isEqualTo: who)
            .whereField("time", isGreaterThanOrEqualTo: startUnixTime)
            .whereField("time", isLessThanOrEqualTo: endUnixTime)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: DashboardEntity.self) }
    }
    
    func getDashboardCount(who: String) async throws -> Int {
        let countQuery = store
            .collection(FBStoreCollection.Dashboard.rawValue)
            .whereField("who", isEqualTo: who)
            .count
        
        let snapshot = try await countQuery.getAggregation(source: .server)
        return snapshot.count.intValue
    }
}
