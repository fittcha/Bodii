//
//  BodiiApp.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: SwiftUI App Lifecycle
// iOS 14+에서는 App protocol 기반 진입점 사용
// 💡 Java 비교: main() 메서드 대신 App struct 사용

import SwiftUI

// MARK: - App Entry Point

@main
struct BodiiApp: App {

    // MARK: - Properties

    // 📚 학습 포인트: @StateObject
    // App 생명주기 동안 유지되는 상태 객체
    // Core Data의 PersistenceController를 앱 전역에서 사용
    private let persistenceController = PersistenceController.shared

    // MARK: - Body

    // 📚 학습 포인트: some Scene
    // WindowGroup은 플랫폼에 맞는 윈도우 관리 제공
    // iOS: 단일 윈도우, macOS: 다중 윈도우 지원
    var body: some Scene {
        WindowGroup {
            ContentView()
                // 📚 학습 포인트: Environment
                // managedObjectContext를 View 계층 전체에 주입
                // 하위 뷰에서 @Environment(\.managedObjectContext)로 접근 가능
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}
