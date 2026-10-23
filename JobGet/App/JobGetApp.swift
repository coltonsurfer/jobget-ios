import SwiftUI

@main
struct JobGetApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appState)
                .tint(.jgPurple)
        }
    }
}
