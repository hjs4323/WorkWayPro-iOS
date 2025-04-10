//
//  ReportST.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/24/24.
//

import Foundation
import SwiftUI

let spineCode = ["C3", "C7", "T4", "T8", "T12"]

struct ReportST: Codable, Equatable, Report {
    var who: String
    var time: Int
    var dshTime: Int
    var value: [String: [Float]]
    var score: Float
}

struct STParam: Equatable, Codable {
    let spineCode: String
    let values: [Float]
    
    var uiBorders: [Float] {
        return [0, self.values[0], self.values[1], self.values[2], 1]
    }
    var m: Float {
        return values.last!
    }
    var l: Float {
        values.first!
    }
    var u: Float {
        values[values.count - 2]
    }
}
