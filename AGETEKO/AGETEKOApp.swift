//
//  AGETEKOApp.swift
//  AGETEKO
//
//  Created by chang chiawei on 2025-03-18.
//

import SwiftUI
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    MobileAds.shared.start(completionHandler: nil)

    return true
  }
}

@main
struct AGETEKOApp: App {
  // To handle app delegate callbacks in an app that uses the SwiftUI lifecycle,
  // you must create an application delegate and attach it to your `App` struct
  // using `UIApplicationDelegateAdaptor`.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    init() {
            AppOpenAdManager.shared.loadAd()
        }

    var body: some Scene {
        WindowGroup {
                    ContentView()
                        .onAppear {
                            // 起動直後に表示
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                AppOpenAdManager.shared.showAdIfAvailable()
                            }
                        }
                        .onChange(of: scenePhase) { newPhase, _ in
                            if newPhase == .active {
                                AppOpenAdManager.shared.showAdIfAvailable()
                            }
                        }
                }
    }
}
