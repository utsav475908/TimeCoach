import Foundation

public protocol LoadTimerState {
    func load() throws -> TimerState
}

public class LocalTimer: SaveTimerState, LoadTimerState {
    private let store: LocalTimerStore
    
    public init(store: LocalTimerStore) {
        self.store = store
    }
    
    public func save(state: TimerState) throws {
        try store.deleteState()
        try store.insert(state: state.local)
    }
    
    public func load() throws -> TimerState {
        try store.retrieve().toModel
    }
}

private extension ElapsedSeconds {
    var local: LocalElapsedSeconds {
        LocalElapsedSeconds(elapsedSeconds, startDate: startDate, endDate: endDate)
    }
}

private extension TimerState {
    var local: LocalTimerState {
        LocalTimerState(localElapsedSeconds: elapsedSeconds.local)
    }
}

private extension LocalTimerState {
    var toModel: TimerState {
        TimerState(elapsedSeconds: localElapsedSeconds.toElapseSeconds)
    }
}
