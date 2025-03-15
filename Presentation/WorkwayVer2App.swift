//
//  workwayVer2App.swift
//  workwayVer2
//
//  Created by 김성욱 on 7/3/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import ComposableArchitecture

class AppDelegate: NSObject, UIApplicationDelegate {
    
    static var orientationLock = UIInterfaceOrientationMask.portrait {
        didSet {
            if #available(iOS 16, *) {
                UIApplication.shared.connectedScenes.forEach { scene in
                    if let windowScene = scene as? UIWindowScene {
                        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientationLock))
                    }
                }
                UIWindow.current?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            } else {
                if orientationLock == .landscape {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        //        #if DEBUG
        //            print("Debug Build")
        //        #else
        //            if Auth.auth().currentUser != nil {
        //                do {
        //                    try Auth.auth().signOut()
        //                } catch {
        //                    print("AppDelegate: error signout")
        //                }
        //            }
        //        #endif
        return true
    }
}

@main
struct workwayVer2App: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            TabNavigationView(store: Store(initialState: TabNavigation.State(), reducer: {
                TabNavigation()
            }))
//            NavigationStack{
//                LogDetailTabView(store: Store(initialState: LogDetailTab.State(
//                    who: "123123",
//                    dashboards: testDashboards,
//                    selectedDashboard: testDashboard2,
//                    stParams: testSTParams,
//                    ftParam: testFTParam,
//                    etParams: testETParams,
//                    btParam: testBTParam
//                ), reducer: {
//                    LogDetailTab()
//                }))
//            }
//            NavigationStack {
//                BtReportView(store: Store(initialState: BtReport.State(setIndex: 0, reports: [testReportBT], reportsNotToday: [], selectedReportName: "측정 1", isFromLog: true), reducer: {
//                    BtReport()
//                }))
//                LogDetailTabView(store: Store(initialState: LogDetailTab.State(
//                    who: "123123",
//                    dashboards: testDashboards,
//                    selectedDashboard: testDashboard2,
//                    stParams: testSTParams,
//                    ftParam: testFTParam,
//                    etParams: testETParams,
//                    btParam: testBTParam
//                ), reducer: {
//                    LogDetailTab()
//                }))
//            }
        }
    }
}
