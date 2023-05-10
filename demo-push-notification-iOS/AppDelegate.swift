//
//  AppDelegate.swift
//  demo-push-notification-iOS
//
//  Created by REVE Systems on 9/5/23.
//

import UIKit
import Ably
import UserNotifications

let apiKey = "xBiDVQ.vqq0nw:LKeWsHcuwAqjGHIorBjH11ZPFd4br4ZTZ4I8Mb5VA10"
let myClientId = "45432314654654"
let ablyClientOptions = ARTClientOptions()
let myPushChannel = "push"

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //MARK: 1) important functions
    var window: UIWindow?
    var realtime: ARTRealtime! = nil
    var channel: ARTRealtimeChannel!
    var myDeviceToken = ""
    var myDeviceId = ""
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.customizeNotificationOnLaunch()
        self.realtime = self.getAblyRealtime()
        self.realtime.push.activate()
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

//MARK: 2) Functions to push notifications if app is closed or killed from background
extension AppDelegate {
    func customizeNotificationOnLaunch() {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        print("[LOCALLOG] App launched on the device")
        
        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, err) in
            DispatchQueue.main.async() {
                UIApplication.shared.registerForRemoteNotifications() 
                print("[LOCALLOG] Request to show notifications successful")
            }
        }
    }
    
    // didRegisterForRemoteNotificationsWithDeviceToken called after calling registerForRemoteNotifications functions.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("[LOCALLOG] Registration for remote notifications successful")
        self.myDeviceToken = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken, realtime: self.getAblyRealtime())
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[LOCALLOG] Error registering for remote notifications")
        ARTPush.didFailToRegisterForRemoteNotificationsWithError(error, realtime: self.getAblyRealtime())
    }
}

//MARK: 3) Functions to handle notification if app is in foreground or background
extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Tell the app that we have finished processing the user's action (eg: tap on notification banner) / response
        // Handle received remoteNotification: 'response.notification.request.content.userInfo'
        // response.notification.request.content.userInfo
        print("tapped on notification ",response.notification.request.content.userInfo)
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("[LOCALLOG] Your device just received a notification!")
        // Show the notification alert in foreground
        completionHandler([.alert, .sound])
    }
}

//MARK: 4) ARTPushRegistererDelegate functions
extension AppDelegate: ARTPushRegistererDelegate {
    func didActivateAblyPush(_ error: ARTErrorInfo?) {
        if let error = error {
            // Handle error
            print("[LOCALLOG] Push activation failed, err=\(String(describing: error))")
            return
        }
        print("[LOCALLOG] Push activation successful")
        
        self.channel = self.realtime.channels.get(myPushChannel)
        self.channel.push.subscribeDevice { (err) in
            if(err != nil){
                print("[LOCALLOG] Device Subscription on push channel failed with err=\(String(describing: err))")
                return
            }
            self.myDeviceId = self.realtime.device.id
            print("[LOCALLOG] Client ID: " + myClientId)
            print("[LOCALLOG] Device Token: " + self.myDeviceToken)
            print("[LOCALLOG] Device ID: " + self.myDeviceId)
            print("[LOCALLOG] Push channel: " + myPushChannel)
        }
    }
    
    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        print("[LOCALLOG] push deactivated")
    }
}

//MARK: 5) Other functions
extension AppDelegate {
    private func getAblyRealtime() -> ARTRealtime {
        if(realtime == nil){
            ablyClientOptions.clientId = myClientId
            ablyClientOptions.key = apiKey
            realtime = ARTRealtime(options: ablyClientOptions)
        }
        return realtime
    }
}
