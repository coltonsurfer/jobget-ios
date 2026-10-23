import SwiftUI

/// Status of a shift from my point of view, rendered as a pill on shift cards.
struct TradeStatusPill: View {
    let trade: ShiftTrade
    let isMine: Bool

    var body: some View {
        switch trade.status {
        case .posted:
            Pill(text: "Posted", icon: "arrow.triangle.2.circlepath", foreground: .jgOrange, background: .jgOrangeSoft)
        case .claimed:
            Pill(text: "Claimed · pending approval", icon: "clock.fill", foreground: .jgOrange, background: .jgOrangeSoft)
        case .approved:
            if isMine {
                Pill(text: "Covered", icon: "checkmark.circle.fill", foreground: .jgMuted, background: Color.jgLine.opacity(0.7))
            } else {
                Pill(text: "Approved", icon: "checkmark.seal.fill", foreground: .jgGreen, background: .jgGreenSoft)
            }
        case .declined:
            Pill(text: "Declined", icon: "xmark.circle.fill", foreground: .jgRed, background: .jgRedSoft)
        case .withdrawn:
            Pill(text: "Withdrawn", icon: "arrow.uturn.backward", foreground: .jgMuted, background: Color.jgLine.opacity(0.7))
        }
    }
}

private func firstName(_ name: String) -> String { name.split(separator: " ").first.map(String.init) ?? name }

/// Live Shift Trade card in the store team thread. Re-renders as the trade moves through its states.
struct ShiftTradeCard: View {
    @Environment(AppState.self) private var state
    let tradeID: UUID

