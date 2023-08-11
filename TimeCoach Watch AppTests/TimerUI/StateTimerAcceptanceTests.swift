import XCTest
import LifeCoach
@testable import TimeCoach_Watch_App

final class StateTimerAcceptanceTests: XCTestCase {
    typealias TimerStore = TimerLoad & TimerSave
    
    func test_onLaunch_onToggleUserInteractionShouldStartNotificationAndSaveStateProcess() {
        let (sut, spy) = makeSUT()
        let expected = createAnyTimerState(using: spy.currentTimerSet, on: .running)
        
        sut.simulateToggleTimerUserInteraction()
        
        XCTAssertEqual(spy.receivedMessages, [
            .startTimer,
            .saveStateTimer(value: expected),
            .scheduleTimerNotification,
            .notifySavedTimer
        ])
    }
    
    func test_onLaunch_afterTimerDeliversShouldNotStartNotificationAndSaveStateProcess() {
        let (sut, spy) = makeSUT()
        let expected = createAnyTimerState(using: spy.currentTimerSet, on: .running)
        spy.deliversSetOnToggle(expected.localTimerSet.adding(1))
        
        sut.simulateToggleTimerUserInteraction()
        
        XCTAssertEqual(spy.receivedMessages, [
            .startTimer,
            .saveStateTimer(value: expected),
            .scheduleTimerNotification,
            .notifySavedTimer
        ])
    }
    
    func test_onLaunch_onStopUserInteractionShouldExecuteStopProcess() {
        let currentDate = Date()
        let (sut, spy) = makeSUT(currentDate: { currentDate })
        let expected = createAnyTimerState(
            using: createAnyTimerSet(startingFrom: currentDate, endDate: currentDate.adding(seconds: .pomodoroInSeconds)),
            on: .stop
        )
        
        sut.timerView.simulateStopTimerUserInteraction()
        
        XCTAssertEqual(spy.receivedMessages, [
            .stopTimer,
            .saveStateTimer(value: expected),
            .unregisterTimerNotification,
            .notifySavedTimer
        ])
    }
    
    func test_onLaunch_onPauseUserInteractionShouldExecutePauseProcess() {
        let currentDate = Date()
        let (sut, spy) = makeSUT(currentDate: { currentDate })
        let anySet = createAnyTimerSet(startingFrom: currentDate, endDate: currentDate.adding(seconds: .pomodoroInSeconds))
        let expected = createAnyTimerState(using: anySet, on: .pause)
        spy.deliversSetOnToggle(anySet)
        sut.timerView.simulateToggleTimerUserInteraction()
        spy.resetMessages()
        
        sut.timerView.simulateToggleTimerUserInteraction()
        
        XCTAssertEqual(spy.receivedMessages, [
            .pauseTimer,
            .saveStateTimer(value: expected),
            .unregisterTimerNotification,
            .notifySavedTimer
        ])
    }
    
    func test_onLaunch_onSkipUserInteractionShouldExecuteSkipProcess() {
        let currentDate = Date()
        let (sut, spy) = makeSUT(currentDate: { currentDate })
        let anySet = createAnyTimerSet(startingFrom: currentDate, endDate: currentDate.adding(seconds: .pomodoroInSeconds))
        let expected = createAnyTimerState(using: anySet, on: .stop)
        spy.deliversSetOnSkip(anySet)
        
        sut.timerView.simulateSkipTimerUserInteraction()
        
        XCTAssertEqual(spy.receivedMessages, [
            .skipTimer,
            .saveStateTimer(value: expected),
            .unregisterTimerNotification,
            .notifySavedTimer
        ])
    }
    
    func test_onLaunch_onSkipUserInteractionShouldStartNotificationAndSaveStateProcessOnce() {
        let currentDate = Date()
        let (sut, spy) = makeSUT(currentDate: { currentDate })
        let anySet = createAnyTimerSet(startingFrom: currentDate, endDate: currentDate.adding(seconds: .pomodoroInSeconds))
        let expected = createAnyTimerState(using: anySet, on: .stop)
        spy.deliversSetOnSkip(anySet)
        
        sut.timerView.simulateSkipTimerUserInteraction()
        
        spy.deliversSet(anySet)
        
        XCTAssertEqual(spy.receivedMessages, [
            .skipTimer,
            .saveStateTimer(value: expected),
            .unregisterTimerNotification,
            .notifySavedTimer
        ])
    }
    
    func test_onBackgroundEvent_shouldSendMessageToStartSaveStateProcess() {
        let currentDate = Date()
        let (sut, spy) = makeSUT(currentDate: { currentDate })
        let expected = createAnyTimerState(using: .pomodoroSet(date: currentDate), on: .stop)
        
        sut.goToBackground()
        
        XCTAssertEqual(spy.receivedMessages, [
            .saveStateTimer(value: expected),
            .notifySavedTimer
        ])
    }
    
    // MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init) -> (sut: TimeCoach_Watch_AppApp, spy: Spy) {
        let spy = Spy(currenDate: currentDate())
        let infra = Infrastructure(
            timerCountdown: spy,
            timerState: spy,
            stateTimerStore: spy,
            scheduler: spy,
            notifySavedTimer: spy.notifySavedTimer,
            currentDate: currentDate,
            unregisterTimerNotification: spy.unregisterTimerNotification
        )
        
