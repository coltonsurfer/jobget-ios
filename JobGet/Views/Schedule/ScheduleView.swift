import SwiftUI

struct ScheduleView: View {
    @Environment(AppState.self) private var state
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: .now)

    private var weekDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    employerCard
                    weekStrip
                    dayShifts
                    upcoming
                    team
                }
                .padding(20)
            }
            .background(Color.jgSurface)
            .navigationTitle("My Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: { Image(systemName: "clock.arrow.circlepath") }
                        .accessibilityLabel("Timesheet")
                }
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
                ForEach(shifts) { ShiftCard(shift: $0, expanded: true) }
            }
        }
    }

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming shifts").font(.headline).foregroundStyle(Color.jgInk)
            ForEach(state.shifts.filter { !Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }) { shift in
                ShiftCard(shift: shift, expanded: false)
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
    let shift: Shift
    let expanded: Bool

    var body: some View {
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
                    Text("\(shift.startDate, format: .dateTime.hour().minute()) – \(shift.endDate, format: .dateTime.hour().minute())")
                        .font(.subheadline.weight(.bold)).foregroundStyle(Color.jgInk)
                    Spacer()
                    Text(String(format: "%.1f h", shift.hours)).font(.caption.weight(.semibold)).foregroundStyle(Color.jgMuted)
                }
                Text(shift.role).font(.subheadline).foregroundStyle(Color.jgInk.opacity(0.85))
                Label(shift.location, systemImage: "mappin").font(.caption).foregroundStyle(Color.jgMuted)
                if expanded {
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
    }
}
