import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state
        TabView(selection: $state.selectedTab) {
            JobsFeedView()
                .tabItem { Label("Jobs", systemImage: "magnifyingglass") }
                .tag(Tab.jobs)

            MessagesView()
                .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right.fill") }
                .badge(state.totalUnread)
                .tag(Tab.messages)

            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag(Tab.schedule)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(Tab.profile)
        }
    }
}

#Preview {
    RootTabView().environment(AppState())
}
