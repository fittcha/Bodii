//
//  Gender+Korean.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import Foundation

// MARK: - Korean Localization

extension Gender {
    /// 한국어 표시 이름
    var koreanDisplayName: String {
        switch self {
        case .male:
            return "남성"
        case .female:
            return "여성"
        }
    }
}
