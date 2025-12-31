//
//  WatchConnectivityManager.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/24/25.
//

import Foundation
import WatchConnectivity

/// Manages communication between iOS app and watchOS app
@MainActor
@Observable
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    var isReachable = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func requestPrayerDataUpdate() {
        guard WCSession.default.activationState == .activated else {
            print("DEBUG Watch: Session not activated")
            return
        }

        let receivedContext = WCSession.default.receivedApplicationContext
        if !receivedContext.isEmpty {
            print("DEBUG Watch: Processing cached application context")
            processApplicationContext(receivedContext)
        }

        if WCSession.default.isReachable {
            let message = ["action": "requestPrayerData"]
            WCSession.default.sendMessage(
                message,
                replyHandler: { response in
                    print("DEBUG Watch: Received reply: \(response)")
                },
                errorHandler: { error in
                    print("DEBUG Watch: Error requesting data: \(error.localizedDescription)")
                })
        } else {
            print("DEBUG Watch: iOS app not reachable, using cached context")
        }
    }

    private func processApplicationContext(_ context: [String: Any]) {
        guard let prayerDicts = context["prayerTimes"] as? [[String: Any]] else {
            print("DEBUG Watch: No prayer times in context")
            return
        }

        var prayers: [SharedPrayerTime] = []
        for dict in prayerDicts {
            if let name = dict["name"] as? String,
                let timeInterval = dict["time"] as? TimeInterval
            {
                let time = Date(timeIntervalSince1970: timeInterval)
                prayers.append(SharedPrayerTime(name: name, time: time))
            }
        }

        let locationName = context["locationName"] as? String ?? ""
        let islamicDate = context["islamicDate"] as? String ?? ""
        let isDuhaEnabled = context["isDuhaEnabled"] as? Bool ?? false
        let isTahajjudEnabled = context["isTahajjudEnabled"] as? Bool ?? false

        print("DEBUG Watch: Processed \(prayers.count) prayers from context")
        print("DEBUG Watch: Location: \(locationName), Date: \(islamicDate)")

        Task { @MainActor in
            WatchDataManager.shared.updateFromContext(
                prayerTimes: prayers,
                locationName: locationName,
                islamicDate: islamicDate,
                isDuhaEnabled: isDuhaEnabled,
                isTahajjudEnabled: isTahajjudEnabled
            )
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                print("DEBUG Watch: Session activation failed: \(error.localizedDescription)")
            } else {
                print("DEBUG Watch: Session activated with state: \(activationState.rawValue)")
                if activationState == .activated {
                    self.requestPrayerDataUpdate()
                }
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            print("DEBUG Watch: Received application context update")
            self.processApplicationContext(applicationContext)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        Task { @MainActor in
            print("DEBUG Watch: Received message: \(message)")
            if message["prayerDataUpdated"] as? Bool == true {
                self.requestPrayerDataUpdate()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        Task { @MainActor in
            print("DEBUG Watch: Received user info")
            self.processApplicationContext(userInfo)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("DEBUG Watch: Reachability changed: \(session.isReachable)")
            if session.isReachable {
                self.requestPrayerDataUpdate()
            }
        }
    }
}
