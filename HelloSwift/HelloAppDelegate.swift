//
//  AppDelegate.swift
//  HelloSwift
//
//  Copyright (c) 2015 Rdio. All rights reserved.
//

import UIKit

@UIApplicationMain
class HelloAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var viewController: HelloViewController?

    lazy internal var rdioInstance: Rdio = {
        return Rdio(consumerKey: ConsumerCredentials.ConsumerKey, andSecret: ConsumerCredentials.ConsumerSecret, delegate:nil);
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        viewController = HelloViewController()
        
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }
}

