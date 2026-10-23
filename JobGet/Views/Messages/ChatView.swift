import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var state
    let conversationID: UUID
    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    private var conversation: Conversation? { state.conversation(id: conversationID) }

    var body: some View {
        VStack(spacing: 0) {
            if let conversation {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            contextCard(conversation)
                            ForEach(conversation.messages) { message in
                                MessageBubble(message: message, color: conversation.logoColor)
                                    .id(message.id)
                            }
                            if conversation.isTyping {
                                TypingIndicator().id("typing")
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color.jgSurface)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: conversation.messages.count) { scrollToBottom(proxy) }
                    .onChange(of: conversation.isTyping) { scrollToBottom(proxy) }
                    .onChange(of: inputFocused) { scrollToBottom(proxy) }
                    .onAppear { scrollToBottom(proxy, animated: false) }
                }
                quickReplies(conversation)
                inputBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let conversation {
                    HStack(spacing: 10) {
                        Avatar(name: conversation.counterpartName, color: conversation.logoColor, size: 32)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(conversation.counterpartName).font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                            HStack(spacing: 4) {
                                Circle().fill(Color.jgGreen).frame(width: 6, height: 6)
                                Text("Online · \(conversation.counterpartRole), \(conversation.company)")
                            }
                            .font(.caption2)
                            .foregroundStyle(Color.jgMuted)
                            .lineLimit(1)
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { } label: { Image(systemName: "phone.fill") }
                    .accessibilityLabel("Call")
            }
        }
        .onAppear { state.markRead(conversationID) }
        .onChange(of: conversation?.messages.count) { state.markRead(conversationID) }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if animated {
                withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("bottom", anchor: .bottom) }
            } else {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private func contextCard(_ conversation: Conversation) -> some View {
        HStack(spacing: 12) {
            LogoBadge(symbol: conversation.logoSymbol, color: conversation.logoColor, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.company).font(.subheadline.weight(.semibold)).foregroundStyle(Color.jgInk)
                Text("Messages are end-to-end in JobGet. Never share bank details in chat.")
                    .font(.caption).foregroundStyle(Color.jgMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.jgLine))
        .padding(.bottom, 6)
    }

    private func quickReplies(_ conversation: Conversation) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(conversation.quickReplies, id: \.self) { reply in
                    Button {
                        state.send(reply, in: conversationID)
                    } label: {
                        Text(reply)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.jgPurple)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.jgLilac, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("quick-reply")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.white)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button { } label: {
                Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Color.jgMuted)
            }
            .accessibilityLabel("Attach")
            TextField("Message", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.jgSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .focused($inputFocused)
                .onSubmit(send)
                .accessibilityIdentifier("message-input")
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? Color.jgMuted.opacity(0.4) : Color.jgPurple)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Send")
            .accessibilityIdentifier("send-button")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(alignment: .top) { Divider() }
    }

    private func send() {
        state.send(draft, in: conversationID)
        draft = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let color: Color

    var body: some View {
        switch message.kind {
        case .system:
            Text(message.text)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.jgMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.jgLine.opacity(0.6), in: Capsule())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        case .interview(let day, let time):
            VStack(alignment: .leading, spacing: 10) {
                Label("Interview confirmed", systemImage: "calendar.badge.checkmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.jgGreen)
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day).font(.headline).foregroundStyle(Color.jgInk)
                        Text(time).font(.subheadline).foregroundStyle(Color.jgMuted)
                    }
                    Spacer()
                    Text("Add to calendar")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.jgPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.jgLilac, in: Capsule())
                }
            }
            .padding(14)
            .frame(maxWidth: 290, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.jgGreen.opacity(0.4)))
            .frame(maxWidth: .infinity, alignment: .leading)
        case .shiftTrade(let tradeID):
            ShiftTradeCard(tradeID: tradeID)
        case .tradeRequest(let tradeID):
            TradeRequestCard(tradeID: tradeID, inChat: true)
        case .text:
            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(message.isFromMe ? .white : Color.jgInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromMe ? Color.jgPurple : Color.white,
                        in: UnevenRoundedRectangle(
                            topLeadingRadius: 18, bottomLeadingRadius: message.isFromMe ? 18 : 6,
                            bottomTrailingRadius: message.isFromMe ? 6 : 18, topTrailingRadius: 18, style: .continuous)
                    )
                Text(message.date, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(Color.jgMuted)
            }
            .frame(maxWidth: 290, alignment: message.isFromMe ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: message.isFromMe ? .trailing : .leading)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.jgMuted)
                    .frame(width: 7, height: 7)
                    .offset(y: phase == index ? -4 : 0)
                    .animation(.easeInOut(duration: 0.3), value: phase)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(320))
                phase = (phase + 1) % 3
            }
        }
    }
}
