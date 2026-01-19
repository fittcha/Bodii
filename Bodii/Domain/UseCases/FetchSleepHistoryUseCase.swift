//
//  FetchSleepHistoryUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Query Use Case Pattern
// 수면 기록 히스토리 조회를 캡슐화하는 Use Case 패턴
// 💡 Java 비교: Service layer의 조회 메서드와 유사하지만 더 세분화됨

import Foundation
import CoreData

// MARK: - FetchSleepHistoryUseCase

/// 수면 기록 히스토리 조회 Use Case
/// 목록 표시를 위해 수면 기록 데이터를 조회하고 변환합니다.
/// 📚 학습 포인트: Clean Architecture - Use Case Layer
/// - 특정 비즈니스 로직(히스토리 데이터 조회)을 독립적인 유닛으로 캡슐화
/// - Repository의 raw data를 UI에 최적화된 형태로 변환
/// - UI나 데이터베이스에 의존하지 않는 순수한 비즈니스 로직
/// 💡 Java 비교: Interactor 또는 Service 클래스의 단일 책임 메서드
struct FetchSleepHistoryUseCase {

    // MARK: - Types

    /// 히스토리 조회 모드
    /// 📚 학습 포인트: Enum for Query Modes
    /// - 다양한 조회 패턴을 타입으로 정의
    /// - 각 케이스가 다른 조회 방식을 나타냄
    /// 💡 Java 비교: Enum with strategy pattern과 유사
    enum QueryMode {
        /// 모든 기록 조회
        case all

        /// 최근 N일 조회
        case recent(days: Int)

        /// 특정 기간 조회
        case dateRange(from: Date, to: Date)
    }

    /// 히스토리 조회에 필요한 입력 데이터
    /// 📚 학습 포인트: Nested Type
    /// - Use Case 내부에 관련된 타입을 중첩하여 네임스페이스 정리
    /// - 외부에서는 FetchSleepHistoryUseCase.Input으로 접근
    /// 💡 Java 비교: static nested class와 유사
    struct Input {
        /// 조회 모드 (기본값: 모든 기록)
        let mode: QueryMode

        /// 초기화
        /// - Parameter mode: 조회 모드 (기본값: .all)
        init(mode: QueryMode = .all) {
            self.mode = mode
        }
    }

    /// 히스토리 조회 결과
    /// 📚 학습 포인트: Result Type
    /// 조회된 데이터와 메타 정보를 함께 반환
    /// 💡 Java 비교: DTO (Data Transfer Object)와 유사
    struct Output {
        /// 수면 기록 배열 (날짜 내림차순 정렬 - 최신순)
        /// 📚 학습 포인트: Collection Type
        /// - UI 리스트에 최적화된 형태로 정렬
        /// - 최신 기록이 먼저 표시됨
        let records: [SleepRecord]

        /// 조회 모드
        let mode: QueryMode

        /// 조회 날짜 범위 (실제 조회된 데이터 기준)
        let dateRange: ClosedRange<Date>?

        /// 데이터 존재 여부
        /// 📚 학습 포인트: Computed Property
        /// UI에서 empty state 표시 여부 판단에 사용
        var isEmpty: Bool {
            records.isEmpty
        }

        /// 데이터 개수
        var count: Int {
            records.count
        }

        /// 총 수면 시간 (분)
        /// 📚 학습 포인트: Aggregate Calculation
        /// 히스토리 요약 정보로 표시
        var totalDuration: Int32 {
            records.reduce(0) { $0 + $1.duration }
        }

        /// 평균 수면 시간 (분)
        var averageDuration: Int32? {
            guard !isEmpty else { return nil }
            return totalDuration / Int32(count)
        }

        /// 평균 수면 시간을 시:분 형식으로 반환
        /// 📚 학습 포인트: Computed Property
        /// UI에서 표시할 때 사용하기 쉬운 형태로 제공
        /// - Returns: (hours, minutes) 튜플
        var averageDurationFormatted: (hours: Int, minutes: Int)? {
            guard let avg = averageDuration else { return nil }
            let hours = Int(avg) / 60
            let minutes = Int(avg) % 60
            return (hours, minutes)
        }

        /// 수면 상태별 분포
        /// 📚 학습 포인트: Dictionary Grouping
        /// 차트나 통계 표시에 사용
        /// - Returns: [SleepStatus: 개수]
        var statusDistribution: [SleepStatus: Int] {
            Dictionary(grouping: records) { $0.status }
                .mapValues { $0.count }
        }

