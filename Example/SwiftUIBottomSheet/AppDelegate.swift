//
//  AppDelegate.swift
//  SwiftUIBottomSheet
//
//  Created by horovodovodo4ka on 12/23/2021.
//  Copyright (c) 2021 horovodovodo4ka. All rights reserved.
//

import UIKit
import SwiftUI
import SwiftUIBottomSheet

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        window.rootViewController = UIHostingController(rootView: ContentView())
//        window.rootViewController = UIHostingController(rootView: BottomSheet_Preview.Preview())
        self.window = window
        window.makeKeyAndVisible()

        return true
    }
}

