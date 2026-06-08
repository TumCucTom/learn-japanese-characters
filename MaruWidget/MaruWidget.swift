import WidgetKit
import SwiftUI

@main
struct MaruWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyKanaWidget()
        FlashcardWidget()
        LockScreenWidget()
    }
}