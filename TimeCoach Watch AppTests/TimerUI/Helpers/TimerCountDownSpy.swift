import Foundation
import Combine
import LifeCoach
import LifeCoachWatchOS

func pomodoroResponse(_ seconds: TimeInterval) -> ElapsedSeconds {
    let start = Date.now
    return ElapsedSeconds(seconds, startDate: start, endDate: start.adding(seconds: .pomodoroInSeconds))
}

func breakResponse(_ seconds: TimeInterval) -> ElapsedSeconds {
    let start = Date.now
    return ElapsedSeconds(seconds, startDate: start, endDate: start.adding(seconds: .breakInSeconds))
}

class TimerCountdownSpy: TimerCountdown, TimerCoutdown {
    
    private(set) var receivedStartCountdownCompletions = [StartCoundownCompletion]()
    private(set) var receivedSkipCountdownCompletions = [SkipCountdownCompletion]()
    private(set) var stopCallCount = 0
    private(set) var pauseCallCount = 0
 
    var state: LifeCoach.TimerState = .pause
    
    func startCountdown(completion: @escaping StartCoundownCompletion) {
        receivedStartCountdownCompletions.append(completion)
    }
    
    func stopCountdown() {
        stopCallCount += 1
    }
    
    func pauseCountdown() {
        pauseCallCount += 1
    }
    
    func skipCountdown(completion: @escaping SkipCountdownCompletion) {
        receivedSkipCountdownCompletions.append(completion)
    }
    
    private var stubs: [() -> ElapsedSeconds] = []
    private var pomodoroStubs: [() -> ElapsedSeconds] = []
    private var breakStubs: [() -> ElapsedSeconds] = []
    private(set) var receivedToggleCompletions = [TimerCompletion]()
    private(set) var receivedSkipCompletions = [TimerCompletion]()
    private(set) var receivedStopCompletions = [TimerCompletion]()
    
    init(stubs: [() -> ElapsedSeconds]) {
        self.stubs = stubs
    }
    
    init(pomodoroStub: [() -> ElapsedSeconds], breakStub: [() -> ElapsedSeconds]) {
        self.pomodoroStubs = pomodoroStub
        self.breakStubs = breakStub
    }
    
    func pauseCountdown(completion: @escaping TimerCompletion) {
        receivedToggleCompletions.append(completion)
    }
    
    func skipCountdown(completion: @escaping TimerCompletion) {
        receivedSkipCompletions.append(completion)
    }
    
    func startCountdown(completion: @escaping TimerCompletion) {
        receivedToggleCompletions.append(completion)
    }
    
    func stopCountdown(completion: @escaping TimerCompletion) {
        receivedStopCompletions.append(completion)
    }
    
    func completeSuccessfullyAfterFirstStart() {
        stubs.forEach { stub in
            receivedToggleCompletions[0](stub())
        }
    }
    
    func flushPomodoroTimes(at index: Int) {
        pomodoroStubs.forEach { stub in
            receivedStartCountdownCompletions[index](.success(stub().toLocal()))
        }
    }
    
    func flushBreakTimes(at index: Int) {
        breakStubs.forEach { stub in
            receivedStartCountdownCompletions[index](.success(stub().toLocal()))
        }
    }
    
    func completeSuccessfullyOnSkip(at index: Int = 0) {
        receivedSkipCountdownCompletions[index](.success(breakResponse(0).toLocal()))
    }
    
    func completeSuccessfullyOnPomodoroStop(at index: Int = 0) {
        receivedStartCountdownCompletions[index](.success(pomodoroResponse(0).toLocal()))
    }
    
    func completeSuccessfullyOnPomodoroToggle(at index: Int = 0) {
        if let lastGivenPomodoro = pomodoroStubs.last {
            receivedStartCountdownCompletions[index](.success(lastGivenPomodoro().toLocal()))
        }
    }
    
    static func delivers(after seconds: ClosedRange<TimeInterval>,
                         _ stub: @escaping (TimeInterval) -> ElapsedSeconds) -> TimerCountdownSpy {
        let start: Int = Int(seconds.lowerBound)
        let end: Int = Int(seconds.upperBound)
        let array: [TimeInterval] = (start...end).map { TimeInterval($0) }
        let stubs = array.map { seconds in
            {
                return stub(seconds)
            }
        }
        return TimerCountdownSpy(stubs: stubs)
    }
    
    static func delivers(
        afterPomoroSeconds pomodoroSeconds: ClosedRange<TimeInterval>,
        pomodoroStub: @escaping (TimeInterval) -> ElapsedSeconds,
        afterBreakSeconds breakSeconds: ClosedRange<TimeInterval>,
        breakStub: @escaping (TimeInterval) -> ElapsedSeconds)
    -> TimerCountdownSpy {
        let pomodoroStart: Int = Int(pomodoroSeconds.lowerBound)
        let pomodoroEnd: Int = Int(pomodoroSeconds.upperBound)
        let pomoroSeconds: [TimeInterval] = (pomodoroStart...pomodoroEnd).map { TimeInterval($0) }
        let pomodoroStub = pomoroSeconds.map { seconds in
            {
                return pomodoroStub(seconds)
            }
        }
        
        let breakStart: Int = Int(breakSeconds.lowerBound)
        let breakEnd: Int = Int(breakSeconds.upperBound)
        let breakSeconds: [TimeInterval] = (breakStart...breakEnd).map { TimeInterval($0) }
        let breakStub = breakSeconds.map { seconds in
            {
                return breakStub(seconds)
            }
        }
        
        return TimerCountdownSpy(pomodoroStub: pomodoroStub, breakStub: breakStub)
    }
    
    // MARK: Time Saver
    private(set) var saveTimeCallCount = 0
}


extension ElapsedSeconds {
    func toLocal() -> LocalElapsedSeconds {
        LocalElapsedSeconds(elapsedSeconds, startDate: startDate, endDate: endDate)
    }
}