        /// 가장 많은 수면 상태
        /// 📚 학습 포인트: Max By Value
        /// 사용자의 주된 수면 상태 표시
        var mostCommonStatus: SleepStatus? {
            statusDistribution.max(by: { $0.value < $1.value })?.key
        }

        /// 요약 문자열
        /// 📚 학습 포인트: UI Helper Method
        /// UI에서 바로 사용할 수 있는 요약 정보
        func summary() -> String {
            guard !isEmpty else {
                return "수면 기록이 없습니다."
            }

            var summary = """
            총 \(count)개의 수면 기록
            """

            if let avg = averageDurationFormatted {
                summary += "\n평균 수면 시간: \(avg.hours)시간 \(avg.minutes)분"
            }

            if let mostCommon = mostCommonStatus {
                let countForStatus = statusDistribution[mostCommon] ?? 0
                summary += "\n가장 많은 상태: \(mostCommon.displayName) (\(countForStatus)회)"
            }

            if let range = dateRange {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .none
                formatter.locale = Locale(identifier: "ko_KR")
                let startStr = formatter.string(from: range.lowerBound)
                let endStr = formatter.string(from: range.upperBound)
                summary += "\n기간: \(startStr) ~ \(endStr)"
            }

            return summary
        }
    }

    // MARK: - Error

    /// 히스토리 조회 중 발생할 수 있는 에러
    /// 📚 학습 포인트: Custom Error Type
    /// Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// 💡 Java 비교: Custom Exception과 유사
    enum HistoryError: Error, LocalizedError {
        /// 조회 실패
        case fetchFailed(Error)

        /// 유효하지 않은 날짜 범위
        case invalidDateRange

        /// 유효하지 않은 일수 값
        case invalidDays(Int)

        /// 에러 설명 (사용자에게 표시할 메시지)
        /// 📚 학습 포인트: LocalizedError Protocol
        /// errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공
        var errorDescription: String? {
            switch self {
            case .fetchFailed(let error):
                return "히스토리 조회 실패: \(error.localizedDescription)"
            case .invalidDateRange:
                return "유효하지 않은 날짜 범위입니다."
            case .invalidDays(let days):
                return "유효하지 않은 일수입니다: \(days). 1 이상의 값을 입력하세요."
            }
        }
    }

    // MARK: - Dependencies

    /// 수면 데이터 저장소
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 주입받아 사용 (테스트 가능성 향상)
    /// 💡 Java 비교: @Autowired Repository와 유사
    private let sleepRepository: SleepRepositoryProtocol

    // MARK: - Initialization

    /// FetchSleepHistoryUseCase 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Autowired constructor injection과 유사
    ///
    /// - Parameter sleepRepository: 수면 데이터 저장소 (필수)
    init(sleepRepository: SleepRepositoryProtocol) {
        self.sleepRepository = sleepRepository
    }

    // MARK: - Execute

    /// 히스토리 데이터 조회 실행
    /// 📚 학습 포인트: Async/Await
    /// - Swift 5.5+의 동시성 모델
    /// - 비동기 작업을 동기 코드처럼 작성 가능
    /// 💡 Java 비교: CompletableFuture 또는 Kotlin Coroutines와 유사
    ///
    /// 📚 학습 포인트: Query Optimization
    /// 1. Repository에서 조회 모드에 따라 데이터 조회
    /// 2. 날짜 내림차순 정렬 (최신순)
    /// 3. 메타 정보 계산 (총 개수, 평균, 분포 등)
    ///
    /// - Parameter input: 히스토리 조회 입력 데이터
    /// - Returns: 수면 기록 히스토리
    /// - Throws: HistoryError - 조회 실패 시
    func execute(input: Input) async throws -> Output {
        // Step 1: 조회 모드에 따라 데이터 조회
        // 📚 학습 포인트: Switch on Associated Values
        // Enum의 associated value에 따라 다른 로직 실행
        let records: [SleepRecord]
        let dateRange: ClosedRange<Date>?

        do {
            switch input.mode {
            case .all:
                // 모든 기록 조회
                records = try await sleepRepository.fetchAll()
                // 날짜 범위 계산 (첫 기록 ~ 마지막 기록)
                if let first = records.first?.date, let last = records.last?.date {
                    // records는 내림차순이므로 first가 최신, last가 가장 오래된 것
                    dateRange = last...first
                } else {
                    dateRange = nil
                }

            case .recent(let days):
                // 유효성 검증
                guard days > 0 else {
                    throw HistoryError.invalidDays(days)
                }
                // 최근 N일 조회
                records = try await sleepRepository.fetchRecent(days: days)
                // 날짜 범위 계산
                let endDate = Date()
                if let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) {
                    dateRange = startDate...endDate
                } else {
                    dateRange = nil
                }

            case .dateRange(let from, let to):
                // 날짜 범위 유효성 검증
                guard from <= to else {
                    throw HistoryError.invalidDateRange
                }
                // 특정 기간 조회
                records = try await sleepRepository.fetch(from: from, to: to)
                dateRange = from...to
            }
        } catch let error as HistoryError {
            // 이미 HistoryError인 경우 그대로 throw
            throw error
        } catch {
            // Repository 에러를 HistoryError로 래핑
            throw HistoryError.fetchFailed(error)
        }

