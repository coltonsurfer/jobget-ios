import SwiftUI
import Observation

enum Tab: Hashable {
    case jobs, messages, schedule, profile
}

@Observable
final class AppState {
    var selectedTab: Tab = .jobs
    var messagesPath: [UUID] = []

    var jobs: [Job] = MockData.jobs
    var savedJobIDs: Set<UUID> = []
    var applications: [JobApplication] = MockData.applications()
    var conversations: [Conversation] = MockData.conversations()
    var shifts: [Shift] = MockData.shifts()
    var teammates: [Teammate] = MockData.teammates
    var profile: UserProfile = MockData.profile

    var searchText: String = ""
    var filter: JobFilter = .all

    init(arguments: [String] = CommandLine.arguments) {
        // Demo/testing hooks: `--tab schedule|messages|profile`, `--open-chat` (first conversation).
        if let index = arguments.firstIndex(of: "--tab"), index + 1 < arguments.count {
            switch arguments[index + 1] {
            case "messages": selectedTab = .messages
            case "schedule": selectedTab = .schedule
            case "profile": selectedTab = .profile
            default: break
            }
        }
        if arguments.contains("--open-chat"), let first = conversations.first {
            selectedTab = .messages
            messagesPath = [first.id]
        }
    }

    // MARK: Jobs

    var filteredJobs: [Job] {
        jobs.filter { job in
            let matchesSearch = searchText.isEmpty
                || job.title.localizedCaseInsensitiveContains(searchText)
                || job.company.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = true
            case .hiringToday: matchesFilter = job.urgentlyHiring
            case .partTime: matchesFilter = job.type == .partTime
            case .fullTime: matchesFilter = job.type == .fullTime
            case .noExperience: matchesFilter = job.noExperience
            case .weekends: matchesFilter = job.schedule.contains { $0.localizedCaseInsensitiveContains("weekend") }
            }
            return matchesSearch && matchesFilter
        }
    }

    var hiringTodayJobs: [Job] { jobs.filter(\.urgentlyHiring) }

    func isSaved(_ job: Job) -> Bool { savedJobIDs.contains(job.id) }

    func toggleSaved(_ job: Job) {
        Haptics.light()
        if savedJobIDs.contains(job.id) { savedJobIDs.remove(job.id) } else { savedJobIDs.insert(job.id) }
    }

    func application(for job: Job) -> JobApplication? {
        applications.first { $0.job.id == job.id }
    }

    func hasApplied(to job: Job) -> Bool { application(for: job) != nil }

    @discardableResult
    func apply(to job: Job) -> Conversation {
        Haptics.success()
        if let existing = conversation(forCompany: job.company) { return existing }
        applications.insert(JobApplication(job: job, date: .now, status: .applied), at: 0)
        let firstName = profile.name.split(separator: " ").first.map(String.init) ?? profile.name
        var conversation = Conversation(
            counterpartName: job.hiringManager,
            counterpartRole: "Hiring Manager",
            company: job.company,
            logoSymbol: job.logoSymbol,
            logoColor: job.logoColor,
            messages: [ChatMessage(text: "You applied to \(job.title) at \(job.company)", isFromMe: true, date: .now, kind: .system)],
            unreadCount: 0,
            quickReplies: ["Yes, I'm available", "What days work for you?", "Can you share the pay range?"],
            pendingReplies: [
                "Great! How does Thursday at 2pm work for a quick 15-minute chat?",
                "Perfect, I'll send a confirmation. See you then!",
                "Sounds good—let me know if anything changes.",
            ]
        )
        conversation.isTyping = true
        conversations.insert(conversation, at: 0)
        let conversationID = conversation.id
        let reply = "Hi \(firstName)! Thanks for applying to the \(job.title) role. I'd love to chat this week—are you available for a quick call?"
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            self.deliver(reply, to: conversationID)
            self.markViewed(job)
        }
        return conversation
    }

    private func markViewed(_ job: Job) {
        if let index = applications.firstIndex(where: { $0.job.id == job.id }), applications[index].status == .applied {
            applications[index].status = .viewed
        }
    }

    // MARK: Messages

    var totalUnread: Int { conversations.reduce(0) { $0 + $1.unreadCount } }

    func conversation(id: UUID) -> Conversation? { conversations.first { $0.id == id } }

    func conversation(forCompany company: String) -> Conversation? { conversations.first { $0.company == company } }

    func openConversation(_ id: UUID) {
        selectedTab = .messages
        messagesPath = [id]
    }

    func markRead(_ id: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].unreadCount = 0
    }

    func send(_ text: String, in id: UUID) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        Haptics.light()
        conversations[index].messages.append(ChatMessage(text: trimmed, isFromMe: true, date: .now))
        guard !conversations[index].pendingReplies.isEmpty else { return }
        let reply = conversations[index].pendingReplies.removeFirst()
        conversations[index].isTyping = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            self.deliver(reply, to: id)
        }
    }

    private func deliver(_ text: String, to id: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].isTyping = false
        conversations[index].messages.append(ChatMessage(text: text, isFromMe: false, date: .now))
        if !(selectedTab == .messages && messagesPath.last == id) {
            conversations[index].unreadCount += 1
        }
        // Move the active conversation to the top of the inbox.
        let conversation = conversations.remove(at: index)
        conversations.insert(conversation, at: 0)
    }

    // MARK: Schedule

    var hoursThisWeek: Double { shifts.reduce(0) { $0 + $1.hours } }

    func shifts(on day: Date) -> [Shift] {
        shifts.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }
}
