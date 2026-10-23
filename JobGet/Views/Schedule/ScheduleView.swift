import SwiftUI

struct ScheduleView: View {
    @Environment(AppState.self) private var state
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: .now)
    @State private var tradingShift: Shift?

    private var weekDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if state.managerMode {
                        managerBanner
                        approvalQueue
                    }
                    employerCard
                    weekStrip
                    dayShifts
                    coverBoard
                    upcoming
                    team
                }
                .padding(20)
            }
            .background(Color.jgSurface)
            .navigationTitle(state.managerMode ? "Store Schedule" : "My Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        withAnimation(.snappy) { state.managerMode.toggle() }
                    } label: {
                        Image(systemName: state.managerMode ? "person.badge.key.fill" : "person.badge.key")
                    }
                    .accessibilityLabel(state.managerMode ? "Exit manager view" : "Manager view")
                    .accessibilityIdentifier("manager-toggle")
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "cover-board" { CoverBoardView() }
            }
            .sheet(item: $tradingShift) { shift in
                TradeShiftSheet(shift: shift)
            }
        }
    }

    private var managerBanner: some View {
        HStack(spacing: 12) {
            Avatar(name: MockData.managerName, color: state.manager?.color ?? .jgPurple, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Viewing as \(MockData.managerName)").font(.subheadline.weight(.bold)).foregroundStyle(.white)
                Text("Store Manager · demo preview of the approval queue").font(.caption).foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
            Pill(text: "Manager", icon: "star.fill", foreground: .jgPurple, background: .white)
        }
        .padding(14)
        .background(Color.jgPurple.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("manager-banner")
    }

    private var approvalQueue: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Needs approval").font(.headline).foregroundStyle(Color.jgInk)
                if !state.pendingApprovals.isEmpty {
                    Text("\(state.pendingApprovals.count)")
                        .font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(minWidth: 20, minHeight: 20).background(Color.jgOrange, in: Capsule())
                }
                Spacer()
                Text("1-tap approve or decline").font(.caption).foregroundStyle(Color.jgMuted)
            }
            if state.pendingApprovals.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(Color.jgGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Queue is clear").font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                        Text("Claimed trades will show up here for a one-tap decision.").font(.caption).foregroundStyle(Color.jgMuted)
                    }
                    Spacer()
                }
                .jgCard()
            } else {
                ForEach(state.pendingApprovals) { TradeRequestCard(tradeID: $0.id) }
            }
        }
        .accessibilityIdentifier("approval-queue")
    }

    private var coverBoard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Cover Board", systemImage: "rectangle.stack.badge.person.crop.fill").font(.headline).foregroundStyle(Color.jgInk)
                if !state.openBoardTrades.isEmpty {
                    Text("\(state.openBoardTrades.count) open")
                        .font(.caption2.weight(.bold)).foregroundStyle(Color.jgPurple)
                        .padding(.horizontal, 8).padding(.vertical, 3).background(Color.jgLilac, in: Capsule())
                }
                Spacer()
                NavigationLink(value: "cover-board") {
                    Text("See all").font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgPurple)
                }
                .accessibilityIdentifier("cover-board-see-all")
            }
            if state.openBoardTrades.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle").font(.title2).foregroundStyle(Color.jgGreen)
                    Text("No open shifts from coworkers right now.").font(.caption).foregroundStyle(Color.jgMuted)
                    Spacer()
                }
                .jgCard()
            } else {
                ForEach(state.openBoardTrades.prefix(2)) { CoverBoardCard(trade: $0) }
            }
        }
    }

    private var employerCard: some View {
        HStack(spacing: 14) {
            LogoBadge(symbol: "cup.and.saucer.fill", color: Color(hex: 0x8B5A2B), size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(state.profile.currentEmployer).font(.headline).foregroundStyle(Color.jgInk)
                Text("\(state.profile.currentLocation) · Barista").font(.subheadline).foregroundStyle(Color.jgMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f h", state.hoursThisWeek)).font(.title3.weight(.bold)).foregroundStyle(Color.jgPurple)
                Text("this week").font(.caption).foregroundStyle(Color.jgMuted)
            }
        }
        .jgCard()
    }

    private var weekStrip: some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { day in
                let selected = Calendar.current.isDate(day, inSameDayAs: selectedDay)
                let hasShift = !state.shifts(on: day).isEmpty
                Button {
                    withAnimation(.snappy) { selectedDay = day }
                } label: {
                    VStack(spacing: 6) {
                        Text(day, format: .dateTime.weekday(.abbreviated))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(selected ? .white.opacity(0.85) : Color.jgMuted)
                        Text(day, format: .dateTime.day())
                            .font(.headline)
                            .foregroundStyle(selected ? .white : Color.jgInk)
                        Circle()
                            .fill(hasShift ? (selected ? Color.white : Color.jgPurple) : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selected ? Color.jgPurple : Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? Color.clear : Color.jgLine))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("day-\(Calendar.current.component(.day, from: day))")
            }
        }
    }

    private var dayShifts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedDay, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(.headline)
                .foregroundStyle(Color.jgInk)
            let shifts = state.shifts(on: selectedDay)
            if shifts.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill").font(.title2).foregroundStyle(Color.jgMuted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No shift scheduled").font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                        Text("Enjoy your day off, or pick up an open shift.").font(.caption).foregroundStyle(Color.jgMuted)
                    }
                    Spacer()
                }
                .jgCard()
            } else {
                ForEach(shifts) { shift in ShiftCard(shift: shift, expanded: true) { tradingShift = shift } }
            }
        }
    }

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming shifts").font(.headline).foregroundStyle(Color.jgInk)
            ForEach(state.scheduleShifts.filter { !Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }) { shift in
                ShiftCard(shift: shift, expanded: false) { tradingShift = shift }
            }
        }
    }

    private var team: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your team").font(.headline).foregroundStyle(Color.jgInk)
                Spacer()
                Text("\(state.teammates.count) at \(state.profile.currentLocation)").font(.caption).foregroundStyle(Color.jgMuted)
            }
            VStack(spacing: 0) {
                ForEach(Array(state.teammates.enumerated()), id: \.element.id) { index, mate in
                    HStack(spacing: 12) {
                        Avatar(name: mate.name, color: mate.color, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mate.name).font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                            Text(mate.role).font(.caption).foregroundStyle(Color.jgMuted)
                        }
                        Spacer()
                        if mate.isManager {
                            Pill(text: "Manager", icon: "star.fill")
                        }
                        Image(systemName: "bubble.left").foregroundStyle(Color.jgPurple)
                    }
                    .padding(.vertical, 10)
                    if index < state.teammates.count - 1 { Divider() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.jgLine))
        }
    }
}

