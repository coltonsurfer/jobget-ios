import SwiftUI

/// Bottom sheet: give away or swap one of my shifts with a same-location coworker.
struct TradeShiftSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let shift: Shift

    @State private var mode: TradeMode = .giveAway
    @State private var swapPreference = "Any day"
    @State private var note = ""
    @State private var posted = false

    private let swapOptions = ["Any day", "Weekend", "Weekday morning", "Weekday evening"]
    private var eligible: [Teammate] { state.eligibleCoworkers(for: shift) }
    private var managerFirstName: String { (state.manager?.name ?? MockData.managerName).split(separator: " ").first.map(String.init) ?? "your manager" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    shiftSummary
                    modePicker
                    if mode == .swap { swapPicker }
                    noteField
                    eligibleRow
                    disclaimer
                }
                .padding(20)
            }
            .background(Color.jgSurface)
            .navigationTitle("Trade shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.accessibilityIdentifier("trade-cancel")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    state.postTrade(shift, mode: mode, note: note, swapPreference: swapPreference)
                    withAnimation(.snappy) { posted = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
                } label: {
                    Label(posted ? "Posted to \(eligible.count) coworkers" : "Post to team", systemImage: posted ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                }
                .buttonStyle(PrimaryButtonStyle(color: posted ? .jgGreen : .jgPurple))
                .disabled(posted || eligible.isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white)
                .accessibilityIdentifier("post-trade-button")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var shiftSummary: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(shift.date, format: .dateTime.weekday(.abbreviated)).font(.caption2.weight(.bold)).foregroundStyle(Color.jgPurple)
                Text(shift.date, format: .dateTime.day()).font(.title3.weight(.bold)).foregroundStyle(Color.jgInk)
            }
            .frame(width: 44)
            .padding(.vertical, 8)
            .background(Color.jgLilac, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(shift.timeLabel).font(.subheadline.weight(.bold)).foregroundStyle(Color.jgInk)
                Text(shift.role).font(.subheadline).foregroundStyle(Color.jgInk.opacity(0.85))
                Label(shift.location, systemImage: "mappin").font(.caption).foregroundStyle(Color.jgMuted)
            }
            Spacer()
            Text(String(format: "%.1f h", shift.hours)).font(.caption.weight(.semibold)).foregroundStyle(Color.jgMuted)
        }
        .jgCard()
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How do you want to trade?").font(.headline).foregroundStyle(Color.jgInk)
            Picker("Trade mode", selection: $mode) {
                ForEach(TradeMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("trade-mode-picker")
            Text(mode.subtitle).font(.caption).foregroundStyle(Color.jgMuted)
        }
    }

    private var swapPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What would you take in return?").font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(swapOptions, id: \.self) { option in
                        let selected = option == swapPreference
                        Button { swapPreference = option } label: {
                            Text(option)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selected ? .white : Color.jgPurple)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selected ? Color.jgPurple : Color.jgLilac, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("swap-option-\(option)")
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Note to the team").font(.headline).foregroundStyle(Color.jgInk)
                Spacer()
                Text("Optional").font(.caption).foregroundStyle(Color.jgMuted)
            }
            TextField("e.g. Family thing came up — thanks y'all", text: $note, axis: .vertical)
                .lineLimit(2...4)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.jgLine))
                .accessibilityIdentifier("trade-note")
        }
    }

    private var eligibleRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Who can take it").font(.headline).foregroundStyle(Color.jgInk)
                Spacer()
                Text("\(eligible.count) at \(state.profile.currentLocation)").font(.caption).foregroundStyle(Color.jgMuted)
            }
            if eligible.isEmpty {
                Text("No coworkers at this location are free for this shift yet. Message \(managerFirstName) instead.")
                    .font(.caption).foregroundStyle(Color.jgMuted)
            } else {
                HStack(spacing: 12) {
                    ForEach(eligible) { mate in
                        VStack(spacing: 6) {
                            Avatar(name: mate.name, color: mate.color, size: 44)
                            Text(mate.name.split(separator: " ").first.map(String.init) ?? mate.name)
                                .font(.caption2.weight(.semibold)).foregroundStyle(Color.jgInk)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.jgLine))
            }
        }
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(Color.jgOrange)
            Text("You're still on this shift until \(managerFirstName) approves a replacement. Only coworkers at \(state.profile.currentLocation) are notified.")
                .font(.caption).foregroundStyle(Color.jgInk.opacity(0.8))
        }
        .padding(12)
        .background(Color.jgOrangeSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
