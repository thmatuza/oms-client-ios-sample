//
//  StreamViewController.swift
//  OMSChat
//
//  Created by Tomohiro Matsuzawa on 2019/01/22.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import AVFoundation
import UIKit

class StreamViewController: UIViewController, OMSP2PPublicationDelegate, StreamViewDelegate {
    weak var appDelegate: AppDelegate?

    private var source: RTCVideoSource?
    private var isChatting = false
    private var publication: OMSP2PPublication?

    @IBOutlet var streamView: StreamView!
    private(set) var status: UILabel?
    var isCaller = false
    private var localStream: OMSLocalStream!
    private var peerClient: OMSP2PClient?
    private var getStatsTimer: Timer?

    func showMsg(_ msg: String) {
        let alert = UIAlertView(
            title: "", message: msg, delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles: "")
        alert.show()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self, selector: #selector(on(_:)), name: Notification.Name("OnStreamAdded"), object: nil)

        if let appDelegate = appDelegate {
            while !appDelegate.infos.isEmpty {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OnStreamAdded"), object: appDelegate,
                    userInfo: appDelegate.infos[appDelegate.infos.count - 1])
                appDelegate.infos.removeLast()
            }
        }

        print("Stream view did load.")
        peerClient = appDelegate?.peerClient
        isChatting = false

        #if TARGET_IPHONE_SIMULATOR
        print("Camera is not supported on simulator.")
        let constraints = OMSStreamConstraints()
        constraints.audio = true
        constraints.video = nil
        localStream = OMSLocalStream(constratins: constraints, error: nil)
        #else
        attachLocal()
        #endif

        let nc = NotificationCenter.default
        nc.addObserver(
            self, selector: #selector(StreamViewController.routeChange(_:)),
            name: AVAudioSession.routeChangeNotification, object: nil)

        //[self publish];
    }

    @objc func routeChange(_ notification: Notification) {
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
    }

    override func viewDidDisappear(_ animated: Bool) {
        print("disappearing")
        super.viewDidDisappear(animated)
        localStream = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        status?.textAlignment = .center
        status?.textColor = UIColor.white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func loadView() {
        super.loadView()

        appDelegate = UIApplication.shared.delegate as? AppDelegate
        streamView = StreamView()
        streamView.delegate = self
        status = UILabel()
        status?.frame = CGRect(
            x: 0, y: UIScreen.main.bounds.size.height / 30.0,
            width: UIScreen.main.bounds.size.width,
            height: UIScreen.main.bounds.size.height / 30.0)
        if let status = status {
            streamView.addSubview(status)
        }
        view = streamView
    }

    func publishBtnDidTouchedDown(_ view: StreamView?) {
        publish()
    }

    func stopBtnDidTouchedDown(_ view: StreamView?) {
        publication?.stop()
    }

    func publish() {
        DispatchQueue.main.async(execute: {
            guard let appDelegate = self.appDelegate else {
                return
            }
            self.peerClient?.publish(self.localStream, to: appDelegate.remoteUserId, onSuccess: { publication in
                self.publication = publication
                self.getStatsTimer?.invalidate()
                let getStatsTimer = Timer(timeInterval: 5.0,
                                          target: self, selector: #selector(StreamViewController.printStats),
                                          userInfo: nil, repeats: true)
                self.getStatsTimer = getStatsTimer
                RunLoop.main.add(getStatsTimer, forMode: .default)
            }, onFailure: { err in
                print("\((err as NSError?)?.localizedFailureReason ?? "")")
            })
            self.status?.text = "Chatting..."
        })
    }

    @objc func printStats() {
    }

    func attachLocal() {
        if localStream == nil {
            let constraints = OMSStreamConstraints()
            constraints.audio = true
            constraints.video = OMSVideoTrackConstraints()
            constraints.video?.frameRate = 24
            constraints.video?.resolution = CGSize(width: 640, height: 480)
            constraints.video?.devicePosition = AVCaptureDevice.Position.front
            DispatchQueue.main.async(execute: {
                self.localStream = OMSLocalStream(constratins: constraints, error: nil)
                self.localStream?.attach(self.streamView.localVideoView)
            })
        }
    }

    @objc func on(_ notification: Notification) {
        print(notification.name)
        if notification.name.rawValue == "OnStreamAdded" {
            let userInfo = notification.userInfo
            if let stream = userInfo?["stream"] as? OMSRemoteStream {
                onRemoteStreamAdded(stream)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let s = segue as? HorizontalSegue
        s?.isDismiss = true
        s?.isLandscapeOrientation = false
    }

    func onRemoteStreamAdded(_ remoteStream: OMSRemoteStream) {
        if remoteStream.source.video == .screenCast {
            print("Screen stream added.")
        } else if remoteStream.source.video == .camera {
            print("Camera stream added.")
        }
        remoteStream.attach(streamView.remoteVideoView)
    }

    func onRemoteStreamRemoved(_ remoteStream: OMSRemoteStream) {
    }

    func publicationDidEnd(_ publication: OMSP2PPublication) {
        print("Publication did end.")
    }

    func localStreamBtnDidTouchedDown(_ view: StreamView?) {

    }
}
