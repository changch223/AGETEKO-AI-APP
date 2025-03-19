//
//  Untitled.swift
//  AGETEKO
//
//  Created by chang chiawei on 2025-03-19.
//

import SwiftUI
import AVFoundation


struct ChatView: View {
    @State private var inputText: String = ""
    @State private var chatLog: [String] = []
    @State private var synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(chatLog, id: \.self) { message in
                        Text(message)
                            .padding()
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }

            HStack {
                TextField("なんでも話してね🌸", text: $inputText)
                    .textFieldStyle(.roundedBorder)

                Button("送信") {
                    chatLog.append("自分: \(inputText)")
                    sendMessage(inputText)
                    inputText = ""
                }
            }
            .padding()
        }
        .padding()
    }

    func sendMessage(_ text: String) {
        sendChatMessage(message: "ギャル語で全力で褒めて: \(text)") { response in
            DispatchQueue.main.async {
                chatLog.append("LILY: \(response)")
                speakText(response)
            }
        }
    }

    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        synthesizer.speak(utterance)
    }
}