    var body: some View {
        if let trade = state.trade(id: tradeID), let shift = state.shift(id: trade.shiftID) {
            let mine = trade.posterName == state.profile.name
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(trade.mode == .swap ? "Shift swap" : "Shift trade", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.bold)).foregroundStyle(Color.jgPurple)
                    Spacer()
                    TradeStatusPill(trade: trade, isMine: mine)
                }
                HStack(spacing: 12) {
                    Avatar(name: trade.posterName, color: .jgPurple, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(shift.dayLabel) · \(shift.timeLabel)").font(.headline).foregroundStyle(Color.jgInk)
                        Text("\(shift.role) · posted by \(mine ? "you" : firstName(trade.posterName))").font(.caption).foregroundStyle(Color.jgMuted)
                    }
                }
                if !trade.note.isEmpty {
                    Text("“\(trade.note)”").font(.subheadline).foregroundStyle(Color.jgInk.opacity(0.85)).italic()
                }
                if let pref = trade.swapPreference {
                    Label("Wants in return: \(pref)", systemImage: "arrow.left.arrow.right").font(.caption).foregroundStyle(Color.jgMuted)
                }
                footer(trade: trade, mine: mine)
            }
            .padding(14)
            .frame(maxWidth: 300, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.jgPurple.opacity(0.35)))
            .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
            .accessibilityIdentifier("shift-trade-card")
        }
    }

    @ViewBuilder
    private func footer(trade: ShiftTrade, mine: Bool) -> some View {
        switch trade.status {
        case .posted:
            if mine {
                HStack {
                    Text("Awaiting a taker").font(.caption.weight(.semibold)).foregroundStyle(Color.jgMuted)
                    Spacer()
                    Button("Withdraw") { state.withdrawTrade(trade.id) }
                        .font(.caption.weight(.bold)).foregroundStyle(Color.jgRed)
                        .accessibilityIdentifier("withdraw-trade-button")
                }
            } else {
                Button { state.pickUp(trade.id) } label: {
                    Label("Pick up this shift", systemImage: "hand.raised.fill").font(.subheadline.weight(.bold))
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("pickup-button")
            }
        case .claimed:
            if let claimer = trade.claimerName {
                Label("\(claimer == state.profile.name ? "You" : firstName(claimer)) claimed · waiting on \(firstName(MockData.managerName))", systemImage: "clock.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Color.jgOrange)
            }
        case .approved:
            if let claimer = trade.claimerName {
                Label("\(claimer == state.profile.name ? "You're" : "\(firstName(claimer)) is") covering · approved by \(firstName(MockData.managerName))", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Color.jgGreen)
            }
        case .declined:
            Label("Declined by \(firstName(MockData.managerName)) · \(mine ? "you're" : "\(firstName(trade.posterName)) is") still on the shift", systemImage: "xmark.circle.fill")
                .font(.caption.weight(.semibold)).foregroundStyle(Color.jgRed)
        case .withdrawn:
            Label("Withdrawn by \(mine ? "you" : firstName(trade.posterName))", systemImage: "arrow.uturn.backward")
                .font(.caption.weight(.semibold)).foregroundStyle(Color.jgMuted)
        }
    }
}

/// Manager approval card: who → who, shift, risk flags, 1-tap Approve / Decline (actionable in manager view).
struct TradeRequestCard: View {
    @Environment(AppState.self) private var state
    let tradeID: UUID
    var inChat = false

    var body: some View {
        if let trade = state.trade(id: tradeID), let shift = state.shift(id: trade.shiftID), let claimer = trade.claimerName {
            let projected = state.projectedHours(for: claimer, adding: shift)
            let overCap = projected > 40
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Trade request", systemImage: "person.badge.clock.fill")
                        .font(.subheadline.weight(.bold)).foregroundStyle(overCap && trade.status == .claimed ? Color.jgOrange : Color.jgPurple)
                    Spacer()
                    TradeStatusPill(trade: trade, isMine: false)
                }
                HStack(spacing: 10) {
                    Avatar(name: trade.posterName, color: .jgMuted, size: 36)
                    Image(systemName: "arrow.right").font(.caption.weight(.bold)).foregroundStyle(Color.jgMuted)
                    Avatar(name: claimer, color: .jgPurple, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(firstName(trade.posterName)) → \(firstName(claimer))").font(.headline).foregroundStyle(Color.jgInk)
                        Text("\(shift.dayLabel) · \(shift.timeLabel)").font(.caption).foregroundStyle(Color.jgMuted)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    flag("Role match · \(shift.role)", ok: true)
                    flag(String(format: "%@: %.0f → %.0f hrs this week", firstName(claimer), projected - shift.hours, projected), ok: !overCap)
                    flag("Same location · \(state.profile.currentLocation)", ok: true)
                    if trade.mode == .swap, let offer = trade.swapOffer {
                        flag("Swap · \(firstName(claimer)) gives \(offer.shortLabel)", ok: true)
                    }
                }
                .font(.caption)
                if trade.status == .claimed {
                    if state.managerMode {
                        HStack(spacing: 10) {
                            Button { state.decline(trade.id) } label: {
                                Label("Decline", systemImage: "xmark").font(.subheadline.weight(.bold))
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .accessibilityIdentifier("decline-button")
                            Button { state.approve(trade.id) } label: {
                                Label("Approve", systemImage: "checkmark").font(.subheadline.weight(.bold))
                            }
                            .buttonStyle(PrimaryButtonStyle(color: .jgGreen))
                            .accessibilityIdentifier("approve-button")
                        }
                    } else {
                        Label("Waiting on \(firstName(MockData.managerName)) · 1-tap approval", systemImage: "hourglass")
                            .font(.caption.weight(.semibold)).foregroundStyle(Color.jgOrange)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: inChat ? 300 : .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.jgPurple.opacity(0.35)))
            .frame(maxWidth: .infinity, alignment: inChat ? .trailing : .leading)
            .accessibilityIdentifier("trade-request-card")
        }
    }

    private func flag(_ text: String, ok: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(ok ? Color.jgGreen : Color.jgOrange)
            Text(text).foregroundStyle(Color.jgInk.opacity(0.85))
        }
    }
}
