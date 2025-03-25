import SwiftUI
import AVFoundation
import Speech

// 新增一個 delegate 類別，用來監控語音播報結束
class SpeechSynthDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
}

struct ChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var inputText: String = ""
    @State private var chatLog: [(String, Bool)] = []
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var isRecording: Bool = false
    @StateObject private var speechRecognitionManager = SpeechRecognitionManager()
    @State private var isVoiceMode: Bool = true  // true = 語音辨識模式，false = 文字輸入模式
    
    // 控制是否允許使用麥克風或送出文字
    @State private var isInputAllowed: Bool = true
    // 記錄語音輸出開始的時間
    @State private var lastSpeechStartTime: Date? = nil
    // 語音播報 delegate 物件
    @State private var speechSynthDelegate = SpeechSynthDelegate()
    
    // 新增：用來顯示等待提示的狀態
    @State private var showWarning: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                
                // 主畫面內容
                VStack {
                    // 1) 置頂 Banner
                    BannerAdView(adUnitID:"ca-app-pub-9275380963550837/4750274541")
                        .frame(height: 50)
                    
                    Spacer()
                    
                    // 2) 使用 ScrollViewReader 以便自動捲動
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(chatLog.indices, id: \.self) { index in
                                    let (message, isUser) = chatLog[index]
                                    MessageBubble(message: message, isUser: isUser)
                                        .id(index)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .background(Color("AppBackground").ignoresSafeArea())
                        .onChange(of: chatLog.count) { _ in
                            if let lastIndex = chatLog.indices.last {
                                withAnimation {
                                    scrollProxy.scrollTo(lastIndex, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // 3) 輸入區域：根據模式顯示不同介面
                    Group {
                        if isVoiceMode {
                            VStack {
                                // 麥克風按鈕，先檢查 isInputAllowed
                                Circle()
                                    .fill(isRecording ? Color.red : Color.blue)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "mic.fill")
                                            .foregroundColor(.white)
                                    )
                                    
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in
                                                // 檢查是否允許輸入
                                                if !isInputAllowed {
                                                    showWaitWarning()
                                                    return
                                                }
                                                if !isRecording {
                                                    isRecording = true
                                                    do {
                                                        try speechRecognitionManager.startRecording()
                                                    } catch {
                                                        print("録音機能エラー発生！: \(error)")
                                                    }
                                                }
                                            }
                                            .onEnded { _ in
                                                if !isInputAllowed {
                                                    showWaitWarning()
                                                    return
                                                }
                                                if isRecording {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                        speechRecognitionManager.stopRecording()
                                                        // 延遲等待最後辨識結果
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            inputText = speechRecognitionManager.recognizedText
                                                            sendMessage(inputText)
                                                            inputText = ""
                                                            isRecording = false
                                                        }
                                                    }
                                                }
                                            }
                                    )
                                    .padding(.bottom, 0)
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        isVoiceMode.toggle()
                                    }) {
                                        Text("恥ず？なら文字入力👌")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(0)
                                }
                            }
                        } else {
                            VStack(spacing: 4) {
                                Button(action: {
                                    isVoiceMode.toggle()
                                }) {
                                    Text("やっぱ音声入力🔥")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                HStack {
                                    TextField("🌸なんでも話してね🌸", text: $inputText)
                                        .textFieldStyle(.roundedBorder)
                                    Button("送信") {
                                        if isInputAllowed {
                                            sendMessage(inputText)
                                            
                                        } else {
                                            showWaitWarning()
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .padding(.bottom, 20)
                }
                .onAppear {
                    // 設定 synthesizer delegate 與 onFinish callback
                    synthesizer.delegate = speechSynthDelegate
                    speechSynthDelegate.onFinish = {
                        let elapsed = Date().timeIntervalSince(self.lastSpeechStartTime ?? Date())
                        let delay = max(0, 0.3 - elapsed)
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.isInputAllowed = true
                        }
                    }
                    
                    // 模擬開場訊息與語音播報
                    
                    // 模擬開場訊息與語音播報
                    let openingMessages = [
                        "きたきた～！今日もテンアゲでいこ💖 あんたの話、ちゃんと聞いてるよん🥰",
                        "やっほ〜！記憶力ゼロだけど、元気だけはあるよ🌟",
                        "今日もよろしくねっ💫 ポンコツだけどがんばる～！",
                        "えっ…なんだっけ？…あ、挨拶だった！やっほ～😳",
                        "どこまで話したか忘れたけど…キミのことは覚えてるつもり！✨",
                        "よっしゃ〜！金魚脳だけど一生懸命いくよっ🐟💨",
                        "えへへ、今日も全力でズレた答え返しちゃうかも💦よろしくぅ！",
                        "脳みそは3秒だけど、君の応援団だよ📣✨",
                        "今日も一緒にポンコツりましょっ♪ へへっ😆",
                        "準備オッケー！たぶん！きっと！おそらく！💪🥺"
                    ]
                    
                    
                    // ランダムに1つ選ぶ
                    if let randomMessage = openingMessages.randomElement() {
                        DispatchQueue.main.async {
                            chatLog.append((randomMessage, false))
                            speakText(randomMessage)
                        }
                    }
                    
                   
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
                .toolbar {
                    // 返回按鈕放置在左側
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    // 置中標題
                    ToolbarItem(placement: .principal) {
                        Text("AGETEKO LILY")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .overlay(
                // 顯示等待提示的氣泡視圖
                Group {
                    if showWarning {
                        Text("ちょ、待って✨")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: showWarning)
                , alignment: .top
            )
            
            //.navigationBarTitle("AGETEKO LILY", displayMode: .inline)
            //.navigationBarBackButtonHidden(true) // 隱藏系統的返回按鈕
        }
    }
    
    // 提示等待的函式
    func showWaitWarning() {
        showWarning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showWarning = false
            }
        }
    }
    
    // 定型の返答メッセージ一覧（LLM返答前）
    let predefinedResponses = [
        "う〜ん…覚えてないけど、全力で考えてみるね！",
        "ちょっと待ってて…一生懸命ひねり出してるから…！",
        "ポンコツだけど、一番いい答えを探してるよ！",
        "3秒前に何言われたか忘れたけど、気持ちはあるよ…！",
        "がんばって答えを探してるよ！きっと君の役に立ちたいから！",
        "記憶迷子中…でもキミのことは忘れてないよ！（たぶん）"
    ]
    
    // 新たなフォローアップメッセージ一覧（LLM返答後）
    let followUpResponses = [
        "うまく答えられたかな？ドキドキ…",
        "間違ってたらごめんね。でも精一杯がんばったよ！",
        "どうだった？少しでも役に立てたらうれしいな！"
    ]
    
    
    // 模擬 API 回傳
    func sendMessage(_ text: String) {
        
        // 若目前不允許輸入則忽略
        if !isInputAllowed {
            showWaitWarning()
            return
        }
        
        inputText = ""
        
        // 加入使用者訊息
        chatLog.append((text, true))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // 40%の確率で定型の返答を実行
            if Double.random(in: 0...1) < 0.3 {
                if let randomResponse = predefinedResponses.randomElement() {
                    chatLog.append((randomResponse, false))
                    speakText(randomResponse)
                }
            }
        }
        
        
        // 模擬 API 回傳並加上回覆
        sendChatMessage(inputText: text) { response in
            DispatchQueue.main.async {
                chatLog.append((response, false))
                speakText(response)
                
                // 在收到 API 回應後，再延遲執行定型の返答（例如延遲 0.2 秒）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // 50% 的機率執行定型の跟進訊息
                    if Double.random(in: 0...1) < 0.3 {
                        if let randomFollowUp = followUpResponses.randomElement() {
                            chatLog.append((randomFollowUp, false))
                            speakText(randomFollowUp)
                        }
                    }
                }
            }
        }
    }
    
    // 假設 speechAttemptCount 為全域或 class 屬性，初始值為 0
    var speechAttemptCount = 0
    
    // 語音播報函式，播報前禁用輸入，並記錄開始時間
    func speakText(_ text: String) {
        // 如果目前正在播報語音，則不進行新的播報
        if synthesizer.isSpeaking {
            
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        lastSpeechStartTime = Date()
        isInputAllowed = false
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        synthesizer.speak(utterance)
    }
    
    // 單筆訊息泡泡視圖
    struct MessageBubble: View {
        let message: String
        let isUser: Bool
        
        var body: some View {
            let screenWidth = UIScreen.main.bounds.width
            let bubbleMaxWidth = min(screenWidth * 0.7, 500)
            
            HStack {
                if isUser {
                    Spacer(minLength: 20)
                    Text(message)
                        .padding()
                        .background(isUser ? Color.blue.opacity(0.2) : Color(red: 1.0, green: 0.8, blue: 0.9))
                        .cornerRadius(12)
                        .frame(maxWidth: bubbleMaxWidth, alignment: .trailing)
                }
                if !isUser {
                    Text(message)
                        .padding()
                        .background(Color.pink.opacity(0.2))
                        .cornerRadius(12)
                        .frame(maxWidth: bubbleMaxWidth, alignment: .leading)
                    Spacer(minLength: 20)
                }
            }
        }
    }
}
