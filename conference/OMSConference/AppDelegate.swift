//
//  AppDelegate.swift
//  OMSConference
//
//  Created by Tomohiro Matsuzawa on 2019/01/16.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,
OMSConferenceClientDelegate, OMSRemoteMixedStreamDelegate, OMSRemoteStreamDelegate {
    var window: UIWindow?

    private var _conferenceClient: OMSConferenceClient?
    var conferenceClient: OMSConferenceClient? {
        if _conferenceClient == nil {
            //NSString* path=[[NSBundle mainBundle]pathForResource:@"audio_long16" ofType:@"pcm"];
            //FileAudioFrameGenerator* generator=[[FileAudioFrameGenerator alloc]initWithPath:path
            // sampleRate:16000 channelNumber:1];
            //[RTCGlobalConfiguration setCustomizedAudioInputEnabled:YES audioFrameGenerator:generator];
            let config = OMSConferenceClientConfiguration()
            let ice = [
                RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["turn:ec2-13-115-187-121.ap-northeast-1.compute.amazonaws.com:3478"],
                             username: "intelcs", credential: "intelcspw")]
            config.rtcConfiguration = RTCConfiguration()
            config.rtcConfiguration.iceServers = ice
            _conferenceClient = OMSConferenceClient(configuration: config)
            _conferenceClient?.delegate = self
        }
        return _conferenceClient
    }
    var mixedStream: OMSRemoteMixedStream?
    var screenStream: OMSRemoteStream?
    var conferenceId = ""
    var serverUrl = ""

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        mixedStream = OMSRemoteMixedStream()
        if let image = UIImage(named: "bg.jpg") {
            window?.backgroundColor = UIColor(patternImage: image)
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain
        // types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits
        // the application
        // and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games
        // should use this method to pause the game.
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

    func onVideoLayoutChanged() {
        print("OnVideoLayoutChanged.")
    }

    func conferenceClient(_ client: OMSConferenceClient, didAdd stream: OMSRemoteStream) {
        print("AppDelegate on stream added")
        stream.delegate = self
        if stream is OMSRemoteMixedStream {
            mixedStream = stream as? OMSRemoteMixedStream
            mixedStream?.delegate = self
        }
        if stream.source.video == .screenCast {
            screenStream = stream
        }
        NotificationCenter.default.post(
            name: NSNotification.Name("OnStreamAdded"),
            object: self, userInfo: ["stream": stream])
    }

    func conferenceClientDidDisconnect(_ client: OMSConferenceClient) {
        print("Server disconnected")
        mixedStream = nil
    }

    func conferenceClient(_ client: OMSConferenceClient?, didReceiveMessage message: String?, from senderId: String?) {
        print("AppDelegate received message: \(message ?? ""), from \(senderId ?? "")")
    }

    func streamDidEnd(_ stream: OMSRemoteStream) {
        print("Stream did end")
    }

    func streamDidChangeVideoLayout(_ stream: OMSRemoteMixedStream) {
        print("Stream did change video layout")
    }

    func streamDidUpdate(_ stream: OMSRemoteStream) {
        print("stream did update")
    }

}
