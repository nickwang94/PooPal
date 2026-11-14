import XCTest
@testable import PooPal

final class InsightsTests: XCTestCase {
    private var calendar: Calendar!
    private var now: Date!

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        cal.firstWeekday = 2
        calendar = cal
        now = date(2026, 11, 14, 19, 0) // Saturday
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func daysAgo(_ n: Int, hour: Int = 9) -> Date {
        calendar.date(byAdding: .day, value: -n, to: date(2026, 11, 14, hour))!
    }

    // MARK: 30-day average

    func testLast30AverageUsesShorterSpanWhenTrackingIsNew() {
        let dates = (0..<10).map { daysAgo($0) } + [daysAgo(0, hour: 7)]
        let stats = PoopStats(dates: dates, now: now, calendar: calendar)
        XCTAssertEqual(stats.trackedDays, 10)
        XCTAssertEqual(stats.averagePerDayLast30 ?? 0, 1.1, accuracy: 0.0001)
        XCTAssertEqual(stats.averagePerDay ?? 0, 1.1, accuracy: 0.0001)
    }

    func testLast30AverageDiffersFromFullHistory() {
        // 60 days ago: daily for 30 days; last 30 days: every other day (15 entries).
        let old = (30..<60).map { daysAgo($0) }
        let recent = stride(from: 0, to: 30, by: 2).map { daysAgo($0) }
        let stats = PoopStats(dates: old + recent, now: now, calendar: calendar)
        XCTAssertEqual(stats.last30DaysCount, 15)
        XCTAssertEqual(stats.averagePerDayLast30 ?? 0, 0.5, accuracy: 0.0001)
        XCTAssertEqual(stats.averagePerDay ?? 0, 45.0 / 60.0, accuracy: 0.0001)
    }

    func testLast30AverageNilWithoutEntries() {
        XCTAssertNil(PoopStats(dates: [], now: now, calendar: calendar).averagePerDayLast30)
    }

    // MARK: Bristol

    func testBristolDistributionIgnoresOldMissingAndInvalid() {
        let entries: [(date: Date, type: Int?)] = [
            (daysAgo(0), 4), (daysAgo(1), 4), (daysAgo(2), 3), (daysAgo(3), nil),
            (daysAgo(4), 9), (daysAgo(40), 1),
        ]
        let distribution = PoopStats.bristolDistribution(entries, now: now, calendar: calendar)
        XCTAssertEqual(distribution, [.smoothSnake: 2, .crackedSausage: 1])
        XCTAssertEqual(PoopStats.mostCommonBristol(entries, now: now, calendar: calendar), .smoothSnake)
    }

    func testMostCommonBristolTieGoesToIdeal() {
        let entries: [(date: Date, type: Int?)] = [(daysAgo(0), 1), (daysAgo(1), 5)]
        XCTAssertEqual(PoopStats.mostCommonBristol(entries, now: now, calendar: calendar), .softBlobs)
        XCTAssertNil(PoopStats.mostCommonBristol([], now: now, calendar: calendar))
    }

    // MARK: Trends

    func testWeeklyBucketsIncludeEmptyWeeksOldestFirst() {
        let dates = [daysAgo(0), daysAgo(1), daysAgo(8), daysAgo(30)]
        let buckets = Trends.buckets(dates, period: .week, count: 3, now: now, calendar: calendar)
        XCTAssertEqual(buckets.map(\.count), [0, 1, 2])
        XCTAssertEqual(buckets.last?.start, date(2026, 11, 9, 0, 0)) // Monday
        XCTAssertEqual(buckets.first?.start, date(2026, 10, 26, 0, 0))
    }

    func testMonthlyBuckets() {
        let dates = [daysAgo(0), date(2026, 11, 1, 0, 30), date(2026, 10, 31, 23, 0), date(2026, 9, 5)]
        let buckets = Trends.buckets(dates, period: .month, count: 3, now: now, calendar: calendar)
        XCTAssertEqual(buckets.map(\.count), [1, 1, 2])
        XCTAssertEqual(buckets.map(\.start), [date(2026, 9, 1, 0, 0), date(2026, 10, 1, 0, 0), date(2026, 11, 1, 0, 0)])
    }

    func testTrendsIgnoreFutureEntries() {
        let buckets = Trends.buckets([date(2026, 11, 15)], period: .week, count: 1, now: now, calendar: calendar)
        XCTAssertEqual(buckets.map(\.count), [0])
    }

    // MARK: Reminders

    func testInactivityFiresOnNthDayAfterLastEntry() {
        let last = date(2026, 11, 13, 21, 30)
        let fire = ReminderPlanner.inactivityFireDate(lastEntry: last, days: 3, hour: 10, now: now, calendar: calendar)
        XCTAssertEqual(fire, date(2026, 11, 16, 10, 0))
    }

    func testInactivityAlreadyOverdueFiresNextMorning() {
        let last = date(2026, 11, 5)
        // now is 19:00, past 10:00 → tomorrow 10:00
        XCTAssertEqual(
            ReminderPlanner.inactivityFireDate(lastEntry: last, days: 3, hour: 10, now: now, calendar: calendar),
            date(2026, 11, 15, 10, 0)
        )
        // before 10:00 → today 10:00
        XCTAssertEqual(
            ReminderPlanner.inactivityFireDate(lastEntry: last, days: 3, hour: 10, now: date(2026, 11, 14, 7, 0), calendar: calendar),
            date(2026, 11, 14, 10, 0)
        )
    }

    func testInactivityNeedsAnEntryAndPositiveDays() {
        XCTAssertNil(ReminderPlanner.inactivityFireDate(lastEntry: nil, days: 3, now: now, calendar: calendar))
        XCTAssertNil(ReminderPlanner.inactivityFireDate(lastEntry: now, days: 0, now: now, calendar: calendar))
    }

    func testInactivityMessageCountsCalendarDays() {
        let message = ReminderPlanner.inactivityMessage(
            lastEntry: date(2026, 11, 13, 23, 0), fireDate: date(2026, 11, 16, 10, 0), calendar: calendar
        )
        XCTAssertEqual(message.title, "已经 3 天没有便便记录啦")
    }

    func testDailyComponentsClamp() {
        XCTAssertEqual(ReminderPlanner.dailyComponents(minutes: 21 * 60 + 30), DateComponents(hour: 21, minute: 30))
        XCTAssertEqual(ReminderPlanner.dailyComponents(minutes: -5), DateComponents(hour: 0, minute: 0))
        XCTAssertEqual(ReminderPlanner.dailyComponents(minutes: 9999), DateComponents(hour: 23, minute: 59))
    }
}
