//
//  CSUSM_ARApp.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/1/23.
//

import SwiftUI
//import FirebaseCore


//class AppDelegate: NSObject, UIApplicationDelegate {
//  func application(_ application: UIApplication,
//                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//    FirebaseApp.configure()
//    return true
//  }
//}


@main
struct CSUSM_ARApp: App {
    
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            NavigationStack(root: { HomeView() })
        }
    }
}