struct ShiftCard: View {
    @Environment(AppState.self) private var state
    let shift: Shift
    let expanded: Bool
    var onTrade: () -> Void = {}

    private var trade: ShiftTrade? { state.latestTrade(for: shift) }
    private var isMine: Bool { shift.owner == state.profile.name || trade?.posterName == state.profile.name }
    private var covered: Bool { trade?.status == .approved && trade?.posterName == state.profile.name }
    private var pending: Bool { trade?.status == .claimed && trade?.claimerName == state.profile.name }
    private var tradable: Bool { state.canTrade(shift) }

    var body: some View {
        Button(action: onTrade) {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 2) {
                    Text(shift.date, format: .dateTime.weekday(.abbreviated)).font(.caption2.weight(.bold)).foregroundStyle(Color.jgPurple)
                    Text(shift.date, format: .dateTime.day()).font(.title3.weight(.bold)).foregroundStyle(Color.jgInk)
                }
                .frame(width: 44)
                .padding(.vertical, 8)
                .background(Color.jgLilac, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(shift.timeLabel)
                            .font(.subheadline.weight(.bold)).foregroundStyle(Color.jgInk)
                            .strikethrough(covered, color: .jgMuted)
                        Spacer()
                        Text(String(format: "%.1f h", shift.hours)).font(.caption.weight(.semibold)).foregroundStyle(Color.jgMuted)
                    }
                    Text(shift.role).font(.subheadline).foregroundStyle(Color.jgInk.opacity(0.85))
                    Label(shift.location, systemImage: "mappin").font(.caption).foregroundStyle(Color.jgMuted)
                    if let trade, trade.status != .withdrawn {
                        HStack(spacing: 8) {
                            TradeStatusPill(trade: trade, isMine: isMine)
                            if covered, let claimer = trade.claimerName {
                                Text("by \(claimer)").font(.caption).foregroundStyle(Color.jgMuted)
                            } else if pending {
                                Text("from \(trade.posterName)").font(.caption).foregroundStyle(Color.jgMuted)
                            }
                        }
                    } else if tradable {
                        Label("Tap to trade", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.semibold)).foregroundStyle(Color.jgPurple)
                    }
                    if expanded, !shift.coworkers.isEmpty {
                        HStack(spacing: -8) {
                            ForEach(shift.coworkers, id: \.self) { Avatar(name: $0, color: .jgMuted, size: 26).overlay(Circle().stroke(.white, lineWidth: 2)) }
                            Text("with \(shift.coworkers.joined(separator: ", "))")
                                .font(.caption).foregroundStyle(Color.jgMuted).padding(.leading, 14)
                        }
                        .padding(.top, 2)
                    }
                }
            }
            .jgCard()
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: pending ? [6, 4] : [])).foregroundStyle(pending ? Color.jgOrange : Color.clear))
            .opacity(covered ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!tradable)
        .accessibilityIdentifier("shift-card")
    }
}
