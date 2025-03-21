import Foundation
import Speech

class SpeechRecognitionManager: ObservableObject {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    @Published var recognizedText: String = ""
    @Published var isAuthorized: Bool = false
    
    init() {
            requestSpeechRecognitionPermission()
        }

        func requestSpeechRecognitionPermission() {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    switch authStatus {
                    case .authorized:
                        self.isAuthorized = true
                    case .denied, .restricted, .notDetermined:
                        self.isAuthorized = false
                        print("音声認識、許可されてな～い💦")
                    @unknown default:
                        self.isAuthorized = false
                    }
                }
            }
        }
    

    func startRecording() throws {
        guard isAuthorized else {
                    print("マイク許可されてないっぽ〜！設定確認して🎤")
                    return
                }
        
        // 配置 AVAudioSession
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 取消現有任務（如果有的話）
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 建立新的 recognitionRequest
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "Speech Recognition Error", code: -1, userInfo: nil)
        }
        recognitionRequest.shouldReportPartialResults = true

        // 開始識別任務
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording() // 呼叫新增的 stopRecording 方法
            }
        }

        // 取得麥克風輸入節點並安裝 tap
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    // 停止錄音與識別
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
    }

    // 取消錄音與識別（如果需要其他取消行為）
    func cancelRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
