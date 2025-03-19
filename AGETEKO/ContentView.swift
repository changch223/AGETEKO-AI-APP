//
//  ContentView.swift
//  AGETEKO
//
//  Created by chang chiawei on 2025-03-18.
//

import SwiftUI


import SwiftUI

struct ContentView: View {
    @StateObject var speechRecognizer = SpeechRecognitionManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("アゲてこ↑↑ LILY✨")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.pink)

                NavigationLink("チャット開始💬") {
                    ChatView()
                }

                Text(speechRecognizer.recognizedText)
                    .padding()

                Button("語音輸入開始🎙️") {
                    do {
                        try speechRecognizer.startRecording()
                    } catch {
                        print("無法啟動語音識別：\(error)")
                    }
                }

                Button("停止") {
                    speechRecognizer.cancelRecording()
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}