        // Step 2: 날짜 내림차순 정렬 (최신순)
        // 📚 학습 포인트: Sorting
        // UI 리스트는 최신 기록을 먼저 표시
        let sortedRecords = records.sorted { $0.date > $1.date }

        // Step 3: 결과 반환
        return Output(
            records: sortedRecords,
            mode: input.mode,
            dateRange: dateRange
        )
    }

    // MARK: - Convenience Methods

    /// 모든 기록 조회 간편 메서드
    /// 📚 학습 포인트: Convenience Method
    /// 가장 일반적인 사용 케이스를 위한 간편 메서드
    /// 💡 사용처: ViewModel에서 쉽게 호출 가능
    ///
    /// - Returns: 모든 수면 기록 히스토리
    /// - Throws: HistoryError
    func fetchAll() async throws -> Output {
        let input = Input(mode: .all)
        return try await execute(input: input)
    }

    /// 최근 N일 조회 간편 메서드
    /// 📚 학습 포인트: Convenience Method
    /// 자주 사용되는 패턴을 간단히 표현
    /// 💡 사용처: 주간/월간 히스토리 표시
    ///
    /// - Parameter days: 조회할 일수 (예: 7, 30)
    /// - Returns: 최근 N일 수면 기록 히스토리
    /// - Throws: HistoryError
    func fetchRecent(days: Int) async throws -> Output {
        let input = Input(mode: .recent(days: days))
        return try await execute(input: input)
    }

    /// 날짜 범위 조회 간편 메서드
    /// 📚 학습 포인트: Convenience Method
    /// 특정 기간 조회를 간단히 표현
    /// 💡 사용처: 커스텀 기간 필터링
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 특정 기간 수면 기록 히스토리
    /// - Throws: HistoryError
    func fetch(from startDate: Date, to endDate: Date) async throws -> Output {
        let input = Input(mode: .dateRange(from: startDate, to: endDate))
        return try await execute(input: input)
    }
}

// MARK: - Sample Usage

extension FetchSleepHistoryUseCase {
    /// 📚 학습 포인트: Sample Data for Testing
    /// Use Case의 사용 예시와 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: JUnit의 @Test fixture와 유사

    /// 샘플 입력 - 모든 기록
    static let sampleInputAll = Input(mode: .all)

    /// 샘플 입력 - 최근 7일
    static let sampleInputWeek = Input(mode: .recent(days: 7))

    /// 샘플 입력 - 최근 30일
    static let sampleInputMonth = Input(mode: .recent(days: 30))

    /// Preview용 context
    private static var previewContext: NSManagedObjectContext {
        PersistenceController.preview.container.viewContext
    }

