import ViewInspector
import SwiftUI
import Combine
import XCTest
import LifeCoach
import LifeCoachWatchOS
import TimeCoach_Watch_App

extension TimerView: Inspectable { }

final class TimerUIIntegrationTests: XCTestCase {
    func test_onInitialLoad_shouldPresentPomodoroTimerAsDefault() {
        let (sut, _) = makeSUT()
        
        let timerString = sut.timerLabelString()
        
        XCTAssertEqual(timerString, .defaultPomodoroTimerString, "Should present pomodoro Timer on view load.")
    }
    
    func test_onPlay_sendsMessageToTimerHandler() {
        var playHandlerCount = 0
        let (sut, _) = makeSUT(playHandler: {
            playHandlerCount += 1
        })
        
        sut.simulateToggleTimerUserInteraction()
        
        XCTAssertEqual(playHandlerCount, 1, "Should execute playHandler once.")
        
        sut.simulateToggleTimerUserInteraction()
        
        XCTAssertEqual(playHandlerCount, 2, "Should execute playHandler twice.")
    }
    
    func test_onSkip_sendsMessageToSkipHandler() {
        var skipHandlerCount = 0
        let (sut, _) = makeSUT(skipHandler: {
            skipHandlerCount += 1
        })
        
        sut.simulateSkipTimerUserInteraction()
        
        XCTAssertEqual(skipHandlerCount, 1, "Should execute skipHandler once.")
        
        sut.simulateSkipTimerUserInteraction()
        
        XCTAssertEqual(skipHandlerCount, 2, "Should execute skipHandler twice.")
    }
    
    func test_onStop_sendsMessageToStopHandler() {
        var stopHandlerCount = 0
        let (sut, _) = makeSUT(stopHandler: {
            stopHandlerCount += 1
        })
        
        sut.simulateStopTimerUserInteraction()
        
        XCTAssertEqual(stopHandlerCount, 1, "Should execute stop handler once.")
        
        sut.simulateStopTimerUserInteraction()
        
        XCTAssertEqual(stopHandlerCount, 2, "Should execute stop handler twice.")
    }
    
    // MARK: - Helpers
    private func makeElapsedSeconds(
        _ seconds: TimeInterval,
        startDate: Date,
        endDate: Date
    ) -> ElapsedSeconds {
        ElapsedSeconds(seconds, startDate: startDate, endDate: endDate)
    }
    
    private func makeSUT(
        playHandler: (() -> Void)? = nil,
        skipHandler: (() -> Void)? = nil,
        stopHandler: (() -> Void)? = nil
    ) -> (sut: TimerView, spy: TimerPublisherSpy) {
        let timeLoader = TimerPublisherSpy()
        
        let timerView = TimerViewComposer.createTimer(
            customFont: "",
            viewModel: TimerViewModel(),
            togglePlayback: playHandler,
            skipHandler: skipHandler,
            stopHandler: stopHandler
        )
        
        return (timerView, timeLoader)
    }
    
    private class TimerPublisherSpy {
        private var timerElapsedSeconds = [PassthroughSubject<ElapsedSeconds, Error>]()
        lazy var loadTimer: PassthroughSubject<ElapsedSeconds, Error> = {
            return PassthroughSubject<ElapsedSeconds, Error>()
        }()
    
        func completesSuccessfullyWith(timeElapsed: ElapsedSeconds) {
            loadTimer.send(timeElapsed)
        }
    }
}