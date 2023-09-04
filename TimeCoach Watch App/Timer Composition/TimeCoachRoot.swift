import Foundation
import SwiftUI
import LifeCoach
import LifeCoachWatchOS
import Combine
import UserNotifications
import WidgetKit

class TimeCoachRoot {
    private var timerSave: TimerSave?
    private var timerLoad: TimerLoad?
    
    // Pomodoro State
    private lazy var currentIsBreakMode: CurrentValueSubject<IsBreakMode, Error> = .init(false)
    
    // Timer
    private var currenDate: () -> Date = Date.init
    var timerCountdown: TimerCountdown?
    private var regularTimer: RegularTimer?
    private lazy var currentSubject: RegularTimer.CurrentValuePublisher = .init(
        TimerState(timerSet: TimerSet.init(0, startDate: .init(), endDate: .init()),
                   state: .stop))
    
    // Local Timer
    private lazy var stateTimerStore: LocalTimerStore = UserDefaultsTimerStore(storeID: "group.timeCoach.timerState")
    private lazy var localTimer: LocalTimer = LocalTimer(store: stateTimerStore)
    
    // Timer Notification Scheduler
    private lazy var scheduler: LifeCoach.Scheduler = UserNotificationsScheduler(with: UNUserNotificationCenter.current())
    private lazy var timerNotificationScheduler = DefaultTimerNotificationScheduler(scheduler: scheduler)
    
    private lazy var UNUserNotificationdelegate: UNUserNotificationCenterDelegate? = { [weak self] in
        return self?.createUNUserNotificationdelegate()
    }()
    private lazy var unregisterNotifications: (() -> Void) = Self.unregisterNotificationsFromUNUserNotificationCenter
    
    static func unregisterNotificationsFromUNUserNotificationCenter() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Timer Saved Notifications
    var needsUpdate: Bool = false
    private var notifySavedTimer: (() -> Void)?
    private lazy var timerSavedNofitier: LifeCoach.TimerStoreNotifier = DefaultTimerStoreNotifier(
        completion: notifySavedTimer ?? {
            WidgetCenter.shared.reloadAllTimelines()
        }
    )
    
    // Concurrency
    private lazy var mainScheduler: AnyDispatchQueueScheduler = DispatchQueue(
        label: "com.danstorre.timeCoach.watchkitapp",
        qos: .userInitiated
    ).eraseToAnyScheduler()
    
    private lazy var timerScheduler: AnyDispatchQueueScheduler = DispatchQueue(
        label: "com.danstorre.timeCoach.watchkitapp.timer",
        qos: .default
    ).eraseToAnyScheduler()
    
    convenience init(infrastructure: Infrastructure) {
        self.init()
        self.timerSave = infrastructure.timerState
        self.timerLoad = infrastructure.timerState
        self.timerCountdown = infrastructure.timerCountdown
        self.stateTimerStore = infrastructure.stateTimerStore
        self.scheduler = infrastructure.scheduler
        self.notifySavedTimer = infrastructure.notifySavedTimer
        self.currenDate = infrastructure.currentDate
        self.unregisterNotifications = infrastructure.unregisterTimerNotification ?? {}
        self.mainScheduler = infrastructure.mainScheduler
        self.timerScheduler = infrastructure.mainScheduler
    }
    
    func createTimer() -> TimerView {
        let date = currenDate()
        timerCountdown = createTimerCountDown(from: date)
        currentSubject = Self.createFirstValuePublisher(from: date)
        let timerPlayerAdapterState = TimerCountdownToTimerStateAdapter(timer: timerCountdown!, currentDate: currenDate)
        regularTimer = Self.createPomodorTimer(with: timerPlayerAdapterState, and: currentSubject)
        
        if let timerCountdown = timerCountdown as? FoundationTimerCountdown {
            self.timerSave = timerCountdown
            self.timerLoad = timerCountdown
        }
        
        let timerControlPublishers = TimerControlsPublishers(playPublisher: handlePlay,
                                                             skipPublisher: handleSkip,
                                                             stopPublisher: handleStop,
                                                             pausePublisher: handlePause,
                                                             isPlaying: timerPlayerAdapterState.isPlayingPublisherProvider())
        
        UNUserNotificationCenter.current().delegate = UNUserNotificationdelegate
        
        return TimerViewComposer.createTimer(timerControlPublishers: timerControlPublishers,
                                             isBreakModePublisher: currentIsBreakMode)
    }
    
    private func createUNUserNotificationdelegate() -> UNUserNotificationCenterDelegate? {
        let localTimer = self.localTimer
        let timerSavedNofitier = self.timerSavedNofitier
        let notificationReceiverProcess = TimerNotificationReceiverFactory
            .notificationReceiverProcessWith(timerStateSaver: localTimer,
                                             timerStoreNotifier: timerSavedNofitier,
                                             playNotification: WKInterfaceDevice.current(),
                                             getTimerState: { [weak self] in
                self?.getTimerState()
            })
        return UserNotificationsReceiver(receiver: notificationReceiverProcess)
    }
    
