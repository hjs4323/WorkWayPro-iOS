//
//  HardWares.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/11/24.
//

struct Clip: Equatable, Hashable {
    let macAddress: String
    var muscleId: Int
    var battery: Float?
    var hubIndex: Int
    
    var battAlerted: Bool = false
    var connection: Bool = true
    
    mutating func setBattAlerted() {
        guard let battery else { return }
        self.battAlerted = battery < 3.4
    }
    
    enum LedColor {
        case white
        case blue
        case whiteBlink
    }
}

struct Hub: Equatable {
    let name: String
    var battery: Float? = nil
    var battAlerted: Bool = false
    
    var connection: Bool = true
}

