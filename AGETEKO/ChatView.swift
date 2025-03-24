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
                                    .opacity(isInputAllowed ? 1.0 : 0.4) // 降低不允許輸入時的透明度
                                    .allowsHitTesting(isInputAllowed) // 阻止觸控事件
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
                                                        print("錄音功能發生錯誤: \(error)")
                                                    }
                                                }
                                            }
                                            .onEnded { _ in
                                                if !isInputAllowed {
                                                    showWaitWarning()
                                                    return
                                                }
                                                if isRecording {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                        speechRecognitionManager.stopRecording()
                                                        // 延遲等待最後辨識結果
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
                                    TextField("なんでも話してね🌸", text: $inputText)
                                        .textFieldStyle(.roundedBorder)
                                    Button("送信") {
                                        if isInputAllowed {
                                            sendMessage(inputText)
                                            inputText = ""
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
                        let delay = max(0, 3 - elapsed)
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.isInputAllowed = true
                        }
                    }
                    
                    // 模擬開場訊息與語音播報
                    let initialMessages = [
                        "きたきた～！今日もテンアゲでいこ💖 広告なんて気にしないで、あんたの話、ちゃんと聞いてるよん🥰"
                    ]
                    
                    for (index, text) in initialMessages.enumerated() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index)) {
                            chatLog.append((text, false))
                            speakText(text)
                        }
                    }
                   
                }
                .navigationBarTitleDisplayMode(.inline)
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
                        Text("ちょ、待って！まだしゃべってるの〜✨")
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
            .navigationBarHidden(true)
        }
    }
    
    // 提示等待的函式
    func showWaitWarning() {
        showWarning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showWarning = false
            }
        }
    }
    
    // 模擬 API 回傳
    func sendMessage(_ text: String) {
        // 若目前不允許輸入則忽略
        if !isInputAllowed {
            showWaitWarning()
            return
        }
        // 加入使用者訊息
        chatLog.append((text, true))
        
        // 模擬 API 回傳並加上回覆
        sendChatMessage(inputText: text) { response in
            DispatchQueue.main.async {
                chatLog.append((response, false))
                speakText(response)
            }
        }
    }
    
    // 語音播報函式，播報前禁用輸入，並記錄開始時間
    func speakText(_ text: String) {
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