    private func getTimerState() -> TimerState? {
        guard let timerSet = timerCountdown?.currentTimerSet.toModel,
              let state = timerCountdown?.state.toModel else {
            return nil
        }
        return TimerState(timerSet: timerSet, state: state)
    }
    
    func goToBackground() {
        timerSave?.saveTime(completion: { time in })
    }
    
    func goToForeground() {
        timerLoad?.loadTime()
    }
    
    func gotoInactive() {
        saveTimerProcessPublisher(timerCoachRoot: self)?
        .subscribe(Subscribers.Sink(receiveCompletion: { _ in
        }, receiveValue: { _ in }))
    }
    
    private struct UnexpectedError: Error {}
    
    private func handlePlay() -> RegularTimer.TimerSetPublisher {
        return playPublisher()
            .subscribe(on: timerScheduler)
            .dispatchOnMainQueue()
            .processFirstValue { [weak self] timerState in
                self?.registerTimerProcessPublisher(timerState: timerState)
                    .subscribe(Subscribers.Sink(receiveCompletion: { _ in
                    }, receiveValue: { _ in }))
            }
            .eraseToAnyPublisher()
    }
    
    private func handleStop() -> RegularTimer.VoidPublisher {
        return stopPublisher()
            .subscribe(on: timerScheduler)
            .dispatchOnMainQueue()
            .processFirstValue { [weak self] _ in
                self?.unregisterTimerProcessPublisher()
                    .subscribe(Subscribers.Sink(receiveCompletion: { _ in
                    }, receiveValue: { _ in }))
            }
            .flatsToVoid()
            .eraseToAnyPublisher()
    }
    
    private func handlePause() -> RegularTimer.VoidPublisher {
        return pausePublisher()
            .subscribe(on: timerScheduler)
            .dispatchOnMainQueue()
            .processFirstValue { [weak self] timerState in
                self?.unregisterTimerProcessPublisher()
                    .subscribe(Subscribers.Sink(receiveCompletion: { _ in
                    }, receiveValue: { _ in }))
            }
            .flatsToVoid()
            .eraseToAnyPublisher()
    }
    
    private func handleSkip() -> RegularTimer.TimerSetPublisher {
        return skipPublisher()
            .subscribe(on: timerScheduler)
            .dispatchOnMainQueue()
            .processFirstValue { [weak self] value in
                self?.unregisterTimerProcessPublisher()
                    .subscribe(Subscribers.Sink(receiveCompletion: { _ in
                    }, receiveValue: { _ in }))
            }
            .eraseToAnyPublisher()
    }
    
    private func stopPublisher() -> RegularTimer.TimerSetPublisher {
        regularTimer!.stopPublisher(currentSubject: currentSubject)()
    }
    
    private func playPublisher() -> RegularTimer.TimerSetPublisher {
        regularTimer!.playPublisher(currentSubject: currentSubject)()
    }
    
    private func pausePublisher() -> RegularTimer.TimerSetPublisher {
        regularTimer!.pausePublisher(currentSubject: currentSubject)()
    }
    
    private func skipPublisher() -> RegularTimer.TimerSetPublisher {
        regularTimer!.skipPublisher(currentSubject: currentSubject)()
    }
    
    private func unregisterTimerProcessPublisher() -> RegularTimer.TimerSetPublisher {
        let currentSubject = currentSubject
        let unregisterNotifications = unregisterNotifications
        
        return Just(())
            .setsNeedsUpdate(self, needsUpdate: true)
            .unregisterTimerNotifications(unregisterNotifications)
            .flatsToTimerSetPublisher(currentSubject)
            .tryMap { $0 }
            .eraseToAnyPublisher()
    }
    
    private func registerTimerProcessPublisher(timerState: TimerState) -> RegularTimer.TimerSetPublisher {
        let timerNotificationScheduler = timerNotificationScheduler
        let currentIsBreakMode = currentIsBreakMode
        
        return Just(timerState)
            .setsNeedsUpdate(self, needsUpdate: true)
            .scheduleTimerNotfication(scheduler: timerNotificationScheduler, isBreak: currentIsBreakMode.value)
            .tryMap { $0 }
            .eraseToAnyPublisher()
    }
    
    private func saveTimerProcessPublisher(
        timerCoachRoot: TimeCoachRoot
    ) -> AnyPublisher<TimerState, Never>? {
        guard let timerCountdown = timerCoachRoot.timerCountdown,
              timerCoachRoot.needsUpdate else {
            return nil
        }
        let currentIsBreakMode = timerCoachRoot.currentIsBreakMode.value
        
        return Just(())
            .mapsTimerSetAndState(timerCountdown: timerCountdown, currentIsBreakMode: currentIsBreakMode)
            .saveTimerState(saver: localTimer)
            .subscribe(on: mainScheduler)
            .dispatchOnMainQueue()
            .notifySavedTimer(notifier: timerSavedNofitier)
            .setsNeedsUpdate(self, needsUpdate: false)
            .eraseToAnyPublisher()
    }
}
