import SwiftUI

// The iPhone side only exists to carry the watch app onto your watch.
@main
struct SchoolBellPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Image(systemName: "applewatch")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                Text("School Bell")
                    .font(.largeTitle.bold())
                Text("This app runs on your Apple Watch.\n\nOpen the Watch app on this iPhone, scroll down to Available Apps, and tap Install next to School Bell.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
    }
}
