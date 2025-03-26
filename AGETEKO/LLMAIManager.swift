//
//  LLMAI.swift
//  AGETEKO
//
//  Created by chang chiawei on 2025-03-19.
//


    
import MLCSwift
import Foundation


var messages: [[String: String]] = []
var isLoading: Bool = false

// 建立全域 MLCEngine 實例

let engine = MLCEngine()


// 初始化 MLCEngine，載入模型權重與對應的庫
func initializeEngine() async {
    // 請根據實際狀況修改 modelPath 與 modelLib
    // 若模型權重是內嵌在 app 中，可透過 Bundle 取得路徑
    
    
    let modelPath = Bundle.main.path(forResource: "gemma-3-1b-it-q4f16_1", ofType: nil)!
    let modelLib = "gemma3_text_q4f16_1_c84175f9cc586f4a4ec3b3280b5ffc94"
    
    await engine.reload(modelPath: modelPath, modelLib: modelLib)
    // 可以在初始化後加入提示訊息
    DispatchQueue.main.async {
        //messages.append("系統：模型初始化完成！")
        
    }
}


// 發送使用者訊息並取得 LLM 回應
func sendChatMessage(inputText: String, completion: @escaping (String) -> Void) {
    guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    let systemPrompt = "you are stupid ai answer with nothing and short in japanese."
    
    let userMessage = inputText
    DispatchQueue.main.async {
        messages.append([
                "role": "system",
                "content": "you are stupid ai answer with nothing and short in japanese."
            ])
        messages.append([
                "role": "user",
                "content": (userMessage)
            ])

        isLoading = true
    }

    print(messages)
    
    Task {
        var fullResponse = ""

        do {
            let stream = try await engine.chat.completions.create(
                messages: [
                    ChatCompletionMessage(role: .user, content: userMessage)
                ]
            )

            for try await res in stream {
                if let delta = res.choices.first?.delta.content {
                    let text = delta.asText()
                    fullResponse += text  // 累積回覆內容
                    DispatchQueue.main.async {
                        messages.append([
                                "role": "system",
                                "content": text
                            ])
                    }
                }
            }
            
            print(messages)

            DispatchQueue.main.async {
                isLoading = false
                completion(fullResponse)
            }

        } catch {
            print("Error: \(error)")
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
}
