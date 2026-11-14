import XCTest
@testable import PooPal

final class PoopStatsTests: XCTestCase {
    private var calendar: Calendar!
    private var now: Date!

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        calendar = cal
        now = date(2026, 11, 2, 12, 0)
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testEmptyLogHasNoAverages() {
        let stats = PoopStats(dates: [], now: now, calendar: calendar)
        XCTAssertEqual(stats.totalCount, 0)
        XCTAssertEqual(stats.last7DaysCount, 0)
        XCTAssertNil(stats.daysSinceLast)
        XCTAssertNil(stats.averagePerDay)
        XCTAssertNil(stats.averageIntervalDays)
        XCTAssertEqual(stats.trackedDays, 0)
    }

    func testSingleEntryToday() {
        let stats = PoopStats(dates: [date(2026, 11, 2, 8)], now: now, calendar: calendar)
        XCTAssertEqual(stats.todayCount, 1)
        XCTAssertEqual(stats.daysSinceLast, 0)
        XCTAssertEqual(stats.trackedDays, 1)
        XCTAssertEqual(stats.averagePerDay ?? 0, 1.0, accuracy: 0.0001)
        XCTAssertNil(stats.averageIntervalDays)
    }

    func testDailyEntriesGiveOnePerDayAndOneDayInterval() {
        let dates = (0..<10).map { calendar.date(byAdding: .day, value: -$0, to: date(2026, 11, 2, 9))! }
        let stats = PoopStats(dates: dates, now: now, calendar: calendar)
        XCTAssertEqual(stats.totalCount, 10)
        XCTAssertEqual(stats.trackedDays, 10)
        XCTAssertEqual(stats.averagePerDay ?? 0, 1.0, accuracy: 0.0001)
        XCTAssertEqual(stats.averageIntervalDays ?? 0, 1.0, accuracy: 0.0001)
        XCTAssertEqual(stats.last7DaysCount, 7)
        XCTAssertEqual(stats.last30DaysCount, 10)
    }

    func testWindowBoundariesUseCalendarDays() {
        let dates = [
            date(2026, 10, 27, 0, 1),  // 6 days ago, early morning: inside 7-day window
            date(2026, 10, 26, 23, 59), // 7 days ago: outside 7-day window
            date(2026, 10, 4, 0, 0),    // 29 days ago: inside 30-day window
            date(2026, 10, 3, 23, 0),   // 30 days ago: outside 30-day window
        ]
        let stats = PoopStats(dates: dates, now: now, calendar: calendar)
        XCTAssertEqual(stats.last7DaysCount, 1)
        XCTAssertEqual(stats.last30DaysCount, 3)
        XCTAssertEqual(stats.daysSinceLast, 6)
    }

    func testDaysSinceLastCountsCalendarDaysNotHours() {
        // 23:50 yesterday is only ~12 hours ago but still "1 day" since.
        let stats = PoopStats(dates: [date(2026, 11, 1, 23, 50)], now: now, calendar: calendar)
        XCTAssertEqual(stats.daysSinceLast, 1)
        XCTAssertEqual(PoopMood(daysSinceLast: stats.daysSinceLast), .yesterday)
    }

    func testAverageIntervalWithUnevenGapsAndUnsortedInput() {
        let dates = [
            date(2026, 11, 2, 9),
            date(2026, 10, 29, 9),
            date(2026, 10, 30, 9),
        ]
        let stats = PoopStats(dates: dates, now: now, calendar: calendar)
        // Gaps of 1 and 3 days -> mean 2 days.
        XCTAssertEqual(stats.averageIntervalDays ?? 0, 2.0, accuracy: 0.0001)
        // 3 entries across Oct 29 ... Nov 2 (5 days).
        XCTAssertEqual(stats.trackedDays, 5)
        XCTAssertEqual(stats.averagePerDay ?? 0, 0.6, accuracy: 0.0001)
    }

    func testMultipleEntriesPerDay() {
        let dates = [date(2026, 11, 2, 7), date(2026, 11, 2, 11), date(2026, 11, 1, 20)]
        let stats = PoopStats(dates: dates, now: now, calendar: calendar)
        XCTAssertEqual(stats.todayCount, 2)
        XCTAssertEqual(stats.averagePerDay ?? 0, 1.5, accuracy: 0.0001)
        XCTAssertEqual(StatsFormat.interval(stats.averageIntervalDays).unit, "小时")
    }

    func testFutureEntriesAreIgnored() {
        let stats = PoopStats(dates: [date(2026, 11, 2, 8), date(2026, 11, 3, 8)], now: now, calendar: calendar)
        XCTAssertEqual(stats.totalCount, 1)
        XCTAssertEqual(stats.daysSinceLast, 0)
    }

    func testCountsByDay() {
        let dates = [date(2026, 11, 2, 7), date(2026, 11, 2, 21), date(2026, 11, 1, 9)]
        let counts = PoopStats.countsByDay(dates, calendar: calendar)
        XCTAssertEqual(counts[calendar.startOfDay(for: date(2026, 11, 2))], 2)
        XCTAssertEqual(counts[calendar.startOfDay(for: date(2026, 11, 1))], 1)
        XCTAssertEqual(counts.count, 2)
    }

    func testMoodThresholds() {
        XCTAssertEqual(PoopMood(daysSinceLast: nil), .noData)
        XCTAssertEqual(PoopMood(daysSinceLast: 0), .today)
        XCTAssertEqual(PoopMood(daysSinceLast: 1), .yesterday)
        XCTAssertEqual(PoopMood(daysSinceLast: 2), .aWhile(days: 2))
        XCTAssertEqual(PoopMood(daysSinceLast: 5), .tooLong(days: 5))
    }

    func testFormatting() {
        XCTAssertEqual(StatsFormat.perDay(nil), "—")
        XCTAssertEqual(StatsFormat.perDay(1.26), "1.3")
        XCTAssertEqual(StatsFormat.interval(1.5).value, "1.5")
        XCTAssertEqual(StatsFormat.interval(1.5).unit, "天")
        XCTAssertEqual(StatsFormat.interval(0.5).value, "12")
        // Just under a day reads as "1.0 天", not "24 小时".
        XCTAssertEqual(StatsFormat.interval(0.99).value, "1.0")
        XCTAssertEqual(StatsFormat.interval(0.99).unit, "天")
        XCTAssertEqual(StatsFormat.daysSince(0).value, "今天")
        XCTAssertEqual(StatsFormat.daysSince(3).value, "3")
    }

    func testElapsed() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let hour: TimeInterval = 3600
        XCTAssertNil(StatsFormat.elapsed(since: nil, now: now))
        XCTAssertEqual(StatsFormat.elapsed(since: now.addingTimeInterval(-20 * 60), now: now), "刚刚")
        XCTAssertEqual(StatsFormat.elapsed(since: now.addingTimeInterval(60), now: now), "刚刚")
        XCTAssertEqual(StatsFormat.elapsed(since: now.addingTimeInterval(-11.5 * hour), now: now), "11 小时")
        XCTAssertEqual(StatsFormat.elapsed(since: now.addingTimeInterval(-47.9 * hour), now: now), "47 小时")
        XCTAssertEqual(StatsFormat.elapsed(since: now.addingTimeInterval(-73 * hour), now: now), "3 天")
    }
}
