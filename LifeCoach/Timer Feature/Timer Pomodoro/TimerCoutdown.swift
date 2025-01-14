import Foundation

public enum TimerCountdownState {
    case pause
    case running
    case stop
}

public protocol TimerCountdown {
    
    var currentSetElapsedTime: TimeInterval { get }
    var state: TimerCountdownState { get }
    var currentTimerSet: LocalTimerSet { get }
    
    typealias Result = Swift.Result<(LocalTimerSet, TimerCountdownState), Error>
    typealias StartCoundownCompletion = (Result) -> Void
    typealias SkipCountdownCompletion = (Result) -> Void
    func startCountdown(completion: @escaping StartCoundownCompletion)
    func stopCountdown()
    func pauseCountdown()
    func skipCountdown(completion: @escaping SkipCountdownCompletion)
}
