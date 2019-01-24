//
//  AppDelegate.swift
//  OMSChat
//
//  Created by Tomohiro Matsuzawa on 2019/01/21.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OMSP2PClientDelegate {
    var window: UIWindow?

    private var _peerClient: OMSP2PClient?
    var peerClient: OMSP2PClient? {
        if _peerClient == nil {
            let scc = SocketSignalingChannel()
            let config = OMSP2PClientConfiguration()
            let opusParameters = OMSAudioCodecParameters()
            opusParameters.name = .opus
            let audioParameters = OMSAudioEncodingParameters()
            audioParameters.codec = opusParameters
            config.audio = [audioParameters]
            let h264Parameters = OMSVideoCodecParameters()
            h264Parameters.name = .H264
            let videoParameters = OMSVideoEncodingParameters()
            videoParameters.codec = h264Parameters
            config.video = [videoParameters]
            config.rtcConfiguration = RTCConfiguration()
            config.rtcConfiguration.iceServers = [RTCIceServer(urlStrings: ["stun:example.com"])]
            _peerClient = OMSP2PClient(configuration: config, signalingChannel: scc)
            _peerClient?.delegate = self
        }
        return _peerClient
    }
    var remoteUserId = ""
    var connecters: [[String: Any]] = []
    var infos: [[String: Any]] = []

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        infos = [[String: Any]]()
        connecters = [[String: Any]]()
        if let image = UIImage(named: "login.jpg") {
            window?.backgroundColor = UIColor(patternImage: image)
        }
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for
        // certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the
        // user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates.
        // Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough
        // application state information to restore your application to its current state in case it is terminated
        // later.
        // If your application supports background execution, this method is called instead of
        // applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo
        // many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If
        // the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also
        // applicationDidEnterBackground:.

    }

    func p2pClient(_ client: OMSP2PClient, didAdd stream: OMSRemoteStream) {
        print("AppDelegate on stream added")
        infos.append(["stream": stream])
        NotificationCenter.default.post(name: NSNotification.Name("OnStreamAdded"),
                                        object: self, userInfo: ["stream": stream])
    }

    func p2pClient(_ client: OMSP2PClient, didReceiveMessage message: String, from senderId: String) {
        print("Recieved data from \(senderId), message: \(message)")
    }

    func p2pClientDidDisconnect(_ client: OMSP2PClient) {
        print("AppDelegate on server disconnected.")
    }
}
