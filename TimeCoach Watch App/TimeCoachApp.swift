//  TimeCoach Watch App
//  Created by Daniel Torres on 12/1/22.

import SwiftUI
import LifeCoachWatchOS
import LifeCoach
import Combine

public enum CustomFont {
    case timer
    
    public var font: String {
        "Digital dream Fat"
    }
}

class TimeCoachRoot {
    init() {}
    
    private lazy var timerCoundown: TimerCountdown = {
        return PomodoroLocalTimer(startDate: .now,
                                  primaryInterval: .pomodoroInSeconds,
                                  secondaryTime: .breakInSeconds)
    }()
    
    init(timerCoundown: TimerCountdown) {
        self.timerCoundown = timerCoundown
    }
    
    func makeTimerLoader() -> () -> AnyPublisher<ElapsedSeconds, Error> {
        return { [timerCoundown] in
            return timerCoundown
                .getPublisher()
                .map({ $0.timeElapsed })
                .eraseToAnyPublisher()
        }
    }
}

@main
struct TimeCoach_Watch_AppApp: App {
    
    var timerView: TimerView = TimerViewComposer.createTimer(customFont: CustomFont.timer.font,
                                                             timerLoader: Self.root.makeTimerLoader())
    
    private static var root: TimeCoachRoot = TimeCoachRoot()
    
    init() {}

    init(timerCoundown: TimerCountdown) {
        Self.root = TimeCoachRoot(timerCoundown: timerCoundown)
        self.timerView = TimerViewComposer.createTimer(customFont: CustomFont.timer.font,
                                                       timerLoader: Self.root.makeTimerLoader())
    }
    
    
    var body: some Scene {
        WindowGroup {
            timerView
        }
    }
}


public extension TimerCountdown {
    typealias Publisher = AnyPublisher<LocalElapsedSeconds, Error>

    func getPublisher() -> Publisher {
        return Deferred {
            Future { completion in
                startCountdown(completion: { localElapsedSeconds in
                    return completion(.success(localElapsedSeconds))
                })
            }
        }
        .eraseToAnyPublisher()
    }
}
