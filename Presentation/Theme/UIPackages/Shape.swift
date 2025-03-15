//
//  Shape.swift
//  WorkwayVer2
//
//  Created by loyH on 8/12/24.
//

import Foundation
import SwiftUI

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: -17, y: 0))
        path.addLine(to: CGPoint(x: rect.width + 32, y: 0))
        return path
    }
}

struct Triangle : Shape {
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        return path
    }
}
