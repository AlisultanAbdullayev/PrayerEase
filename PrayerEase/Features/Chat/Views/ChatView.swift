//
//  ChatView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/6/24.
//



@preconcurrency import OpenAI
import SwiftUI

@MainActor
@Observable
final class ChatController {
    var messages: [Message] = []
    var isLoading = false
    var botTypingText: String = "" // New property for typing animation
    
    private let openAI = OpenAI(apiToken: "")
    private var typingTask: Task<Void, Never>?

    func sendNewMessage(content: String) {
        isLoading = true
        botTypingText = "" // Reset typing text
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMessage = Message(content: content, isUser: true)
        self.messages.append(userMessage)
        
        // Start typing animation asynchronously
        startTypingAnimation()
        
        Task {
            await getBotReply()
        }
    }
    
    private func startTypingAnimation() {
        typingTask?.cancel()
        typingTask = Task {
            while isLoading {
                botTypingText.append(".")
                if botTypingText.count > 3 {
                    botTypingText = ""
                }
                try? await Task.sleep(for: .milliseconds(500)) // Update every 0.5 seconds
            }
            botTypingText = "" // Clear when done
        }
    }
    
    private func getBotReply() async {
        let query = ChatQuery(
            messages: self.messages.map {
                .init(role: .user, content: $0.content)!
            },
            model: .gpt4_turbo
        )
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                openAI.chats(query: query) { result in
                    switch result {
                    case .success(let success):
                        continuation.resume(returning: success)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            isLoading = false
            
            guard let choice = result.choices.first else {
                return
            }
            guard let message = choice.message.content?.string else { return }
            self.messages.append(Message(content: message, isUser: false))
        } catch {
            isLoading = false
            print("Chat error: \(error)")
        }
    }
}

struct Message: Identifiable {
    var id: UUID = .init()
    var content: String
    var isUser: Bool
}

struct ChatView: View {
    @State private var chatController = ChatController()
    @State private var userMessage = ""
    @Namespace private var bottomID // For scroll animation

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        ForEach(chatController.messages) { message in
                            MessageView(message: message)
                                .padding(5)
                        }
                        if chatController.isLoading {
                            HStack {
                                Text("AI is typing\(chatController.botTypingText)")
                                    .foregroundStyle(.secondary)
                                    .italic()
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        Spacer().id(bottomID) // Anchor for scrolling
                    }
                }
                .onChange(of: chatController.messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(bottomID)
                    }
                }
            }
            
            Divider()
            
            HStack {
                TextField("Message...", text: $userMessage, axis: .vertical)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 8))
                
                Button("Send") {
                    chatController.sendNewMessage(content: userMessage)
                    userMessage = ""
                }
                .disabled(userMessage.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

extension View {
  func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

struct MessageView: View {
    var message: Message
    var body: some View {
        Group {
            if message.isUser {
                HStack {
                    Spacer()
                    Text(attributedContent(message.content))
                        .padding()
                        .background(.green.opacity(0.3))
                        .foregroundStyle(Color(.label))
                        .clipShape(.rect(cornerRadius: 15))
                }
            } else {
                HStack {
                    Text(attributedContent(message.content))
                        .padding()
                        .background(.regularMaterial)
                        .foregroundStyle(Color(.label))
                        .clipShape(.rect(cornerRadius: 15))
                    Spacer()
                }
            }
        }
    }
    
    private func attributedContent(_ content: String) -> AttributedString {
        var attributedString = AttributedString(content)
        
        // Regex for bold text
        let boldRegex = try? NSRegularExpression(pattern: "\\*\\*(.*?)\\*\\*", options: [])
        
        // Regex for headers
        let headerRegex = try? NSRegularExpression(pattern: "###\\s*(.*?)(?=\\n|$)", options: [])
        
        let range = NSRange(location: 0, length: content.utf16.count)
        
        // Process bold text
        boldRegex?.matches(in: content, options: [], range: range).forEach { match in
            if let swiftRange = Range(match.range(at: 1), in: content) {
                let boldText = String(content[swiftRange])
                
                if let fullMatchRange = attributedString.range(of: "**" + boldText + "**") {
                    attributedString.replaceSubrange(fullMatchRange, with: AttributedString(boldText, attributes: .init().font(.body.bold())))
                }
            }
        }
        
        // Process headers
        headerRegex?.matches(in: content, options: [], range: range).forEach { match in
            if let swiftRange = Range(match.range(at: 1), in: content) {
                let headerText = String(content[swiftRange])
                
                if let fullMatchRange = attributedString.range(of: "### " + headerText) {
                    attributedString.replaceSubrange(fullMatchRange, with: AttributedString(headerText, attributes: .init().font(.headline)))
                }
            }
        }
        
        return attributedString
    }
}


#Preview {
    ChatView()
}
