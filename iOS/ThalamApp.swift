import HealthKit
import SwiftUI
import UIKit

@main
struct ThalamApp: App {
    @UIApplicationDelegateAdaptor(PhoneAppDelegate.self) private var appDelegate
    @StateObject private var model = PracticeModel()

    var body: some Scene {
        WindowGroup {
            PracticeView()
                .environmentObject(model)
                .tint(Color.kumkum)
        }
    }
}

/// Older watchOS versions ask the iPhone to show the HealthKit permission
/// screen for the Watch app. This hook lets the iPhone do that.
final class PhoneAppDelegate: NSObject, UIApplicationDelegate {
    private let healthStore = HKHealthStore()

    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        healthStore.handleAuthorizationForExtension { _, error in
            if let error {
                print("HealthKit authorisation for the watch failed: \(error.localizedDescription)")
            }
        }
    }
}
