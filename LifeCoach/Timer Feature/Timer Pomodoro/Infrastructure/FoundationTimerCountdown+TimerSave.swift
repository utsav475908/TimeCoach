import Foundation

extension FoundationTimerCountdown: TimerSave {
    public func saveTime(completion: @escaping (TimeInterval) -> Void) {
        guard let timer = currentTimer, timer.isValid else { return }
        timeAtSave = CFAbsoluteTimeGetCurrent()
        let elapsedDate = currentSet.startDate.adding(seconds: currentSet.elapsedSeconds)
        
        let remainingSeconds = currentSet.endDate.timeIntervalSince(elapsedDate)
        completion(remainingSeconds)
    }
}
