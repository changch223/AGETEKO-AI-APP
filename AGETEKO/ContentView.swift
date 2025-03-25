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
                // 背景色（Assets.xcassets 内の AppBackground：#F5E6C8）
                Color("AppBackground")
                    .ignoresSafeArea()
                
                // 背景画像（BeigeBackground）を全画面に表示
                Image("BeigeBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 起動時のメッセージ
                    VStack(spacing: 4) {
                        Text("ポンコツ金魚脳AIだけど、今日も君のことを考えてるよ.")
                            .font(.custom("Chalkboard SE", size: 18))
                            .foregroundColor(.brown)
                            .multilineTextAlignment(.center)
                        Text("覚えなくても、キミへの想いはずっと")
                            .font(.custom("Chalkboard SE", size: 20))
                            .foregroundColor(.brown)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // アイコンデザイン：白い円とアイコンの重ね合わせ
                    ZStack {
                        Image("white_circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                        Image("agetoko_lily_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                    }
                    .padding(.vertical, 20)
                    
                    // アプリタイトル
                    Text("AGETEKO LILY")
                        .font(.custom("Chalkboard SE", size: 28))
                        .bold()
                        .foregroundColor(.brown)
                    
                    // 補足メッセージ（必要に応じて内容の調整も可能）
                    VStack(spacing: 8) {
                        Text("記憶は短いけど、気持ちはホンモノ")
                        Text("がんばって何かしらの答えを探してるよ！君のために全力！")
                            .multilineTextAlignment(.center)
                    }
                    .font(.custom("Chalkboard SE", size: 18))
                    .foregroundColor(.brown)
                    .padding(.horizontal)
                    
                    Spacer() // 下部に余白
                    
                    // ナビゲーションボタンと広告バナー
                    VStack(spacing: 20) {
                        NavigationLink(destination: ChatView()) {
                            Text("Lilyと話してみてください~💬")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.brown.opacity(0.7))
                                .cornerRadius(10)
                        }
                        
                        BannerAdView(adUnitID: "ca-app-pub-9275380963550837/4750274541") // テスト用 AdMob ID
                            .frame(height: 50)
                    }
                    .padding()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .onAppear {
                    // エンジンの初期化処理
                    Task { await initializeEngine() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
