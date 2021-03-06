//
//  AppDelegate.swift
//  CalTrack
//
//  Created by Andrew Bihl on 5/27/17.
//  Copyright © 2017 Andrew Bihl. All rights reserved.
//

import UIKit
import GoogleMaps
import RealmSwift
import Firebase
import Fabric
import Crashlytics
import UserNotifications
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    func copyRealmData() {
        if let bUrl = bundleURL("caltrainTimes") {
            let defaultRealmPath = Realm.Configuration.defaultConfiguration.fileURL!
            
                if !FileManager.default.fileExists(atPath: defaultRealmPath.path) {
                    print("First initialization")
                do {
                    try FileManager.default.copyItem(at: bUrl, to: defaultRealmPath)
                } catch let error {
                    print("error copying seeds: \(error)")
                }
            }

        }
     
    }
    
    func checkRealmData() {
        let realm = try! Realm()
        let stopTimes = realm.objects(stop_times.self)//.filter(<#T##predicate: NSPredicate##NSPredicate#>)
        print(stopTimes.count)
    }
    
    func buildRelationships() {
        
        let realm = try! Realm()
        
        let allObj = realm.objects(stop_times.self)
        for obj in allObj {
            if obj.realTime == nil {
                //print("obj without written relationship", obj)
                if let real = realm.object(ofType: realtime_trips.self, forPrimaryKey: obj.trip_id) {
                //print("related real", real)
                try! realm.write {
                    obj.realTime = real
                }
                }
            } else {
                print("Not first initialization")
                break
            }
        }
    }
    
    func bundleURL(_ name: String) -> URL? {
        return Bundle.main.url(forResource: name, withExtension: "realm")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("failed to register with error", error.localizedDescription)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey(GMS_APIKEY)
        GADMobileAds.configure(withApplicationID: "ca-app-pub-3104334766866306~1150489874")
        FirebaseApp.configure()
        Fabric.with([Crashlytics.self])
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            
            UNUserNotificationCenter.current().delegate = self
            print("request authorization")
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        
        self.copyRealmData()
        
        let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 10 {
                migration.enumerateObjects(ofType: stop_times.className(), { (oldObject, newObject) in
                    let depTime = oldObject!["departure_time"] as! String
                    let arrTime = oldObject!["arrival_time"] as! String
                    
                    let depArr = depTime.components(separatedBy: ":")
                    let firstDep = Int(depArr.first!)!
                    let secondDep = Int(depArr[1])!
                    
                    newObject!["departureTime"] = firstDep * 60 + secondDep
                    
                    let arrArr = arrTime.components(separatedBy: ":")
                    let firstArr = Int(arrArr.first!)!
                    let secondArr = Int(arrArr[1])!
                    
                    newObject!["arrivalTime"] = firstArr * 60 + secondArr
                    
                })
                /*
                migration.enumerateObjects(ofType: stop_times.className(), { (oldStop, newStop) in
                    let stopID = oldStop!["trip_id"] as! String
                    migration.enumerateObjects(ofType: realtime_trips.className(), { (oldReal, newReal) in
                        let realID = oldReal!["trip_id"] as! String
                        if stopID == realID {
                            newStop!["realTime"] = oldReal
                        }
                    })
                }) */
                
                
            }
            
            
        }
        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 11,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: migrationBlock
        )
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        let realm = try! Realm()
        
        self.checkRealmData()
        self.buildRelationships()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        /*
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        } */
        
        // Print full message.
        print("did receive remote notification", userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        /*
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        } */
        
        // Print full message.
        print("did receive remote notification", userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }


}

