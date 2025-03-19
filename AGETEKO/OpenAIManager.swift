//
//  OpenAI.swift
//  AGETEKO
//
//  Created by chang chiawei on 2025-03-19.
//

import OpenAI

let openAI = OpenAI(apiToken: Secrets.openAIKey)

func sendChatMessage(message: String, completion: @escaping (String) -> Void) {
    guard let userMessage = ChatQuery.ChatCompletionMessageParam(role: .user, content: message) else {
        completion("メッセージを作成できませんでした😢")
        return
    }

    let query = ChatQuery(
        messages: [userMessage],
        model: .gpt3_5Turbo
    )

    openAI.chats(query: query) { result in
            switch result {
            case .success(let response):
                if let content = response.choices.first?.message.content {
                    completion("\(content)")
                } else {
                    completion("応答なし")
                }
            case .failure(let error):
                print("Error:", error.localizedDescription)
                completion("なんか問題あったっぽい🥺")
            }
        }
}
    
