import Foundation

public class PomodoroTimer: RegularTimer {
    private let timer: TimerCoutdown
    private let timeReceiver: (Result) -> Void
    
    public enum Error: Swift.Error {
        case timerError
    }
    
    public typealias Result = Swift.Result<ElapsedSeconds, Error>
    
    public init(timer: TimerCoutdown, timeReceiver: @escaping (Result) -> Void) {
        self.timer = timer
        self.timeReceiver = timeReceiver
    }
    
    public func start() {
        timer.startCountdown() { [weak self] result in
            guard let self = self else { return }
            if case .failure = result {
                self.timer.stopCountdown()
            }
            
            self.timeReceiver(Self.resolveResult(result: result))
        }
    }
    
    public func pause() {
        timer.pauseCountdown()
    }
    
    public func stop() {
        timer.stopCountdown()
    }
    
    public func skip() {
        timer.skipCountdown() { [weak self] result in
            guard let self = self else { return }
            if case .failure = result {
                self.timer.stopCountdown()
            }
            
            self.timeReceiver(Self.resolveResult(result: result))
        }
    }
    
    private static func resolveResult(result: TimerCoutdown.Result) -> Result {
        switch result {
        case let .success(localElapsedSeconds):
            return .success(localElapsedSeconds.toElapseSeconds)
        case .failure:
            return .failure(.timerError)
        }
    }
}
