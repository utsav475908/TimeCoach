//  TimeCoach Watch App
//  Created by Daniel Torres on 12/1/22.

import SwiftUI
import LifeCoachWatchOS
import LifeCoach
import Combine

@main
struct TimeCoach_Watch_AppApp: App {
    var timerView: TimerView
    @State private var root: TimeCoachRoot
    
    init() {
        let root = TimeCoachRoot()
        self.root = root
        self.timerView = TimerViewComposer.createTimer(
            customFont: CustomFont.timer.font,
            timerLoader: root
                .skipPublisher
                .merge(with: root.startPublisher)
                .eraseToAnyPublisher(),
            skipHandler: root.skipHandler
        )
    }

    init(timerCoundown: TimerCountdown) {
        let root = TimeCoachRoot(timerCoundown: timerCoundown)
        self.root = root
        self.timerView = TimerViewComposer.createTimer(
            customFont: CustomFont.timer.font,
            timerLoader: root
                .skipPublisher
                .merge(with: root.startPublisher)
                .eraseToAnyPublisher(),
            skipHandler: root.skipHandler
        )
    }
    
    var body: some Scene {
        WindowGroup {
            timerView
        }
    }
}
