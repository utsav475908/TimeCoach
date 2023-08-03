import XCTest
import LifeCoach

class TimerGlancePresentation {
    enum Event {
        case showIdle
    }
    
    var onShowEvent: (() -> Void)?
    
    
    func check(timerState: TimerState) {
        
    }
}

final class TimerGlancePresentationTests: XCTestCase {
    func test_checkTimerState_onPauseTimerStateSendsShowIdle() {
        let pauseState = makeAnyTimerState(state: .pause)
        let sut = makeSUT()
        let result = resultOnStatusCheck(from: sut)
        
        sut.check(timerState: pauseState)
        
        XCTAssertEqual(result, .showIdle)
    }
    
    func test_checkTimerState_onStopTimerStateSendsShowIdle() {
        let stopState = makeAnyTimerState(state: .stop)
        let sut = makeSUT()
        let result = resultOnStatusCheck(from: sut)
        
        sut.check(timerState: stopState)
        
        XCTAssertEqual(result, .showIdle)
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> TimerGlancePresentation {
        let sut = TimerGlancePresentation()
            
        trackForMemoryLeak(instance: sut, file: file, line: line)
        
        return sut
    }
    
    private func resultOnStatusCheck(from: TimerGlancePresentation) -> TimerGlancePresentation.Event {
        .showIdle
    }
}
