import SwiftUI

enum JobType: String, CaseIterable, Identifiable {
    case fullTime = "Full-time"
    case partTime = "Part-time"
    case seasonal = "Seasonal"
    case gig = "Gig"

    var id: String { rawValue }
}

enum JobFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case hiringToday = "Hiring today"
    case partTime = "Part-time"
    case fullTime = "Full-time"
    case noExperience = "No experience"
    case weekends = "Weekends"

    var id: String { rawValue }
}

struct Job: Identifiable, Hashable {
    let id: UUID
    let title: String
    let company: String
    let logoSymbol: String
    let logoColor: Color
    let payMin: Int
    let payMax: Int
    let distanceMiles: Double
    let address: String
    let type: JobType
    let tags: [String]
    let urgentlyHiring: Bool
    let noExperience: Bool
    let postedHoursAgo: Int
    let applicants: Int
    let about: String
    let responsibilities: [String]
    let requirements: [String]
    let schedule: [String]
    let hiringManager: String

    init(title: String, company: String, logoSymbol: String, logoColor: Color, payMin: Int, payMax: Int,
         distanceMiles: Double, address: String, type: JobType, tags: [String], urgentlyHiring: Bool = false,
         noExperience: Bool = false, postedHoursAgo: Int, applicants: Int, about: String,
         responsibilities: [String], requirements: [String], schedule: [String], hiringManager: String) {
        self.id = UUID()
        self.title = title
        self.company = company
        self.logoSymbol = logoSymbol
        self.logoColor = logoColor
        self.payMin = payMin
        self.payMax = payMax
        self.distanceMiles = distanceMiles
        self.address = address
        self.type = type
        self.tags = tags
        self.urgentlyHiring = urgentlyHiring
        self.noExperience = noExperience
        self.postedHoursAgo = postedHoursAgo
        self.applicants = applicants
        self.about = about
        self.responsibilities = responsibilities
        self.requirements = requirements
        self.schedule = schedule
        self.hiringManager = hiringManager
    }

    var payLabel: String { payMin == payMax ? "$\(payMin)/hr" : "$\(payMin)–$\(payMax)/hr" }
    var distanceLabel: String { String(format: "%.1f mi", distanceMiles) }
    var postedLabel: String {
        if postedHoursAgo < 1 { return "Just now" }
        if postedHoursAgo < 24 { return "\(postedHoursAgo)h ago" }
        return "\(postedHoursAgo / 24)d ago"
    }
}

enum ApplicationStatus: String {
    case applied = "Applied"
    case viewed = "Viewed by employer"
    case interview = "Interview scheduled"
    case hired = "Hired"

    var color: Color {
        switch self {
        case .applied: return .jgPurple
        case .viewed: return .jgOrange
        case .interview: return .jgGreen
        case .hired: return .jgGreen
        }
    }
}

struct JobApplication: Identifiable {
    let id = UUID()
    let job: Job
    let date: Date
    var status: ApplicationStatus
}

enum MessageKind: Equatable {
    case text
    case system
    case interview(day: String, time: String)
    /// Shift Trade card posted to the store team thread (poster → taker, claimable).
    case shiftTrade(tradeID: UUID)
    /// Manager approval request card posted to the manager thread (1-tap approve / decline).
    case tradeRequest(tradeID: UUID)
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isFromMe: Bool
    let date: Date
    var kind: MessageKind = .text
}

struct Conversation: Identifiable {
    let id = UUID()
    let counterpartName: String
    let counterpartRole: String
    let company: String
    let logoSymbol: String
    let logoColor: Color
    var messages: [ChatMessage]
    var unreadCount: Int
    var isTyping: Bool = false
    var quickReplies: [String]
    var pendingReplies: [String]

    var lastMessage: ChatMessage? { messages.last }
}

struct Shift: Identifiable {
    let id = UUID()
    let date: Date
    let start: DateComponents
    let end: DateComponents
    let role: String
    let location: String
    let manager: String
    var coworkers: [String]
    /// Employee currently responsible for the shift. Changes only when a trade is approved.
    var owner: String = MockData.profile.name

    var startDate: Date { Calendar.current.date(bySettingHour: start.hour ?? 0, minute: start.minute ?? 0, second: 0, of: date) ?? date }
    var endDate: Date { Calendar.current.date(bySettingHour: end.hour ?? 0, minute: end.minute ?? 0, second: 0, of: date) ?? date }
    var hours: Double { endDate.timeIntervalSince(startDate) / 3600 }

    var dayLabel: String { date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) }
    var timeLabel: String { "\(startDate.formatted(.dateTime.hour().minute())) – \(endDate.formatted(.dateTime.hour().minute()))" }
    var shortLabel: String { "\(date.formatted(.dateTime.weekday(.abbreviated))) \(timeLabel)" }
}

enum TradeMode: String, CaseIterable, Identifiable {
    case giveAway = "Give away"
    case swap = "Swap"

    var id: String { rawValue }
    var subtitle: String {
        switch self {
        case .giveAway: return "A coworker takes the whole shift."
        case .swap: return "A coworker takes it and you pick up one of theirs."
        }
    }
}

enum TradeStatus: Equatable {
    case posted
    case claimed
    case approved
    case declined
    case withdrawn

    var isActive: Bool { self == .posted || self == .claimed }
}

/// One shift trade (give-away or swap) between two employees at the same location.
/// Phase 1: same-location peers only, manager approval required.
struct ShiftTrade: Identifiable, Equatable {
    let id = UUID()
    let shiftID: UUID
    let posterName: String
    let mode: TradeMode
    let note: String
    var swapPreference: String?
    var claimerName: String?
    /// For swaps: the shift the claimer gives the poster in return. Added to the poster's schedule on approval.
    var swapOfferID: UUID?
    var status: TradeStatus
    var postedAt: Date = .now
    var decidedAt: Date?

    var isClaimed: Bool { claimerName != nil }
}

struct Teammate: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let color: Color
    let isManager: Bool
}

struct UserProfile {
    var name: String
    var headline: String
    var city: String
    var availability: [String]
    var skills: [String]
    var documents: [String]
    var profileStrength: Double
    var currentEmployer: String
    var currentLocation: String
}
