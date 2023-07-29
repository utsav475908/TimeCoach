import Foundation

public protocol LocalTimerStore {
    func retrieve() throws
    func deleteState() throws
    func insert(state: LocalTimerState) throws
}

public struct LocalTimerState: Equatable {
    public let localElapsedSeconds: LocalElapsedSeconds
    
    public init(localElapsedSeconds: LocalElapsedSeconds) {
        self.localElapsedSeconds = localElapsedSeconds
    }
}
