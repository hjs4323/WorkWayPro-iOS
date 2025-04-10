//
//  Exercise.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/12/24.
//

import Foundation
import FirebaseStorage

struct ExerciseDTO: Equatable {
    let exerciseId: Int
    let name: String
    let part: Int
    let mainMuscles: [MuscleDTO]
    let subMuscles: [MuscleDTO]
    let dfWei: Int
    let fromRelax: Bool
    
    static func fromEntity(entity: ExerciseEntity, muscles: [MuscleDTO]) -> ExerciseDTO {
        let mainMus = entity.mainMus.compactMap { mid in muscles.first { $0.id == mid } }
        let subMus = entity.subMus.compactMap { mid in muscles.first { $0.id == mid } }
        return ExerciseDTO(
            exerciseId: entity.exid,
            name: entity.name,
            part: entity.part,
            mainMuscles: mainMus,
            subMuscles: subMus,
            dfWei: entity.dfWei,
            fromRelax: entity.fromRlx
        )
    }
}

struct ExerciseEntity: Equatable, Codable {
    let exid: Int
    let name: String
    let part: Int
    let mainMus: [Int]
    let subMus: [Int]
    let dfWei: Int
    let fromRlx: Bool
}

