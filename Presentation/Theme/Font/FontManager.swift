//
//  FontManager.swift
//  LAYR
//
//  Created by 김성욱 on 2023/09/26.
//

import Foundation
import SwiftUI

extension Font{
    
    enum Pretendard: String {
        case semibold = "Pretendard-SemiBold"
        case medium = "Pretendard-Medium"
        case regular = "Pretendard-Regular"
        case bold = "Pretendard-Bold"
        
    }
    static func s_22() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 22)
    }
    static func s_20() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 20)
    }
    static func s_18() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 18)
    }
    static func s_30() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 30)
    }
    static func headlineMedium() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 20)
    }
    static func headlineSmall() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 14)
    }
    static func m_18() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 18)
    }
    static func m_10() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 10)
    }
    static func m_12() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 12)
    }
    static func m_20() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 20)
    }
    static func r_14() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 14)
    }
    static func r_10() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 10)
    }
    static func r_5() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 5)
    }
    static func bodyMedium() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 12)
    }
    static func bodySmall() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 10)
    }
    static func labelLarge() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 11)
    }
    static func labelMedium() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 10)
    }
    static func subtitle_L() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 18)
    }
    static func r_16() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 16)
    }
    static func subtitle_M_medium() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 16)
    }
    static func s_16() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 16)
    }
    static func headline_M_medium() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 18)
    }
    static func headline_M_regular() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 18)
    }
    static func headline_L_semibold() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 30)
    }
    static func body_M_medium() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 12)
    }
    static func body_M_semibold() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 12)
    }
    static func b_22() -> Font {
        return .custom(Pretendard.bold.rawValue, size: 22)
    }
    static func m_14() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 14)
    }
    static func m_16() -> Font {
        return .custom(Pretendard.medium.rawValue, size: 16)
    }
    static func s_13() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 13)
    }
    static func s_10() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 12)
    }
    static func s_12() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 12)
    }
    static func s_14() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 14)
    }
    static func s_17() -> Font {
        return .custom(Pretendard.semibold.rawValue, size: 17)
    }
    static func r_11() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 11)
    }
    static func r_12() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 12)
    }
    static func r_18() -> Font {
        return .custom(Pretendard.regular.rawValue, size: 18)
    }
}
