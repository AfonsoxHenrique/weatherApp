//
//  AppDelegate.swift
//  weatherApp
//
//  Created by Afonso Henrique Freitas de Paula on 4/3/2026.
//

import UIKit
import Firebase


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()

        return true
    }

}

