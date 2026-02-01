//
//  FoodSearchTab.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-31.
//

import Foundation

/// 음식 검색 화면의 탭 열거형
enum FoodSearchTab: Int, CaseIterable {
    case recent = 0
    case frequent = 1
    case custom = 2

    /// 탭 표시 이름
    var displayName: String {
        switch self {
        case .recent: return "최근 음식"
        case .frequent: return "자주 먹는"
        case .custom: return "커스텀"
        }
    }
}
