import SwiftUI

struct JobDetailView: View {
    @Environment(AppState.self) private var state
    let job: Job
    @State private var showApplied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                stats
                section("About the role") {
                    Text(job.about).font(.body).foregroundStyle(Color.jgInk.opacity(0.85))
                }
                section("Schedule") {
                    FlowChips(items: job.schedule, foreground: .jgPurple, background: .jgLilac)
                }
                section("What you'll do") { bullets(job.responsibilities, symbol: "checkmark.circle.fill", color: .jgPurple) }
                section("Requirements") { bullets(job.requirements, symbol: "info.circle.fill", color: .jgOrange) }
                hiringManager
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .background(Color.jgSurface)
        .navigationTitle(job.company)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { state.toggleSaved(job) } label: {
                    Image(systemName: state.isSaved(job) ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(state.isSaved(job) ? "Unsave job" : "Save job")
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sheet(isPresented: $showApplied) {
            AppliedSheet(job: job)
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                LogoBadge(symbol: job.logoSymbol, color: job.logoColor, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title).font(.title2.weight(.bold)).foregroundStyle(Color.jgInk)
                    Text(job.company).font(.subheadline.weight(.medium)).foregroundStyle(Color.jgMuted)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse").font(.caption)
                        Text("\(job.address) · \(job.distanceLabel)")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.jgMuted)
                }
            }
            HStack(spacing: 8) {
                if job.urgentlyHiring {
                    Pill(text: "Hiring today", icon: "bolt.fill", foreground: .jgOrange, background: .jgOrangeSoft)
                }
                Pill(text: job.type.rawValue)
                ForEach(job.tags, id: \.self) { Pill(text: $0, foreground: .jgMuted, background: .jgSurface) }
            }
        }
        .jgCard()
    }

    private var stats: some View {
        HStack(spacing: 0) {
            stat(value: job.payLabel, label: "Pay", color: .jgGreen)
            Divider().frame(height: 36)
            stat(value: "\(job.applicants)", label: "Applicants", color: .jgInk)
            Divider().frame(height: 36)
            stat(value: job.postedLabel, label: "Posted", color: .jgInk)
        }
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.jgLine))
    }

    private func stat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.headline).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption).foregroundStyle(Color.jgMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(Color.jgInk)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jgCard()
    }

    private func bullets(_ items: [String], symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: symbol).foregroundStyle(color).padding(.top, 2)
                    Text(item).foregroundStyle(Color.jgInk.opacity(0.85))
                }
                .font(.subheadline)
            }
        }
    }

    private var hiringManager: some View {
        HStack(spacing: 12) {
            Avatar(name: job.hiringManager, color: job.logoColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(job.hiringManager).font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                Text("Hiring Manager · Usually replies in under 1 hour").font(.caption).foregroundStyle(Color.jgMuted)
            }
            Spacer()
            Image(systemName: "bubble.left.fill").foregroundStyle(Color.jgPurple)
        }
        .jgCard()
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if let conversation = state.conversation(forCompany: job.company), state.hasApplied(to: job) {
                Button {
                    state.openConversation(conversation.id)
                } label: {
                    Label("Message \(job.hiringManager.split(separator: " ").first ?? "")", systemImage: "bubble.left.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                Label("Applied", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.jgGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.jgGreenSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Button {
                    state.apply(to: job)
                    showApplied = true
                } label: {
                    Label("1-Tap Apply", systemImage: "hand.tap.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("apply-button")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

struct AppliedSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let job: Job
    @State private var animate = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.jgGreenSoft).frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.jgGreen)
                    .scaleEffect(animate ? 1 : 0.4)
                    .opacity(animate ? 1 : 0)
            }
            .padding(.top, 24)

            VStack(spacing: 6) {
                Text("Application sent!").font(.title2.weight(.bold)).foregroundStyle(Color.jgInk)
                Text("\(job.hiringManager) at \(job.company) has your profile. Most employers reply within a few hours.")
                    .font(.subheadline)
                    .foregroundStyle(Color.jgMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 12) {
                LogoBadge(symbol: job.logoSymbol, color: job.logoColor, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(job.title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                    Text(job.payLabel).font(.caption.weight(.semibold)).foregroundStyle(Color.jgGreen)
                }
                Spacer()
                Pill(text: "Applied", icon: "checkmark", foreground: .jgGreen, background: .jgGreenSoft)
            }
            .padding(12)
            .background(Color.jgSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 24)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Button {
                    dismiss()
                    if let conversation = state.conversation(forCompany: job.company) {
                        state.openConversation(conversation.id)
                    }
                } label: {
                    Label("Message \(job.hiringManager.split(separator: " ").first ?? "")", systemImage: "bubble.left.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("message-manager-button")

                Button("Keep browsing") { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.jgMuted)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.1)) { animate = true }
        }
    }
}

struct FlowChips: View {
    let items: [String]
    var foreground: Color = .jgPurple
    var background: Color = .jgLilac

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { Pill(text: $0, foreground: foreground, background: background) }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
