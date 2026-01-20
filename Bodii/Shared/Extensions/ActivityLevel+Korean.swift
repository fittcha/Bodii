//
//  ActivityLevel+Korean.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import Foundation

// MARK: - Korean Localization

extension ActivityLevel {
    /// 한국어 표시 이름
    var koreanDisplayName: String {
        switch self {
        case .sedentary:
            return "비활동적"
        case .lightlyActive:
            return "가벼운 활동"
        case .moderatelyActive:
            return "보통 활동"
        case .veryActive:
            return "활발한 활동"
        case .extraActive:
            return "매우 활발"
        }
    }

    /// 한국어 설명
    var koreanDescription: String {
        switch self {
        case .sedentary:
            return "거의 운동 안 함 (사무직, 재택근무)"
        case .lightlyActive:
            return "가벼운 운동 (주 1-3회)"
        case .moderatelyActive:
            return "보통 운동 (주 3-5회)"
        case .veryActive:
            return "활발한 운동 (주 6-7회)"
        case .extraActive:
            return "매우 활발 (운동선수, 육체 노동)"
        }
    }
}
