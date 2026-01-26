//
//  WatchConnectivityManager.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/24/25.
//

import Foundation
@preconcurrency import WatchConnectivity

/// Manages communication between iOS app and watchOS app
@MainActor
@Observable
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    var isReachable = false

    // Deduplication: track last processed context timestamp
    private var lastProcessedTimestamp: TimeInterval = 0

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func requestPrayerDataUpdate() {
        guard WCSession.default.activationState == .activated else { return }

        let receivedContext = WCSession.default.receivedApplicationContext
        if !receivedContext.isEmpty {
            processApplicationContext(receivedContext)
        }

        // Only request from iOS if reachable and we don't have recent data
        if WCSession.default.isReachable {
            let message = ["action": "requestPrayerData"]
            WCSession.default.sendMessage(message, replyHandler: { _ in }, errorHandler: { _ in })
        }
    }

    private func processApplicationContext(_ context: [String: Any]) {
        // Deduplication: check timestamp to avoid reprocessing same data
        let timestamp = context["timestamp"] as? TimeInterval ?? 0
        guard timestamp > lastProcessedTimestamp else { return }
        lastProcessedTimestamp = timestamp

        guard let prayerDicts = context["prayerTimes"] as? [[String: Any]] else { return }

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

        WatchDataManager.shared.updateFromContext(
            prayerTimes: prayers,
            locationName: locationName,
            islamicDate: islamicDate,
            isDuhaEnabled: isDuhaEnabled,
            isTahajjudEnabled: isTahajjudEnabled
        )
    }

    nonisolated private func extractAndProcessContext(_ context: [String: Any]) {
        // Extract values in nonisolated context before crossing isolation boundary
        let timestamp = context["timestamp"] as? TimeInterval ?? 0
        guard let prayerDicts = context["prayerTimes"] as? [[String: Any]] else { return }

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

        Task { @MainActor in
            self.processApplicationContextWithValues(
                timestamp: timestamp,
                prayers: prayers,
                locationName: locationName,
                islamicDate: islamicDate,
                isDuhaEnabled: isDuhaEnabled,
                isTahajjudEnabled: isTahajjudEnabled
            )
        }
    }

    private func processApplicationContextWithValues(
        timestamp: TimeInterval,
        prayers: [SharedPrayerTime],
        locationName: String,
        islamicDate: String,
        isDuhaEnabled: Bool,
        isTahajjudEnabled: Bool
    ) {
        // Deduplication: check timestamp to avoid reprocessing same data
        guard timestamp > lastProcessedTimestamp else { return }
        lastProcessedTimestamp = timestamp

        WatchDataManager.shared.updateFromContext(
            prayerTimes: prayers,
            locationName: locationName,
            islamicDate: islamicDate,
            isDuhaEnabled: isDuhaEnabled,
            isTahajjudEnabled: isTahajjudEnabled
        )
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard error == nil, activationState == .activated else { return }
        Task { @MainActor in
            self.requestPrayerDataUpdate()
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        self.extractAndProcessContext(applicationContext)
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        if message["prayerDataUpdated"] as? Bool == true {
            Task { @MainActor in
                self.requestPrayerDataUpdate()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        self.extractAndProcessContext(userInfo)
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
            // Don't request data on every reachability change - session activation handles initial load
        }
    }
}



