import SwiftUI

public class TimerViewModel: ObservableObject {
    @Published public var timerString: String = .defaultPomodoroTimerString
    public var isBreak: Bool
    
    public var mode: TimePresentation = .full {
        didSet {
            guard !hasFinished else { return }
            switch mode {
            case .full:
                timerString = currentTimerString
            case .none:
                timerString = "--:--"
            }
        }
    }
    private var hasFinished = false
    private let formatter = makeTimerFormatter()
    private var currentTimerString: String = .defaultPomodoroTimerString
    
    public enum TimePresentation {
        case full
        case none
    }
    
    public init(isBreak: Bool) {
        self.isBreak = isBreak
    }
    
    public func delivered(elapsedTime: TimerSet) {
        hasFinished = false
        let startDate = elapsedTime.startDate
        let endDate = elapsedTime.endDate.adding(seconds: -elapsedTime.elapsedSeconds)
        
        guard endDate.timeIntervalSince(startDate) > 0 else {
            timerString = "00:00"
            hasFinished = true
            return
        }
        
        currentTimerString = formatter.string(from: startDate, to: endDate)!
        timerString = makeStringFrom(startDate: startDate, endDate: endDate, elapsedTime: elapsedTime)
    }
    
    private func makeStringFrom(startDate: Date, endDate: Date, elapsedTime: TimerSet) -> String {
        switch mode {
        case .none:
            return "--:--"
        case .full:
            return currentTimerString
        }
    }
}