//
//  GoalUrgency.swift
//  Bodii
//

import SwiftUI

/// 목표 모드 긴박도 레벨
///
/// 남은 기간 비율에 따라 UI 색상과 AI 코칭 톤을 결정합니다.
enum GoalUrgency: Int, CaseIterable {
    case relaxed = 0   // 60%+ 시간 남음
    case steady = 1    // 30-60% 남음
    case intense = 2   // 10-30% 남음
    case critical = 3  // 10% 미만

    /// 사용자 표시용 이름
    var displayName: String {
        switch self {
        case .relaxed: return "여유"
        case .steady: return "순항"
        case .intense: return "집중"
        case .critical: return "스퍼트"
        }
    }

    /// 긴박도에 따른 테마 색상
    var color: Color {
        switch self {
        case .relaxed: return .blue.opacity(0.7)
        case .steady: return .blue
        case .intense: return .orange
        case .critical: return .red
        }
    }

    /// 긴박도에 따른 배경 그라데이션 색상
    var gradientColors: [Color] {
        switch self {
        case .relaxed: return [.blue.opacity(0.3), .blue.opacity(0.1)]
        case .steady: return [.blue.opacity(0.4), .blue.opacity(0.2)]
        case .intense: return [.orange.opacity(0.4), .orange.opacity(0.2)]
        case .critical: return [.red.opacity(0.4), .red.opacity(0.2)]
        }
    }
}
