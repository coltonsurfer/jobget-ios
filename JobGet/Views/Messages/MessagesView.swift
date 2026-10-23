import SwiftUI

struct MessagesView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state
        NavigationStack(path: $state.messagesPath) {
            List {
                ForEach(state.conversations) { conversation in
                    NavigationLink(value: conversation.id) {
                        ConversationRow(conversation: conversation)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 16))
                    .listRowSeparatorTint(Color.jgLine)
                    .accessibilityIdentifier("conversation-\(conversation.company)")
                }
            }
            .listStyle(.plain)
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: { Image(systemName: "square.and.pencil") }
                        .accessibilityLabel("New message")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                ChatView(conversationID: id)
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Avatar(name: conversation.counterpartName, color: conversation.logoColor, size: 52)
                LogoBadge(symbol: conversation.logoSymbol, color: conversation.logoColor, size: 20)
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(.white, lineWidth: 2))
                    .offset(x: 3, y: 3)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.counterpartName)
                        .font(.subheadline.weight(conversation.unreadCount > 0 ? .bold : .semibold))
                        .foregroundStyle(Color.jgInk)
                    Spacer()
                    if let last = conversation.lastMessage {
                        Text(last.date, format: .relative(presentation: .named))
                            .font(.caption)
                            .foregroundStyle(conversation.unreadCount > 0 ? Color.jgPurple : Color.jgMuted)
                    }
                }
                Text(conversation.company)
                    .font(.caption)
                    .foregroundStyle(Color.jgMuted)
                HStack(alignment: .top) {
                    Text(previewText)
                        .font(.subheadline)
                        .foregroundStyle(conversation.unreadCount > 0 ? Color.jgInk : Color.jgMuted)
                        .lineLimit(1)
                    Spacer()
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Color.jgPurple, in: Capsule())
                    }
                }
            }
        }
    }

    private var previewText: String {
        if conversation.isTyping { return "Typing…" }
        guard let last = conversation.lastMessage else { return "" }
        switch last.kind {
        case .interview(let day, let time): return "Interview confirmed · \(day) at \(time)"
        case .shiftTrade: return "Shift trade posted"
        case .tradeRequest: return "Trade request · awaiting approval"
        case .system: return last.text
        case .text: return last.isFromMe ? "You: \(last.text)" : last.text
        }
    }
}
