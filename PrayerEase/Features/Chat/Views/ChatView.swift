//
//  ChatView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/6/24.
//



import OpenAI
import SwiftUI

class ChatController: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var botTypingText: String = "" // New property for typing animation
    
    let openAI = OpenAI(apiToken: "")

    @MainActor
    func sendNewMessage(content: String) {
        isLoading = true
        botTypingText = "" // Reset typing text
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMessage = Message(content: content, isUser: true)
        self.messages.append(userMessage)
        
        // Start typing animation asynchronously
        startTypingAnimation()
        
        getBotReply()
    }
    
    @MainActor
    private func startTypingAnimation() {
        Task {
            while isLoading {
                botTypingText.append(".")
                if botTypingText.count > 3 {
                    botTypingText = ""
                }
                try await Task.sleep(nanoseconds: 500_000_000) // Update every 0.5 seconds
            }
            botTypingText = "" // Clear when done
        }
    }
    
    func getBotReply() {
        let query = ChatQuery(
            messages: self.messages.map {
                .init(role: .user, content: $0.content)!
            },
            model: .gpt4_turbo
        )
        
        openAI.chats(query: query) { result in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            switch result {
            case .success(let success):
                guard let choice = success.choices.first else {
                    return
                }
                guard let message = choice.message.content?.string else { return }
                DispatchQueue.main.async {
                    self.messages.append(Message(content: message, isUser: false))
                }
            case .failure(let failure):
                print(failure)
            }
        }
    }
}

struct Message: Identifiable {
    var id: UUID = .init()
    var content: String
    var isUser: Bool
}

struct ChatView: View {
    @StateObject var chatController: ChatController = .init()
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
                                    .foregroundColor(.gray)
                                    .italic()
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        Spacer().id(bottomID) // Anchor for scrolling
                    }
                }
                .onChange(of: chatController.messages.count) { _,_ in
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
                    .cornerRadius(8)
                
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
                        .foregroundColor(Color(.label))
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
