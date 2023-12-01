//
//  CSUSM_ARApp.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/1/23.
//

import SwiftUI

@main
struct CSUSM_ARApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    var body: some Scene {
        WindowGroup {
        //Welcome()
       NavigationStack(root: { HomeView() })
        .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