    /// 샘플 출력 - 7일 데이터
    static func sampleOutput() -> Output {
        let now = Date()
        let context = previewContext

        let record1 = SleepRecord(context: context)
        record1.id = UUID()
        record1.date = now
        record1.duration = 420 // 7시간
        record1.status = Int16(SleepStatus.good.rawValue)
        record1.createdAt = now
        record1.updatedAt = now

        let record2 = SleepRecord(context: context)
        record2.id = UUID()
        record2.date = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        record2.duration = 480 // 8시간
        record2.status = Int16(SleepStatus.excellent.rawValue)
        record2.createdAt = now
        record2.updatedAt = now

        let record3 = SleepRecord(context: context)
        record3.id = UUID()
        record3.date = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        record3.duration = 360 // 6시간
        record3.status = Int16(SleepStatus.soso.rawValue)
        record3.createdAt = now
        record3.updatedAt = now

        let records = [record1, record2, record3]

        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let dateRange = startDate...now

        return Output(
            records: records,
            mode: .recent(days: 7),
            dateRange: dateRange
        )
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: FetchSleepHistoryUseCase 이해
///
/// FetchSleepHistoryUseCase의 역할:
/// - Repository에서 수면 기록을 조회하여 UI에 최적화된 형태로 반환
/// - 다양한 조회 모드 지원 (전체, 최근 N일, 날짜 범위)
/// - 통계 정보 계산 (평균, 분포, 가장 많은 상태 등)
/// - 날짜 내림차순 정렬 (최신순)
///
/// 지원하는 조회 모드:
/// 1. All: 모든 수면 기록 조회
///    - 사용처: 전체 히스토리 보기
///    - 주의: 데이터가 많으면 성능 이슈 가능
///
/// 2. Recent(days): 최근 N일 조회
///    - 사용처: 주간/월간 히스토리 (7일, 30일)
///    - 가장 자주 사용되는 모드
///
/// 3. DateRange(from, to): 특정 기간 조회
///    - 사용처: 커스텀 기간 필터링
///    - 유연한 조회 가능
///
/// Output에 포함된 정보:
/// - records: 수면 기록 배열 (날짜 내림차순)
/// - count: 총 개수
/// - totalDuration: 총 수면 시간
/// - averageDuration: 평균 수면 시간
/// - statusDistribution: 상태별 분포
/// - mostCommonStatus: 가장 많은 상태
/// - summary(): 요약 문자열
///
/// 성능 고려사항:
/// - Repository 쿼리는 0.5초 이내 목표
/// - 대량 데이터는 recent 또는 dateRange 사용 권장
/// - 정렬 및 통계 계산은 메모리에서 수행 (빠름)
///
/// Clean Architecture에서의 위치:
/// - Domain Layer의 Use Case
/// - SleepRepositoryProtocol에 의존
/// - Presentation Layer (ViewModel)에서 호출됨
///
/// 💡 Java Spring과의 비교:
/// - Spring: @Service class with query method
/// - Swift: Struct with async/await
/// - Spring: Repository를 @Autowired로 주입
/// - Swift: 생성자로 의존성 주입
///
/// 사용 예시:
/// ```swift
/// let useCase = FetchSleepHistoryUseCase(sleepRepository: repository)
///
/// // 간단한 조회 - 모든 기록
/// let allHistory = try await useCase.fetchAll()
/// print(allHistory.summary())
///
/// // 최근 7일 조회
/// let weekHistory = try await useCase.fetchRecent(days: 7)
/// print("평균 수면: \(weekHistory.averageDuration ?? 0)분")
///
/// // 날짜 범위 조회
/// let startDate = // ...
/// let endDate = // ...
/// let rangeHistory = try await useCase.fetch(from: startDate, to: endDate)
///
/// // UI에서 사용
/// List(allHistory.records) { record in
///     SleepRecordRow(record: record)
/// }
///
/// // 통계 표시
/// Text("가장 많은 상태: \(allHistory.mostCommonStatus?.displayName ?? "-")")
/// ```
///
/// 💡 실무 팁:
/// - 히스토리 뷰에서는 fetchAll() 또는 fetchRecent(days:) 사용
/// - 대량 데이터가 예상되면 최근 30~90일로 제한
/// - 필터링이 필요하면 fetch(from:to:) 사용
/// - Output의 통계 정보를 활용하여 요약 UI 구성
/// - 02:00 경계 로직은 Repository에서 자동 처리됨
///
/// FetchBodyTrendsUseCase와의 비교:
/// - FetchBodyTrendsUseCase: 차트 표시를 위한 트렌드 데이터 (날짜 오름차순)
/// - FetchSleepHistoryUseCase: 리스트 표시를 위한 히스토리 데이터 (날짜 내림차순)
/// - FetchBodyTrendsUseCase: 대사율 데이터 등 추가 정보 조회
/// - FetchSleepHistoryUseCase: 수면 기록만 조회하므로 더 단순함
///
