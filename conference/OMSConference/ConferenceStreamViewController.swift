//
//  ConferenceStreamViewController.swift
//  OMSConference
//
//  Created by Tomohiro Matsuzawa on 2019/01/16.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import Alamofire
import AVFoundation
import UIKit

class ConferenceStreamViewController: UIViewController, UIGestureRecognizerDelegate,
OMSConferencePublicationDelegate, OMSConferenceSubscriptionDelegate, StreamViewDelegate, OMSRemoteMixedStreamDelegate {
    weak var appDelegate: AppDelegate?

    private var getStatsTimer: Timer?
    private var source: RTCVideoSource?
    private var capturer: RTCCameraVideoCapturer?
    private var subscribedMix = false
    private var filter: BrightenFilter?
    private var url = ""

    @IBOutlet var streamView: StreamView!
    var localStream: OMSLocalStream?
    var localStream2: OMSLocalStream?

    func doPublish() {
        if localStream == nil {
            #if TARGET_IPHONE_SIMULATOR
            print("Camera is not supported on simulator")
            let constraints = OMSStreamConstraints()
            constraints.audio = true
            constraints.video = nil
            #else
            // Create LocalStream with constraints
            let constraints = OMSStreamConstraints()
            constraints.audio = true
            let video = OMSVideoTrackConstraints()
            video.frameRate = 24
            video.resolution = CGSize(width: 640, height: 480)
            video.devicePosition = AVCaptureDevice.Position.front
            constraints.video = video
            #endif
            var err: NSError?
            localStream = OMSLocalStream(constratins: constraints, error: &err)
            #if TARGET_IPHONE_SIMULATOR
            print("Stream does not have video track.")
            #else
            DispatchQueue.main.async(execute: {
                ((self.view as? StreamView)?.localVideoView)?.captureSession = self.capturer?.captureSession
            })
            #endif
            let options = OMSPublishOptions()
            let opusParameters = OMSAudioCodecParameters()
            opusParameters.name = .opus
            let audioParameters = OMSAudioEncodingParameters()
            audioParameters.codec = opusParameters
            options.audio = [audioParameters]
            let h264Parameters = OMSVideoCodecParameters()
            h264Parameters.name = .H264
            let videoParameters = OMSVideoEncodingParameters()
            videoParameters.codec = h264Parameters
            options.video = [videoParameters]
            guard let localStream = localStream else {
                return
            }
            conferenceClient?.publish(localStream, with: nil, onSuccess: { p in
                self.publication = p
                self.publication?.delegate = self
                self.mix(toCommonView: p)
                DispatchQueue.main.async(execute: {
                    print("publish success!")
                })
            }, onFailure: { err in
                print("publish failure!")
                self.showMsg((err as NSError?)?.localizedFailureReason)
            })
            screenStream = appDelegate?.screenStream
            remoteStream = appDelegate?.mixedStream
            subscribe()
        }
    }

    func handleSwipeGuesture() {
    }

    func mix(toCommonView publication: OMSConferencePublication?) {
        let params = [
            "op": "add",
            "path": "/info/inViews",
            "value": "common"
        ]
        let paramsArray = [params]
        if let serverUrl = appDelegate?.serverUrl,
            let conferenceId = appDelegate?.conferenceId,
            let publicationId = publication?.publicationId,
            let url = URL(string: "\(serverUrl)rooms/\(conferenceId)/streams/\(publicationId)") {
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: paramsArray)
            } catch {
                print("Error: \(error)")
            }

            AF.request(request)
                .responseJSON { response in
                    // do whatever you want here
                    switch response.result {
                    case .failure(let error):
                        print("Error: \(error)")
                    case .success:
                        break
                    }
            }
        }
    }

    private var remoteStream: OMSRemoteStream?
    private var screenStream: OMSRemoteStream?
    private var conferenceClient: OMSConferenceClient?
    private var publication: OMSConferencePublication?
    private var subscription: OMSConferenceSubscription?

    private func handleLocalPreviewOrientation() {
        let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        switch orientation {
        case .landscapeLeft:
            streamView.localVideoView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        case .landscapeRight:
            streamView.localVideoView.transform = CGAffineTransform(rotationAngle: CGFloat(.pi + Double.pi / 2))
        default:
            print("Unsupported orientation.")
        }
    }

    @objc private func handleSwipeGuesture(_ sender: UIScreenEdgePanGestureRecognizer?) {
        if sender?.state == .ended {
            conferenceClient?.leaveWith(onSuccess: {
                self.quitConference()
            }, onFailure: { err in
                self.quitConference()
                print("Failed to leave. \(err)")
            })
        }
    }

    func showMsg(_ msg: String?) {
        let alertController = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        conferenceClient = appDelegate?.conferenceClient
        NotificationCenter.default.addObserver(
            self, selector: #selector(ConferenceStreamViewController.onStreamAddedNotification(_:)),
            name: NSNotification.Name("OnStreamAdded"), object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(ConferenceStreamViewController.onOrientationChangedNotification(_:)),
            name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        let edgeGestureRecognizer = UIScreenEdgePanGestureRecognizer(
            target: self, action: #selector(ConferenceStreamViewController.handleSwipeGuesture(_:)))
        edgeGestureRecognizer.delegate = self
        edgeGestureRecognizer.edges = .left
        view.addGestureRecognizer(edgeGestureRecognizer)
        DispatchQueue.global(qos: .default).async(execute: {
            self.doPublish()
        })
        if #available(iOS 11.0, *) {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        handleLocalPreviewOrientation()
    }

    override func loadView() {
        super.loadView()
        streamView = StreamView()
        streamView.delegate = self
        view = streamView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func quitConference() {
        DispatchQueue.main.async(execute: {
            self.localStream = nil
            self.getStatsTimer?.invalidate()
            if let capturer = self.capturer {
                capturer.stopCapture()
            }
            self.conferenceClient = nil
            self.performSegue(withIdentifier: "Back", sender: self)
        })
    }

    func quitBtnDidTouchedDown(_ view: StreamView?) {
        conferenceClient?.leaveWith(onSuccess: {
            self.quitConference()
        }, onFailure: { err in
            self.quitConference()
            print("Failed to leave. \(err)")
        })
    }

    func onStreamRemovedNotification(_ notification: Notification?) {
        let userInfo = notification?.userInfo
        let stream = userInfo?["stream"] as? OMSRemoteStream
        if let origin = stream?.origin {
            print("A stream was removed from \(origin)")
        }
        onRemoteStreamRemoved(stream)
    }

    @objc func onStreamAddedNotification(_ notification: Notification?) {
        let userInfo = notification?.userInfo
        let stream = userInfo?["stream"] as? OMSRemoteStream
        if let origin = stream?.origin {
            print("New stream add from \(origin)")
        }
        onRemoteStreamAdded(stream)
    }

    @objc func onOrientationChangedNotification(_ notification: Notification?) {
        handleLocalPreviewOrientation()
    }

    func onRemoteStreamRemoved(_ remoteStream: OMSRemoteStream?) {
        if remoteStream?.source.video == .screenCast {
            screenStream = nil
            subscribe()
        }
    }

    func onRemoteStreamAdded(_ remoteStream: OMSRemoteStream?) {
        if remoteStream?.source.video == .screenCast {
            screenStream = remoteStream
            subscribe()
        }
    }

    // Try to subscribe screen sharing stream is available, otherwise, subscribe
    // mixed stream.
    func subscribe() {
        if let screenStream = screenStream {
            conferenceClient?.subscribe(screenStream, with: nil, onSuccess: { subscription in
                subscription.delegate = self
                DispatchQueue.main.async(execute: {
                    print("Subscribe screen stream success.")
                    //[_screenStream attach:((StreamView*)self.view).remoteVideoView];
                    self.streamView.act.stopAnimating()
                })
            }, onFailure: { err in
                print("Subscribe screen stream failed. Error: \(err.localizedDescription)")
            })
        } else {
            let subOption = OMSConferenceSubscribeOptions()
            subOption.video = OMSConferenceVideoSubscriptionConstraints()
            var width = Int(INT_MAX)
            var height = Int(INT_MAX)
            for value: NSValue? in (appDelegate?.mixedStream?.capabilities.video.resolutions)! {
                let resolution: CGSize? = value?.cgSizeValue
                if resolution?.width == 640 && resolution?.height == 480 {
                    width = Int(resolution?.width ?? 0)
                    height = Int(resolution?.height ?? 0)
                    break
                }
                if (resolution?.width ?? 0.0) < CGFloat(width) && resolution?.height != 0 {
                    width = Int(resolution?.width ?? 0)
                    height = Int(resolution?.height ?? 0)
                }
            }
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            guard let mixedStream = appDelegate?.mixedStream else {
                return
            }
            conferenceClient?.subscribe(mixedStream, with: subOption, onSuccess: { subscription in
                self.subscription = subscription
                self.subscription?.delegate = self
                self.getStatsTimer = Timer(
                    timeInterval: 1.0, target: self,
                    selector: #selector(ConferenceStreamViewController.printStats), userInfo: nil, repeats: true)
                RunLoop.main.add(self.getStatsTimer!, forMode: .default)
                DispatchQueue.main.async(execute: {
                    self.remoteStream = self.appDelegate?.mixedStream
                    print("Subscribe stream success.")
                    self.remoteStream?.attach(((self.view as? StreamView)?.remoteVideoView)!)
                    self.streamView.act.stopAnimating()
                    self.subscribedMix = true
                })
            }, onFailure: { err in
                print("Subscribe stream failed. \(err.localizedDescription)")
            })
        }
    }

    @objc func printStats() {
        subscription?.statsWith(onSuccess: { stats in
            print("\(stats)")
        }, onFailure: { e in
            print("\(e)")
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let s = segue as? HorizontalSegue
        s?.isDismiss = true
    }

    func onVideoLayoutChanged() {
        print("OnVideoLayoutChanged.")
    }

    func subscriptionDidMute(_ subscription: OMSConferenceSubscription, trackKind kind: OMSTrackKind) {
        print("Subscription is muted.")
    }

    func subscriptionDidUnmute(_ subscription: OMSConferenceSubscription, trackKind kind: OMSTrackKind) {
        print("Subscription is unmuted.")
    }

    func subscriptionDidEnd(_ subscription: OMSConferenceSubscription) {
        print("Subscription is ended.")
    }

    func publicationDidMute(_ publication: OMSConferencePublication, trackKind kind: OMSTrackKind) {
        print("Publication is muted.")
    }

    func publicationDidUnmute(_ publication: OMSConferencePublication, trackKind kind: OMSTrackKind) {
        print("Publication is unmuted.")
    }

    func publicationDidEnd(_ publication: OMSConferencePublication) {
        print("Publication is ended.")
    }

    func streamDidEnd(_ stream: OMSRemoteStream) {
        print("stream did end")
    }

    func streamDidUpdate(_ stream: OMSRemoteStream) {
        print("stream did update")
    }

    func streamDidChangeVideoLayout(_ stream: OMSRemoteMixedStream) {
        print("stream did change video layout")
    }
}
