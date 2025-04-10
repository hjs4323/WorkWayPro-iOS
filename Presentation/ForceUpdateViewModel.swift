//
//  FbConfig.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 9/24/24.
//

import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import FirebaseRemoteConfig
import FirebaseRemoteConfigInternal

class ForceUpdateViewModel: ObservableObject {
    @Published var isUpdateNeeded: UpdateCases = .notInitialized
    let remoteConfig = RemoteConfig.remoteConfig()
    var settings = RemoteConfigSettings()
    
    init() {
        setupRemoteConfigListener()
        Task {
            await activateRemoteConfig()
        }
    }
    
    func setupRemoteConfigListener() {
        self.settings.minimumFetchInterval = 60 * 20 //20분에 1번
        self.remoteConfig.configSettings = settings
        remoteConfig.addOnConfigUpdateListener { configUpdate, error in
            if let error {
                print("FbConfig/setupRemoteConfigListener: error \(error)")
                return
            }
            Task {
                await self.activateRemoteConfig()
            }
        }
    }
    
    private func activateRemoteConfig() async {
        do {
            try await remoteConfig.fetch()
            try await remoteConfig.activate()
            
            DispatchQueue.main.async {
                let recommendVer = self.remoteConfig["recommend_version"].stringValue.components(separatedBy: ".").map({ Int($0) ?? 0 })
                let forcedVer = self.remoteConfig["force_version"].stringValue.components(separatedBy: ".").map({ Int($0) ?? 0 })
                
                guard
                    let currentVersionNumber = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)?.components(separatedBy: ".").map({ Int($0) ?? 0 })
                else { return }
                print("recommendVer = \(recommendVer)")
                print("forcedVer = \(forcedVer)")
                print("currentVersionNumber = \(currentVersionNumber)")
                
                let currentMainVer = currentVersionNumber[0]
                let currentMinorVer = currentVersionNumber[1]
                let currentPatchVer = currentVersionNumber[2]
                
                let forcedMainVer = forcedVer[0]
                let forcedMinorVer = forcedVer[1]
                let forcedPatchVer = forcedVer[2]
                
                let recommendMainVer = recommendVer[0]
                let recommendMinorVer = recommendVer[1]
                let recommendPatchVer = recommendVer[2]
                
                if currentMainVer < forcedMainVer {
                    self.isUpdateNeeded = .isForced
                } else if currentMinorVer < forcedMinorVer {
                    self.isUpdateNeeded = .isForced
                } else if currentPatchVer < forcedPatchVer {
                    self.isUpdateNeeded = .isForced
                } else if currentMainVer < recommendMainVer {
                    self.isUpdateNeeded = .isRecommended
                } else if currentMinorVer < recommendMinorVer {
                    self.isUpdateNeeded = .isRecommended
                } else if currentPatchVer < recommendPatchVer {
                    self.isUpdateNeeded = .isRecommended
                } else {
                    self.isUpdateNeeded = .noUpdate
                }
            }
        } catch {
            print("FbConfig/isUpdateNeeded: \(error)")
            return
        }
    }
    
    enum UpdateCases {
        case noUpdate
        case isRecommended
        case isForced
        case notInitialized
    }
}
