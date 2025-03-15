//
//  Muscle.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/24/24.
//

import Foundation

struct MuscleDTO: Equatable, Hashable {
    var id: Int
    var name: String
    var isLeft: Bool
    var part: Int
    
    func fullName(multiLine: Bool) -> String {
        return "(\(isLeft ? "좌" : "우"))\(multiLine ? "\n" : " ")\(name)"
    }
    
    func leftRightStr() -> String {
        return "(\(isLeft ? "좌" : "우"))"
    }
    
    static func fromEntity(entity: MuscleEntity) -> MuscleDTO {
        return MuscleDTO(id: entity.id, name: entity.name, isLeft: entity.left, part: entity.part)
    }
}

struct MuscleEntity: Equatable, Codable {
    let id: Int
    let name: String
    let left: Bool
    let part: Int
}
