//
//  Untitled.swift
//  AGETEKO
//
//  Created by chang chiawei on 2025-03-24.
//

import SwiftUI
import MLCSwift

struct ChatView2: View {
    @State private var messages: [String] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false

    // 建立 MLCEngine 實例
    let engine = MLCEngine()

    var body: some View {
        VStack {
            // 聊天紀錄區：捲動視圖展示對話內容
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages, id: \.self) { message in
                        Text(message)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            // 輸入與送出區
            HStack {
                TextField("請輸入訊息...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 40)
                Button(action: {
                    Task { await sendMessage() }
                }) {
                    Text("送出")
                        .bold()
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding()
        }
        .navigationTitle("LLM 聊天")
        .onAppear {
            // 初始化引擎
            Task { await initializeEngine() }
        }
    }
    
    // 初始化 MLCEngine，載入模型權重與對應的庫
    func initializeEngine() async {
        // 請根據實際狀況修改 modelPath 與 modelLib
        // 若模型權重是內嵌在 app 中，可透過 Bundle 取得路徑
        
        
        let modelPath = Bundle.main.path(forResource: "gemma-3-1b-it-q4f16_1", ofType: nil)!
        let modelLib = "gemma3_text_q4f16_1_c84175f9cc586f4a4ec3b3280b5ffc94"
        
        await engine.reload(modelPath: modelPath, modelLib: modelLib)
        // 可以在初始化後加入提示訊息
        DispatchQueue.main.async {
            messages.append("系統：模型初始化完成！")
        }
    }
    
    // 發送使用者訊息並取得 LLM 回應
    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = inputText
        DispatchQueue.main.async {
            messages.append("使用者：\(userMessage)")
            inputText = ""
            isLoading = true
        }
        
        
        
        // 呼叫 LLM API，這裡模仿 OpenAI API 的風格進行補全
        for await res in await engine.chat.completions.create(
            messages: [
                ChatCompletionMessage(role: .user, content: userMessage)
            ]
        ) {
            if let delta = res.choices.first?.delta.content {
                let text = delta.asText()
                DispatchQueue.main.async {
                    messages.append("LLM：\(text)")
                }
            }
        }
        
        print(messages)
        
        DispatchQueue.main.async {
            isLoading = false
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatView()
        }
    }
}

