//
//  IOSConnectivityManager.swift
//  PrayerEase
//
//  Handles WatchConnectivity from iOS side to send data to watch
//

import Foundation
import WatchConnectivity

/// Manages communication with watchOS app from iOS
final class IOSConnectivityManager: NSObject, ObservableObject {
    static let shared = IOSConnectivityManager()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    /// Sends prayer data to watch via application context
    func sendPrayerDataToWatch(
        prayerTimes: [[String: Any]],
        locationName: String,
        islamicDate: String,
        isDuhaEnabled: Bool,
        isTahajjudEnabled: Bool
    ) {
        guard WCSession.default.activationState == .activated else {
            print("DEBUG iOS: WCSession not activated")
            return
        }

        let context: [String: Any] = [
            "prayerTimes": prayerTimes,
            "locationName": locationName,
            "islamicDate": islamicDate,
            "isDuhaEnabled": isDuhaEnabled,
            "isTahajjudEnabled": isTahajjudEnabled,
            "timestamp": Date().timeIntervalSince1970,
        ]

        do {
            try WCSession.default.updateApplicationContext(context)
            print("DEBUG iOS: Sent prayer data to watch via application context")
        } catch {
            print("DEBUG iOS: Failed to send application context: \(error.localizedDescription)")
        }
    }

    /// Convenience method to send current prayer data
    func sendCurrentPrayerData() {
        guard let defaults = UserDefaults(suiteName: "group.com.alijaver.PrayerEase") else {
            return
        }

        // Convert SharedPrayerTime to dictionary for transfer
        var prayerDicts: [[String: Any]] = []

        if let data = defaults.data(forKey: "widgetPrayerTimes"),
            let times = try? JSONDecoder().decode([SharedPrayerTime].self, from: data)
        {
            prayerDicts = times.map { prayer in
                [
                    "name": prayer.name,
                    "time": prayer.time.timeIntervalSince1970,
                ]
            }
        }

        let locationName = defaults.string(forKey: "locationName") ?? ""
        let islamicDate = defaults.string(forKey: "islamicDate") ?? ""
        let isDuhaEnabled = defaults.bool(forKey: "isDuhaEnabled")
        let isTahajjudEnabled = defaults.bool(forKey: "isTahajjudEnabled")

        sendPrayerDataToWatch(
            prayerTimes: prayerDicts,
            locationName: locationName,
            islamicDate: islamicDate,
            isDuhaEnabled: isDuhaEnabled,
            isTahajjudEnabled: isTahajjudEnabled
        )
    }
}

// MARK: - WCSessionDelegate

extension IOSConnectivityManager: WCSessionDelegate {

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("DEBUG iOS: Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("DEBUG iOS: Session deactivated")
        session.activate()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("DEBUG iOS: Session activation failed: \(error.localizedDescription)")
        } else {
            print("DEBUG iOS: Session activated: \(activationState.rawValue)")
            // Send initial data when session activates
            if activationState == .activated {
                DispatchQueue.main.async {
                    self.sendCurrentPrayerData()
                }
            }
        }
    }

    func session(
        _ session: WCSession, didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        print("DEBUG iOS: Received message from watch: \(message)")

        if message["action"] as? String == "requestPrayerData" {
            // Watch is requesting prayer data
            DispatchQueue.main.async {
                self.sendCurrentPrayerData()
            }
            replyHandler(["status": "success"])
        }
    }
}
