//
//  Extensions.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/17/24.
//

import Foundation
import SwiftUI

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    /// 각 요소의 크기가 size로 자름
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    func takeLast(_ count: Int) -> Self {
        if self.count < count {
            return self
        } else {
            return Array(self[self.index(self.endIndex, offsetBy: -count)..<self.endIndex])
        }
    }
    func take(_ count: Int) -> Self {
        return Array(self[self.startIndex..<self.index(self.startIndex, offsetBy: count)])
    }
}

extension Array<Int> {
    func average() -> Float {
        var sum = 0
        for number in self {
            let (tempSum, overflow) = sum.addingReportingOverflow(number)
            if overflow {
                return Float(Int.max)
            }
            sum = tempSum
        }
        return Float(sum) / Float(self.count)
    }
    func sd() -> Float {
        let average = self.average()
        return sqrt(self.map({ pow((Float($0) - average), 2) / Float(self.count - 1) }).reduce(0, +))
    }
}

extension Data {
    func toFloatArray(arrayCount: Int) -> [[Float]]? {
        let floatCount = self.count / MemoryLayout<Float>.size
        guard floatCount > 0 && floatCount % arrayCount == 0 else { return nil } // 4개의 Float로 나누어 떨어져야 함
        
        var floatArray = [[Float]]()
        
        for i in 0..<arrayCount {
            var row = [Float]()
            for j in 0..<floatCount / arrayCount {
                let startIndex = (i * floatCount / arrayCount + j) * MemoryLayout<Float>.size
                let floatValue: Float = self.subdata(in: startIndex..<startIndex + MemoryLayout<Float>.size).withUnsafeBytes {
                    $0.load(as: Float.self)
                }
                row.append(floatValue)
            }
            floatArray.append(row)
        }
        
        return floatArray
    }
}


@inlinable // trivial-implementation
public func == <A: Equatable, B: Equatable>(lhs: (A,B), rhs: (A,B)) -> Bool {
    guard lhs.0 == rhs.0 else { return false }
    /*tail*/ return (
        lhs.1
    ) == (
        rhs.1
    )
}

extension Data {
    
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(_ options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

extension String {
    func hexToData() -> Data? {
        let len = count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = index(startIndex, offsetBy: i*2)
            let k = index(j, offsetBy: 2)
            let bytes = self[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        return data
    }
    
    ///@param length: 한 개의 길이
    func components(withMaxLength length: Int) -> [String] {
        return stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
    
    func take(_ count: Int) -> String {
        return String(self[self.startIndex..<self.index(self.startIndex, offsetBy: count)])
    }
    
    func takeLast(_ count: Int) -> String {
        return String(self[self.index(self.endIndex, offsetBy: -count)..<self.endIndex])
    }
}

extension Double {
    func unixTimeToDateStr(_ dateFormat: String = "yy.MM.dd") -> String {
        let date = Date(timeIntervalSince1970: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: date)
    }
    
    func unixTimeToStopWatchTime() -> String{
        let minutes: Int = Int(self / 60)
        
        if minutes < 60 {
            return "\(minutes)분"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return  "\(hours)시간 \(remainingMinutes)분"
        }
    }
    
    func unixTimeToDate() -> Date {
        return Date(timeIntervalSince1970: self)
    }
}

extension Array where Element == Double {
    func unixTimeToDateStrForGraph() -> [String] {
        var previousDate: String = ""
        return self.enumerated().reduce(into: []) { result, current in
            let (index, timeInterval) = current
            let currentDate = Double(timeInterval).unixTimeToDateStr("yy.MM.dd")
            
            if index == 0 {
                result.append(currentDate)
            } else {
                let currentYear = currentDate.prefix(2)
                let previousYear = previousDate.prefix(2)
                
                if currentYear == previousYear {
                    let formattedDate = Double(timeInterval).unixTimeToDateStr("MM.dd")
                    result.append(formattedDate)
                } else {
                    result.append(currentDate)
                }
            }
            previousDate = currentDate
        }
    }
}

extension Array where Element == Float {
    func average() -> Float {
        return self.reduce(0.0, + ) / Float(self.count)
    }
}
    
extension Array where Element: BinaryFloatingPoint {
    func getAvg() -> Element? {
        guard !self.isEmpty else { return nil }
        let sum = self.reduce(0, +)
        return sum / Element(self.count)
    }
}

extension Array where Element == Int {
    func getAvg() -> Float? {
        guard !self.isEmpty else { return nil }
        let sum = self.reduce(0, +)
        return Float(sum) / Float(self.count)
    }
}

extension Date {
    func getDateStr(_ dateFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: self)
    }
}

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}

extension Binding: Equatable where Value: Equatable {
    public static func == (left: Binding<Value>, right: Binding<Value>) -> Bool {
      left.wrappedValue == right.wrappedValue
   }
}

@propertyWrapper
public struct EquatableBinding<Wrapped: Equatable>: Equatable {
   public var wrappedValue: Binding<Wrapped>

   public init(wrappedValue: Binding<Wrapped>) {
      self.wrappedValue = wrappedValue
   }

   public static func == (left: EquatableBinding<Wrapped>, right: EquatableBinding<Wrapped>) -> Bool {
      left.wrappedValue.wrappedValue == right.wrappedValue.wrappedValue
   }
}

func valueToqV(_ value: Float) -> Float {
    let mV = value * 2.42/(pow(2, 23) - 1) / 12
    return mV * 1000 * 1000
}
