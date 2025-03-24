//
//  ContentView.swift
//  AGETEKO
//
//  Created by chang chiawei on 2025-03-18.
//

import SwiftUI
import GoogleMobileAds

struct ContentView: View {
    @StateObject var speechRecognizer = SpeechRecognitionManager()

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景顏色（Assets.xcassets 內設定 AppBackground 為 #F5E6C8）
                Color("AppBackground")
                    .ignoresSafeArea()
                
                // 背景圖片填滿整個畫面
                Image("BeigeBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 15) {
                    // 插圖組合 (使用 ZStack 來重疊 white_circle + agetoko_lily_icon)
                    ZStack {
                        Image("white_circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180) // 適當調整大小
                        
                        Image("agetoko_lily_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                    }
                    
                    // 標題
                    Text("AGETOKO LILY")
                        .font(.custom("Chalkboard SE", size: 24)) // 更有手寫感
                        .bold()
                        .foregroundColor(.brown)
                    
                    // 主內容文字
                    VStack(spacing: 8) {
                        Text("今日も一日めっちゃ頑張ったね！")
                        Text("めっちゃ褒めたる〜")
                    }
                    .font(.custom("Chalkboard SE", size: 18))
                    .foregroundColor(.brown)
                    
                    Spacer() // 推開下方空間
                    
                    VStack(spacing: 20) {
                        NavigationLink(destination: ChatView2()) {
                            Text("アゲアゲで話そ↑↑チャット開幕〜💬")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.brown.opacity(0.3))
                                .cornerRadius(10)
                        }

                        Spacer() // 讓廣告顯示在底部

                        BannerAdView(adUnitID: "ca-app-pub-9275380963550837/4750274541") // 測試 AdMob ID
                            .frame(height: 50) // 設定 banner 高度
                    }
                    .padding()
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    ContentView()
}
