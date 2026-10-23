import SwiftUI

/// One open coworker shift on the Cover Board with 1-tap Pick up.
struct CoverBoardCard: View {
    @Environment(AppState.self) private var state
    let trade: ShiftTrade

    var body: some View {
        if let shift = state.shift(id: trade.shiftID) {
            let conflict = state.conflict(for: shift)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Avatar(name: trade.posterName, color: state.teammates.first { $0.name == trade.posterName }?.color ?? .jgPurple, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(shift.dayLabel) · \(shift.timeLabel)").font(.subheadline.weight(.bold)).foregroundStyle(Color.jgInk)
                        Text("\(shift.role) · \(trade.posterName)").font(.caption).foregroundStyle(Color.jgMuted)
                    }
                    Spacer()
                    Pill(text: trade.mode == .swap ? "Swap" : "Give away", icon: trade.mode == .swap ? "arrow.left.arrow.right" : "gift.fill",
                         foreground: trade.mode == .swap ? .jgOrange : .jgPurple, background: trade.mode == .swap ? .jgOrangeSoft : .jgLilac)
                }
                if !trade.note.isEmpty {
                    Text("“\(trade.note)”").font(.caption).foregroundStyle(Color.jgInk.opacity(0.8)).italic()
                }
                HStack {
                    Label(String(format: "%.1f h · +$%.0f est.", shift.hours, shift.hours * 18), systemImage: "dollarsign.circle")
                        .font(.caption.weight(.semibold)).foregroundStyle(Color.jgGreen)
                    Spacer()
                    Text(trade.postedAt, format: .relative(presentation: .named)).font(.caption2).foregroundStyle(Color.jgMuted)
                }
                if let conflict {
                    Label("You're already on \(conflict.shortLabel)", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(Color.jgOrange)
                } else {
                    Button { withAnimation(.snappy) { state.pickUp(trade.id) } } label: {
                        Label("Pick up", systemImage: "hand.raised.fill").font(.subheadline.weight(.bold))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("pickup-button")
                }
            }
            .jgCard()
            .accessibilityIdentifier("cover-board-card")
        }
    }
}

/// Full Cover Board: every open shift at my location plus my pending pick-ups.
struct CoverBoardView: View {
    @Environment(AppState.self) private var state

    private var myClaims: [ShiftTrade] {
        state.trades.filter { $0.claimerName == state.profile.name && $0.status != .posted }
            .sorted { ($0.decidedAt ?? $0.postedAt) > ($1.decidedAt ?? $1.postedAt) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "rectangle.stack.badge.person.crop.fill").font(.title2).foregroundStyle(Color.jgPurple)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Open shifts at \(state.profile.currentLocation)").font(.headline).foregroundStyle(Color.jgInk)
                        Text("Posted by your coworkers. Pick one up and \(MockData.managerName.split(separator: " ").first ?? "") approves with one tap.")
                            .font(.caption).foregroundStyle(Color.jgMuted)
                    }
                }
                .jgCard()

                if state.openBoardTrades.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle").font(.title2).foregroundStyle(Color.jgGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Board is clear").font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                            Text("No open shifts right now. We'll ping you when a coworker posts one.").font(.caption).foregroundStyle(Color.jgMuted)
                        }
                        Spacer()
                    }
                    .jgCard()
                } else {
                    ForEach(state.openBoardTrades) { CoverBoardCard(trade: $0) }
                }

                if !myClaims.isEmpty {
                    Text("Your pick-ups").font(.headline).foregroundStyle(Color.jgInk)
                    ForEach(myClaims) { trade in
                        if let shift = state.shift(id: trade.shiftID) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(shift.dayLabel) · \(shift.timeLabel)").font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                                    Text("from \(trade.posterName)").font(.caption).foregroundStyle(Color.jgMuted)
                                }
                                Spacer()
                                TradeStatusPill(trade: trade, isMine: false)
                            }
                            .jgCard()
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.jgSurface)
        .navigationTitle("Cover Board")
        .navigationBarTitleDisplayMode(.inline)
    }
}
