import SwiftUI
import TimeCoachVisionOS
import LifeCoach

struct PreviewTimer: View {
    var body: some View {
        TimerView(
            controlsViewModel: ControlsViewModel(),
            timerViewModel: TimerViewModel(),
            customFont: CustomFont.timer.font
        )
    }
}

struct PreviewTimer_Previews: PreviewProvider {
    static var previews: some View {
        PreviewTimer()
    }
}
