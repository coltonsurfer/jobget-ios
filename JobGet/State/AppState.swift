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
    var trades: [ShiftTrade] = []
    var teammates: [Teammate] = MockData.teammates
    var profile: UserProfile = MockData.profile
    /// Demo-only: preview the store manager's approval queue and act on it as Maya.
    var managerMode = false

    var searchText: String = ""
    var filter: JobFilter = .all

    init(arguments: [String] = CommandLine.arguments) {
        let board = MockData.openCoverBoard()
        shifts += board.shifts
        trades = board.trades
        // Demo/testing hooks: `--tab schedule|messages|profile`, `--open-chat` (first conversation), `--manager`.
        managerMode = arguments.contains("--manager")
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

    private func post(_ message: ChatMessage, to id: UUID, quickReplies: [String]? = nil) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].messages.append(message)
        if let quickReplies { conversations[index].quickReplies = quickReplies }
        if !message.isFromMe, !(selectedTab == .messages && messagesPath.last == id) {
            conversations[index].unreadCount += 1
        }
        let conversation = conversations.remove(at: index)
        conversations.insert(conversation, at: 0)
    }

    // MARK: Schedule

    var myShifts: [Shift] { shifts.filter { $0.owner == profile.name } }

    var hoursThisWeek: Double { myShifts.reduce(0) { $0 + $1.hours } }

    /// Shifts shown on my schedule: the ones I own, plus ones I gave away (kept, greyed, as "Covered").
    var scheduleShifts: [Shift] {
        shifts
            .filter { shift in shift.owner == profile.name || coveredTrade(for: shift) != nil }
            .sorted { $0.startDate < $1.startDate }
    }

    func shifts(on day: Date) -> [Shift] {
        scheduleShifts.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    func shift(id: UUID) -> Shift? { shifts.first { $0.id == id } }

    // MARK: Shift trades

    var teamConversationID: UUID? { conversations.first { $0.counterpartName == MockData.teamThreadName }?.id }
    var managerConversationID: UUID? { conversations.first { $0.counterpartName == MockData.managerName }?.id }
    var manager: Teammate? { teammates.first(where: \.isManager) }

    func trade(id: UUID) -> ShiftTrade? { trades.first { $0.id == id } }

    /// The live trade attached to a shift (posted or claimed), if any.
    func activeTrade(for shift: Shift) -> ShiftTrade? {
        trades.first { $0.shiftID == shift.id && $0.status.isActive }
    }

    /// Latest trade for a shift in any state — drives the status pill on shift cards.
    func latestTrade(for shift: Shift) -> ShiftTrade? {
        trades.filter { $0.shiftID == shift.id }.max { $0.postedAt < $1.postedAt }
    }

    private func coveredTrade(for shift: Shift) -> ShiftTrade? {
        trades.first { $0.shiftID == shift.id && $0.posterName == profile.name && $0.status == .approved }
    }

    /// Open Cover Board: coworker shifts at my location posted for trade that I haven't claimed.
    var openBoardTrades: [ShiftTrade] {
        trades
            .filter { $0.status == .posted && $0.posterName != profile.name }
            .sorted { (shift(id: $0.shiftID)?.startDate ?? .distantFuture) < (shift(id: $1.shiftID)?.startDate ?? .distantFuture) }
    }

    /// Manager approval queue: claimed trades awaiting Maya's 1-tap decision.
    var pendingApprovals: [ShiftTrade] {
        trades.filter { $0.status == .claimed }.sorted { $0.postedAt < $1.postedAt }
    }

    func canTrade(_ shift: Shift) -> Bool {
        shift.owner == profile.name && activeTrade(for: shift) == nil && shift.startDate.timeIntervalSinceNow > 2 * 3600
    }

    /// Same-location coworkers who could take the shift: not the manager, not already on it.
    func eligibleCoworkers(for shift: Shift) -> [Teammate] {
        teammates.filter { !$0.isManager && $0.name != profile.name && !shift.coworkers.contains($0.name) }
    }

    /// Overlapping shift check used for the "can I pick this up" eligibility reason.
    func conflict(for shift: Shift) -> Shift? {
        myShifts.first { $0.id != shift.id && $0.startDate < shift.endDate && shift.startDate < $0.endDate }
    }

    func projectedHours(for name: String, adding shift: Shift) -> Double {
        let current = name == profile.name ? hoursThisWeek : Double.random(in: 22...30).rounded()
        return current + shift.hours
    }

    @discardableResult
    func postTrade(_ shift: Shift, mode: TradeMode, note: String, swapPreference: String?) -> ShiftTrade {
        Haptics.success()
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trade = ShiftTrade(shiftID: shift.id, posterName: profile.name, mode: mode, note: trimmed,
                               swapPreference: mode == .swap ? swapPreference : nil, status: .posted)
        trades.append(trade)
        if let teamID = teamConversationID {
            post(ChatMessage(text: "You posted \(shift.shortLabel) for trade · \(mode.rawValue)", isFromMe: true, date: .now, kind: .system), to: teamID)
            post(ChatMessage(text: "Shift trade", isFromMe: true, date: .now, kind: .shiftTrade(tradeID: trade.id)), to: teamID,
                 quickReplies: ["Thanks y'all 🙏", "Anyone free \(shift.date.formatted(.dateTime.weekday(.wide)))?", "Keys are in the drawer"])
        }
        simulatePeerClaim(trade.id)
        return trade
    }

    func withdrawTrade(_ tradeID: UUID) {
        guard let index = trades.firstIndex(where: { $0.id == tradeID }), trades[index].status == .posted else { return }
        Haptics.light()
        trades[index].status = .withdrawn
        trades[index].decidedAt = .now
        if let teamID = teamConversationID, let shift = shift(id: trades[index].shiftID) {
            post(ChatMessage(text: "You withdrew \(shift.shortLabel) from the Cover Board", isFromMe: true, date: .now, kind: .system), to: teamID)
        }
    }

    /// Demo: a same-location coworker claims the posted shift a few seconds later, so the manager queue fills itself.
    private func simulatePeerClaim(_ tradeID: UUID) {
        Task { @MainActor in
            if let teamID = teamConversationID, let index = conversations.firstIndex(where: { $0.id == teamID }) {
                try? await Task.sleep(for: .seconds(1.8))
                guard trade(id: tradeID)?.status == .posted else { return }
                conversations[index].isTyping = true
            }
            try? await Task.sleep(for: .seconds(2.2))
            guard let trade = trade(id: tradeID), trade.status == .posted, let shift = shift(id: trade.shiftID) else {
                if let teamID = teamConversationID, let index = conversations.firstIndex(where: { $0.id == teamID }) {
                    conversations[index].isTyping = false
                }
                return
            }
            let taker = eligibleCoworkers(for: shift).first?.name ?? "Sam Okafor"
            if let teamID = teamConversationID, let index = conversations.firstIndex(where: { $0.id == teamID }) {
                conversations[index].isTyping = false
                post(ChatMessage(text: "I can take \(shift.date.formatted(.dateTime.weekday(.wide)))! Claiming it now 👍", isFromMe: false, date: .now), to: teamID)
            }
            claim(tradeID, by: taker)
        }
    }

    /// Jordan picks up a coworker's open shift from the Cover Board.
    func pickUp(_ tradeID: UUID) {
        claim(tradeID, by: profile.name)
    }

    private func claim(_ tradeID: UUID, by claimer: String) {
        guard let index = trades.firstIndex(where: { $0.id == tradeID }), trades[index].status == .posted,
              let shift = shift(id: trades[index].shiftID) else { return }
        Haptics.success()
        trades[index].claimerName = claimer
        trades[index].status = .claimed
        if trades[index].mode == .swap {
            let offer = swapOffer(from: claimer, for: shift)
            shifts.append(offer)
            trades[index].swapOfferID = offer.id
        }
        let mine = claimer == profile.name
        let first = claimer.split(separator: " ").first.map(String.init) ?? claimer
        if let teamID = teamConversationID {
            let text = mine ? "You claimed \(trades[index].posterName)'s \(shift.shortLabel) · waiting on \(MockData.managerName)"
                            : "\(claimer) claimed your \(shift.shortLabel) · waiting on \(MockData.managerName)"
            post(ChatMessage(text: text, isFromMe: mine, date: .now, kind: .system), to: teamID,
                 quickReplies: mine ? ["Happy to help!", "What time should I be there?", "Thanks \(trades[index].posterName.split(separator: " ").first ?? "")!"]
                                    : ["Thank you \(first)!!", "Keys are in the drawer", "Call me if anything comes up"])
        }
        if let managerID = managerConversationID {
            let intro = mine ? "You asked to pick up \(trades[index].posterName)'s \(shift.shortLabel)"
                             : "You asked \(MockData.managerName) to approve \(first) covering \(shift.shortLabel)"
            post(ChatMessage(text: intro, isFromMe: true, date: .now, kind: .system), to: managerID)
            post(ChatMessage(text: "Trade request", isFromMe: true, date: .now, kind: .tradeRequest(tradeID: trades[index].id)), to: managerID,
                 quickReplies: ["Thanks Maya!", "Let me know if that works", "Happy to talk it through"])
        }
    }

    private func swapOffer(from claimer: String, for shift: Shift) -> Shift {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let taken = Set(myShifts.map { cal.startOfDay(for: $0.date) })
        let freeDay = (1..<7).compactMap { cal.date(byAdding: .day, value: $0, to: today) }.first { !taken.contains($0) }
            ?? cal.date(byAdding: .day, value: 2, to: today) ?? today
        return Shift(date: freeDay, start: .init(hour: 7), end: .init(hour: 13), role: "Barista", location: shift.location,
                     manager: shift.manager, coworkers: [shift.owner], owner: claimer)
    }

    func approve(_ tradeID: UUID) { decide(tradeID, approved: true) }
    func decline(_ tradeID: UUID) { decide(tradeID, approved: false) }

    private func decide(_ tradeID: UUID, approved: Bool) {
        guard let index = trades.firstIndex(where: { $0.id == tradeID }), trades[index].status == .claimed,
              let claimer = trades[index].claimerName,
              let shiftIndex = shifts.firstIndex(where: { $0.id == trades[index].shiftID }) else { return }
        if approved { Haptics.success() } else { Haptics.light() }
        let trade = trades[index]
        let shift = shifts[shiftIndex]
        let poster = trade.posterName
        let first = claimer.split(separator: " ").first.map(String.init) ?? claimer
        trades[index].status = approved ? .approved : .declined
        trades[index].decidedAt = .now
        if approved {
            shifts[shiftIndex].owner = claimer
            shifts[shiftIndex].coworkers.removeAll { $0 == claimer }
            if let offerID = trade.swapOfferID, let offerIndex = shifts.firstIndex(where: { $0.id == offerID }) {
                shifts[offerIndex].owner = poster
            }
        } else if let offerID = trade.swapOfferID {
            shifts.removeAll { $0.id == offerID }
        }

        let outcome = approved ? "approved" : "declined"
        let mineToCover = claimer == profile.name
        if let teamID = teamConversationID {
            let text = approved
                ? "\(MockData.managerName) approved · \(mineToCover ? "You're" : "\(first) is") covering \(shift.shortLabel)"
                : "\(MockData.managerName) declined the trade · \(poster == profile.name ? "you're" : "\(poster) is") still on \(shift.shortLabel)"
            post(ChatMessage(text: text, isFromMe: false, date: .now, kind: .system), to: teamID)
        }
        if let managerID = managerConversationID {
            post(ChatMessage(text: "Trade \(outcome) · \(shift.shortLabel)", isFromMe: false, date: .now, kind: .system), to: managerID,
                 quickReplies: approved ? ["Thanks Maya!", "Appreciate it 🙏", "See you next shift"] : ["Got it, thanks", "Can we talk about it?", "I'll keep the shift"])
            if let convIndex = conversations.firstIndex(where: { $0.id == managerID }) { conversations[convIndex].isTyping = true }
            let reply = approved
                ? (mineToCover ? "Approved — thanks for picking that up, Jordan. You're on \(shift.shortLabel)." : "Approved. \(first) has \(shift.date.formatted(.dateTime.weekday(.wide))) — thanks for sorting it out early, Jordan.")
                : "I need you on \(shift.date.formatted(.dateTime.weekday(.wide))) — can we talk before your next shift?"
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.6))
                self.deliver(reply, to: managerID)
            }
        }
    }
}
