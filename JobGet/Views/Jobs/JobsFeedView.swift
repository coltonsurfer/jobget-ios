import SwiftUI

struct JobsFeedView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    searchField($state.searchText)
                    filterChips($state.filter)
                    if state.searchText.isEmpty && state.filter == .all {
                        hiringToday
                    }
                    jobList
                }
                .padding(.bottom, 24)
            }
            .background(Color.jgSurface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    JobGetWordmark()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: {
                        Image(systemName: "bell.badge.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.jgOrange, Color.jgInk)
                    }
                    .accessibilityLabel("Notifications")
                }
            }
            .navigationDestination(for: Job.self) { job in
                JobDetailView(job: job)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hi \(state.profile.name.split(separator: " ").first.map(String.init) ?? ""), find your next shift")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.jgInk)
            HStack(spacing: 4) {
                Image(systemName: "location.fill").font(.caption)
                Text("\(state.profile.city) · within 10 mi")
                Image(systemName: "chevron.down").font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.jgPurple)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func searchField(_ text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.jgMuted)
            TextField("Search jobs, companies", text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.wrappedValue.isEmpty {
                Button { text.wrappedValue = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.jgMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.jgLine))
        .padding(.horizontal, 20)
    }

    private func filterChips(_ filter: Binding<JobFilter>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(JobFilter.allCases) { item in
                    let selected = filter.wrappedValue == item
                    Button {
                        withAnimation(.snappy) { filter.wrappedValue = item }
                    } label: {
                        HStack(spacing: 4) {
                            if item == .hiringToday { Image(systemName: "bolt.fill").font(.caption2) }
                            Text(item.rawValue)
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .foregroundStyle(selected ? .white : Color.jgInk)
                        .background(selected ? Color.jgPurple : Color.white, in: Capsule())
                        .overlay(Capsule().stroke(selected ? Color.clear : Color.jgLine))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("filter-\(item.rawValue)")
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var hiringToday: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Hiring today", systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundStyle(Color.jgInk)
                Spacer()
                Text("\(state.hiringTodayJobs.count) near you")
                    .font(.subheadline)
                    .foregroundStyle(Color.jgMuted)
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(state.hiringTodayJobs) { job in
                        NavigationLink(value: job) {
                            HiringTodayCard(job: job)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var jobList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(state.filter == .all && state.searchText.isEmpty ? "Recommended for you" : "\(state.filteredJobs.count) jobs")
                    .font(.headline)
                    .foregroundStyle(Color.jgInk)
                Spacer()
                Text("Sorted by match")
                    .font(.subheadline)
                    .foregroundStyle(Color.jgMuted)
            }
            .padding(.horizontal, 20)

            if state.filteredJobs.isEmpty {
                ContentUnavailableView.search(text: state.searchText)
                    .padding(.top, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(state.filteredJobs) { job in
                        NavigationLink(value: job) {
                            JobCard(job: job)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct JobGetWordmark: View {
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.jgPurple)
                .frame(width: 26, height: 26)
                .overlay(Image(systemName: "briefcase.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(.white))
            Text("JobGet")
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.jgInk)
        }
    }
}

struct HiringTodayCard: View {
    @Environment(AppState.self) private var state
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                LogoBadge(symbol: job.logoSymbol, color: job.logoColor, size: 40)
                Spacer()
                Pill(text: "Hiring today", icon: "bolt.fill", foreground: .jgOrange, background: .jgOrangeSoft)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(job.title).font(.headline).foregroundStyle(Color.jgInk)
                Text(job.company).font(.subheadline).foregroundStyle(Color.jgMuted).lineLimit(1)
            }
            HStack {
                Text(job.payLabel).font(.subheadline.weight(.bold)).foregroundStyle(Color.jgGreen)
                Spacer()
                Text(job.distanceLabel).font(.caption).foregroundStyle(Color.jgMuted)
            }
        }
        .padding(14)
        .frame(width: 210, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.jgLine))
    }
}

struct JobCard: View {
    @Environment(AppState.self) private var state
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                LogoBadge(symbol: job.logoSymbol, color: job.logoColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(job.title).font(.headline).foregroundStyle(Color.jgInk)
                    Text(job.company).font(.subheadline).foregroundStyle(Color.jgMuted)
                    HStack(spacing: 6) {
                        Text(job.distanceLabel)
                        Text("·")
                        Text(job.type.rawValue)
                        Text("·")
                        Text(job.postedLabel)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.jgMuted)
                }
                Spacer()
                Button { state.toggleSaved(job) } label: {
                    Image(systemName: state.isSaved(job) ? "bookmark.fill" : "bookmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(state.isSaved(job) ? Color.jgPurple : Color.jgMuted)
                        .frame(width: 36, height: 36)
                        .background(Color.jgSurface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(state.isSaved(job) ? "Unsave job" : "Save job")
            }

            HStack(spacing: 8) {
                Text(job.payLabel).font(.title3.weight(.bold)).foregroundStyle(Color.jgGreen)
                if job.urgentlyHiring {
                    Pill(text: "Hiring today", icon: "bolt.fill", foreground: .jgOrange, background: .jgOrangeSoft)
                }
                ForEach(job.tags.prefix(job.urgentlyHiring ? 1 : 2), id: \.self) { tag in
                    Pill(text: tag, foreground: .jgMuted, background: .jgSurface)
                }
                Spacer()
            }

            if state.hasApplied(to: job) {
                Label("Applied", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.jgGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.jgGreenSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                    Text("1-Tap Apply")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.jgPurple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.jgLilac, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .jgCard()
    }
}