        let sut = TimeCoach_Watch_AppApp(infrastructure: infra)
        
        return (sut, spy)
    }
    
    private func createAnyTimerState(using anySet: LocalTimerSet, on state: LocalTimerState.State) -> LocalTimerState {
        LocalTimerState(localTimerSet: anySet, state: state)
    }
    
    private func createAnyTimerSet(startingFrom startDate: Date = Date(), endDate: Date? = nil) -> LocalTimerSet {
        createTimerSet(0, startDate: startDate, endDate: endDate ?? startDate.adding(seconds: 1))
    }
    
    private func createTimerSet(_ elapsedSeconds: TimeInterval, startDate: Date, endDate: Date) -> LocalTimerSet {
        LocalTimerSet(elapsedSeconds, startDate: startDate, endDate: endDate)
    }
    
    private class Spy: TimerCoutdown, TimerStore, LocalTimerStore, Scheduler {
        private let currenDate: Date
        
        init(currenDate: Date) {
            self.currenDate = currenDate
        }
        var currentTimerSet: LifeCoach.LocalTimerSet { .pomodoroSet(date: currenDate) }
        
        enum AnyMessage: Equatable, CustomStringConvertible {
            case startTimer
            case stopTimer
            case pauseTimer
            case skipTimer
            case saveStateTimer(value: LifeCoach.LocalTimerState)
            case scheduleTimerNotification
            case unregisterTimerNotification
            case notifySavedTimer
            
            var description: String {
                switch self {
                case .startTimer:
                    return "startTimer"
                case let .saveStateTimer(value: localTimerState):
                    return """
                saveStateTimer: seconds: \(localTimerState.localTimerSet.elapsedSeconds), state: \(localTimerState.state)
                startDate: \(localTimerState.localTimerSet.startDate), endDate: \(localTimerState.localTimerSet.endDate)
                """
                case .scheduleTimerNotification:
                    return "scheduleTimerNotification"
                case .notifySavedTimer:
                    return "notifySavedTimer"
                case .stopTimer:
                    return "stopTimer"
                case .unregisterTimerNotification:
                    return "unregisterTimerNotification"
                case .pauseTimer:
                    return "pauseTimer"
                case .skipTimer:
                    return "skipTimer"
                }
            }
        }
        
        var currentSetElapsedTime: TimeInterval = 0.0
        var state: LifeCoach.TimerCoutdownState = .stop
        
        private(set) var receivedCompletions = [StartCoundownCompletion]()
        private(set) var receivedMessages = [AnyMessage]()
        private(set) var receivedSkipCompletions = [SkipCountdownCompletion]()
        
        private var setOnStart: Result<LocalTimerSet, Error>?
        private var setOnSkip: Result<LocalTimerSet, Error>?
        
        func resetMessages() {
            receivedMessages = []
        }
        
        // MARK: - Timer
        func startCountdown(completion: @escaping StartCoundownCompletion) {
            state = .running
            receivedMessages.append(.startTimer)
            guard let setOnStart = setOnStart else { return }
            completion(setOnStart)
        }
        
        func stopCountdown() {
            state = .stop
            receivedMessages.append(.stopTimer)
        }
        
        func pauseCountdown() {
            state = .pause
            receivedMessages.append(.pauseTimer)
        }
        
        func skipCountdown(completion: @escaping SkipCountdownCompletion) {
            state = .stop
            receivedMessages.append(.skipTimer)
            guard let setOnSkip = setOnSkip else { return }
            completion(setOnSkip)
            receivedSkipCompletions.append(completion)
        }
        
        func deliversSetOnToggle(_ set: LocalTimerSet) {
            setOnStart = .success(set)
        }
        
        func deliversSetOnSkip(_ set: LocalTimerSet) {
            setOnSkip = .success(set)
        }
        
        func deliversSet(_ set: LocalTimerSet, index: Int = 0) {
            receivedSkipCompletions[index](.success(set))
        }
        
        // MARK: - Timer Store
        func loadTime() {}
        
        func saveTime(completion: @escaping (TimeInterval) -> Void) {}
        
        // MARK: - Local Timer State Store
        func retrieve() throws -> LifeCoach.LocalTimerState? {
            nil
        }
        
        func deleteState() throws {
            
        }
        
        func insert(state: LifeCoach.LocalTimerState) throws {
            receivedMessages.append(.saveStateTimer(value: state))
        }
        
        // MARK: - Scheduler
        func setSchedule(at scheduledDate: Date) throws {
            receivedMessages.append(.scheduleTimerNotification)
        }
        
        func unregisterTimerNotification() {
            receivedMessages.append(.unregisterTimerNotification)
        }
        
        // MARK: - Notify Saved Timer
        func notifySavedTimer() {
            receivedMessages.append(.notifySavedTimer)
        }
    }
}

private extension TimeCoach_Watch_AppApp {
    func simulateToggleTimerUserInteraction() {
        timerView.simulateToggleTimerUserInteraction()
    }
}
