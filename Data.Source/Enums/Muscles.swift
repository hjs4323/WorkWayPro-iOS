//
//  Muscles.swift
//  WorkwayVer2
//
//  Created by loyH on 7/5/24.
//

import Foundation
import SwiftUI

enum ExerciseParts: Int, CaseIterable {
    case Chest = 0
    case Back = 1
    case Shoulder = 2
    case Leg = 3
    case Arm = 4
    case Abs = 5
}

enum ExercisePartsName: String, CaseIterable {
    case Chest = "가슴"
    case Back = "등"
    case Shoulder = "어깨"
    case Leg = "하체"
    case Arm = "팔"
    case Abs = "복근"
}

let ExercisePartNameMap = [
    0: "가슴",
    1: "등",
    2: "어깨",
    3: "하체",
    4: "팔",
    5: "복근",
]

let MuscleNameIdMap = [
    "frtrapezius" : 6,
    "fltrapezius" : 5,
    "frshoulder" : 8,
    "flshoulder" : 7,
    "frchest" : 2,
    "flchest" : 1,
    "frbicep" : 16,
    "flbicep" : 15,
    "frabs" : 20,
    "flabs" : 19,
    "bllatissimusdorsi" : 3,
    "brlatissimusdorsi" : 4,
    "blshoulder" : 7,
    "brshoulder" : 8,
    "bltrapezius" : 5,
    "brtrapezius" : 6,
    "bltriceps" : 17,
    "brtriceps" : 18,
    "lmaximus_gluteus" : 21,
    "rmaximus_gluteus" : 22,
    "lrectus_femoris" : 23,
    "rrectus_femoris" : 24,
    "lbiceps_femoris" : 25,
    "rbiceps_femoris" : 26,
    "ltibialis_anterior" : 27,
    "rtibialis_anterior" : 28
]

let bodies = ["fbody", "bbody"]

func getMatchMuscleId(_ muscle: Int) -> Int {
    return if muscle%2 == 0 {
        muscle - 1
    } else {
        muscle + 1
    }
}



let totalMuscles: [MuscleDTO] = [
    MuscleDTO(id: 1, name: "대흉근", isLeft: true, part: 0),
    MuscleDTO(id: 2, name: "대흉근", isLeft: false, part: 0),
    MuscleDTO(id: 3, name: "광배근", isLeft: true, part: 1),
    MuscleDTO(id: 4, name: "광배근", isLeft: false, part: 1),
    MuscleDTO(id: 5, name: "상부 승모근", isLeft: true, part: 1),
    MuscleDTO(id: 6, name: "상부 승모근", isLeft: false, part: 1),
    MuscleDTO(id: 7, name: "측면 삼각근", isLeft: true, part: 2),
    MuscleDTO(id: 8, name: "측면 삼각근", isLeft: false, part: 2),
    MuscleDTO(id: 9, name: "중부 승모근", isLeft: true, part: 1),
    MuscleDTO(id: 10, name: "중부 승모근", isLeft: false, part: 1),
    MuscleDTO(id: 11, name: "전거근", isLeft: true, part: 2),
    MuscleDTO(id: 12, name: "전거근", isLeft: false, part: 2),
    MuscleDTO(id: 15, name: "이두근", isLeft: true, part: 4),
    MuscleDTO(id: 16, name: "이두근", isLeft: false, part: 4),
    MuscleDTO(id: 17, name: "삼두근", isLeft: true, part: 4),
    MuscleDTO(id: 18, name: "삼두근", isLeft: false, part: 4),
    MuscleDTO(id: 21, name: "대둔근", isLeft: true, part: 3),
    MuscleDTO(id: 22, name: "대둔근", isLeft: false, part: 3),
    MuscleDTO(id: 23, name: "대퇴직근", isLeft: true, part: 3),
    MuscleDTO(id: 24, name: "대퇴직근", isLeft: false, part: 3),
    MuscleDTO(id: 25, name: "햄스트링", isLeft: true, part: 3),
    MuscleDTO(id: 26, name: "햄스트링", isLeft: false, part: 3),
    MuscleDTO(id: 27, name: "전경골근", isLeft: true, part: 3),
    MuscleDTO(id: 28, name: "전경골근", isLeft: false, part: 3),
]

let muscleDictionary = Dictionary(uniqueKeysWithValues: totalMuscles.map { ($0.id, $0) })
let ftMuscles: [MuscleDTO] = totalMuscles.filter{$0.part == 3}

