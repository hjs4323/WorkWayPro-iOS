//
//  PacketDecode.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/17/24.
//

import Foundation

class PacketDecode {
    static func battDecode(_ str: String) -> Float? {
        guard let intVal = Int(str, radix: 16) else { return nil }
        return Float(intVal)/50.0
    }
    static func dataSort(_ dataStr: String, hubIndexes: [Int]) -> [[Int]] {
        dataStr.components(withMaxLength: 32).map { aSample in
            aSample.components(withMaxLength: 4).enumerated().compactMap({ (index, dataStr) in
                hubIndexes.contains(index) ? (Int(dataStr, radix: 16) ?? 0) : nil
            })
        }
    }
}
