//
//  StreamView.swift
//  OMSChat
//
//  Created by Tomohiro Matsuzawa on 2019/01/22.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import Foundation

let MAX_CONNECTERS = 4

protocol StreamViewDelegate: NSObjectProtocol {
    /// Called when publish button is touched
    func publishBtnDidTouchedDown(_ view: StreamView?)
    func stopBtnDidTouchedDown(_ view: StreamView?)
    func localStreamBtnDidTouchedDown(_ view: StreamView?)
}

class StreamView: UIView, RTCEAGLVideoViewDelegate {
    // Auto-adjust to the screen size
    var screenSize = CGRect.zero

    private(set) var localVideoView: RTCEAGLVideoView
    private(set) var remoteVideoView: RTCEAGLVideoView
    private(set) var publishBtn: UIButton
    private(set) var stopBtn: UIButton
    private(set) var localStreamBtn: UIButton
    weak var delegate: StreamViewDelegate?

    override init(frame: CGRect) {

        remoteVideoView = RTCEAGLVideoView(frame: CGRect.zero)
        localVideoView = RTCEAGLVideoView(frame: CGRect.zero)
        publishBtn = UIButton(type: .custom)
        stopBtn = UIButton(type: .custom)
        localStreamBtn = UIButton()
        super.init(frame: frame)
        remoteVideoView.delegate = self
        backgroundColor = UIColor.black
        publishBtn.addTarget(self, action: #selector(StreamView.onAcceptBtnDown(_:)), for: .touchDown)
        stopBtn.addTarget(self, action: #selector(StreamView.onDenyBtnDown(_:)), for: .touchDown)
        localStreamBtn.addTarget(self, action: #selector(StreamView.onLocalStreamBtnDown(_:)), for: .touchDown)

        addSubview(remoteVideoView)
        addSubview(localVideoView)
        addSubview(publishBtn)
        addSubview(stopBtn)
    }

    override func layoutSubviews() {

        screenSize = UIScreen.main.bounds

        // localVideo
        let localVideoViewFrame = CGRect(
            x: screenSize.size.width / 12.0,
            y: screenSize.size.height * 2.0 / 3.0,
            width: screenSize.size.width / 3.0,
            height: screenSize.size.height / 4.0)
        localVideoView.frame = localVideoViewFrame

        localVideoView.layer.borderColor = UIColor.yellow.cgColor
        localVideoView.layer.borderWidth = 0.0

        // remoteVideo
        let remoteVideoViewFrame = CGRect(
            x: 0,
            y: 0,
            width: screenSize.size.width,
            height: screenSize.size.height)
        remoteVideoView.frame = remoteVideoViewFrame
        remoteVideoView.layer.borderColor = UIColor.black.cgColor
        remoteVideoView.layer.borderWidth = 2.0

        // acceptBtn
        publishBtn.setTitle("📹", for: .normal)
        publishBtn.setTitleColor(UIColor.white, for: .normal)
        publishBtn.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        let acceptBtnFrame = CGRect(
            x: screenSize.size.width / 2.0,
            y: screenSize.size.height * 11.0 / 12.0 - screenSize.size.width / 5,
            width: screenSize.size.width / 5,
            height: screenSize.size.width / 5)
        publishBtn.frame = acceptBtnFrame
        publishBtn.layer.cornerRadius = screenSize.size.width / 10
        publishBtn.backgroundColor = UIColor.green

        // denyBtn
        stopBtn.setTitle("❌", for: .normal)
        stopBtn.setTitleColor(UIColor.white, for: .normal)
        stopBtn.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        let denyBtnFrame = CGRect(
            x: screenSize.size.width * 11.0 / 12.0 - screenSize.size.width / 5,
            y: screenSize.size.height * 11.0 / 12.0 - screenSize.size.width / 5,
            width: screenSize.size.width / 5,
            height: screenSize.size.width / 5)
        stopBtn.frame = denyBtnFrame
        stopBtn.layer.cornerRadius = screenSize.size.width / 10
        stopBtn.backgroundColor = UIColor.red

        // localStreamBtn
        localStreamBtn.setTitle("lStream", for: .normal)
        localStreamBtn.setTitleColor(UIColor.blue, for: .normal)
        let localStreamBtnFrame = CGRect(
            x: 0,
            y: screenSize.size.height / 2.0,
            width: 100,
            height: screenSize.size.height / 8.0)
        localStreamBtn.frame = localStreamBtnFrame

    }

    @objc func onAcceptBtnDown(_ sender: Any?) {
        delegate?.publishBtnDidTouchedDown(self)
    }

    @objc func onDenyBtnDown(_ sender: Any?) {
        delegate?.stopBtnDidTouchedDown(self)
    }

    @objc func onLocalStreamBtnDown(_ sender: Any?) {
        delegate?.localStreamBtnDidTouchedDown(self)
    }

    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        if videoView !== remoteVideoView {
            return
        }
        if size.width > 0 && size.height > 0 {
            let remoteVideoFrame: CGRect = AVMakeRect(aspectRatio: size, insideRect: bounds)
            remoteVideoView.frame = remoteVideoFrame
            remoteVideoView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
