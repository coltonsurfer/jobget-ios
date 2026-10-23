import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    strength
                    applications
                    section("Availability", icon: "clock.fill") {
                        FlowChips(items: state.profile.availability)
                    }
                    section("Skills & certifications", icon: "checkmark.seal.fill") {
                        FlowChips(items: state.profile.skills, foreground: .jgInk, background: .jgSurface)
                    }
                    section("Documents", icon: "doc.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(state.profile.documents, id: \.self) { doc in
                                HStack {
                                    Image(systemName: "doc.text.fill").foregroundStyle(Color.jgPurple)
                                    Text(doc).font(.subheadline).foregroundStyle(Color.jgInk)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.jgMuted)
                                }
                            }
                        }
                    }
                    settings
                }
                .padding(20)
            }
            .background(Color.jgSurface)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Avatar(name: state.profile.name, size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(state.profile.name).font(.title2.weight(.bold)).foregroundStyle(Color.jgInk)
                Text(state.profile.headline).font(.subheadline).foregroundStyle(Color.jgMuted)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                    Text(state.profile.city)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.jgPurple)
            }
            Spacer()
        }
        .jgCard()
    }

    private var strength: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Profile strength").font(.headline).foregroundStyle(Color.jgInk)
                Spacer()
                Text("\(Int(state.profile.profileStrength * 100))%").font(.headline).foregroundStyle(Color.jgGreen)
            }
            ProgressView(value: state.profile.profileStrength)
                .tint(Color.jgGreen)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            Text("Add a short intro video to reach 100% and get 2× more replies.")
                .font(.caption).foregroundStyle(Color.jgMuted)
        }
        .jgCard()
    }

    private var applications: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your applications").font(.headline).foregroundStyle(Color.jgInk)
                Spacer()
                Text("\(state.applications.count) active").font(.caption).foregroundStyle(Color.jgMuted)
            }
            VStack(spacing: 0) {
                ForEach(Array(state.applications.enumerated()), id: \.element.id) { index, application in
                    HStack(spacing: 12) {
                        LogoBadge(symbol: application.job.logoSymbol, color: application.job.logoColor, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(application.job.title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                            Text(application.job.company).font(.caption).foregroundStyle(Color.jgMuted)
                        }
                        Spacer()
                        Pill(text: application.status.rawValue, foreground: application.status.color, background: application.status.color.opacity(0.12))
                    }
                    .padding(.vertical, 10)
                    if index < state.applications.count - 1 { Divider() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.jgLine))
        }
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(Color.jgInk)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jgCard()
    }

    private var settings: some View {
        VStack(spacing: 0) {
            ForEach(Array(["Notifications", "Job alerts", "Payment & tax info", "Help center"].enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(item).font(.subheadline).foregroundStyle(Color.jgInk)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.jgMuted)
                }
                .padding(.vertical, 14)
                if index < 3 { Divider() }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.jgLine))
    }
}
