//
//  TimeCoachRoot.swift
//  TimeCoach Watch App
//
//  Created by Daniel Torres on 6/27/23.
//

import Foundation
import Combine
import LifeCoach

extension TimeCoachRoot {
    // MARK: Factory methods
    func createTimerCountDown(from date: Date) -> TimerCoutdown {
        #if os(watchOS)
        timerCoutdown ?? FoundationTimerCountdown(startingSet: .pomodoroSet(date: date),
                                                  nextSet: .breakSet(date: date))
        #elseif os(xrOS)
        FoundationTimerCountdown(startingSet: .pomodoroSet(date: date),
                                                  nextSet: .breakSet(date: date))
        #endif
    }
    
    static func createPomodorTimer(with timer: TimerCoutdown, and currentValue: RegularTimer.CurrentValuePublisher) -> RegularTimer {
        PomodoroTimer(timer: timer, timeReceiver: { result in
            switch result {
            case let .success(seconds):
                currentValue.send(seconds)
            case let .failure(error):
                currentValue.send(completion: .failure(error))
            }
        })
    }
    
    static func createFirstValuePublisher(from date: Date) -> RegularTimer.CurrentValuePublisher {
        CurrentValueSubject<ElapsedSeconds, Error>(ElapsedSeconds(0,
                                                                  startDate: date,
                                                                  endDate: date.adding(seconds: .pomodoroInSeconds)))
    }
}

extension LocalElapsedSeconds {
    static func pomodoroSet(date: Date) -> LocalElapsedSeconds {
        LocalElapsedSeconds(0, startDate: date, endDate: date.adding(seconds: .pomodoroInSeconds))
    }
    
    static func breakSet(date: Date) -> LocalElapsedSeconds {
        LocalElapsedSeconds(0, startDate: date, endDate: date.adding(seconds: .breakInSeconds))
    }
}