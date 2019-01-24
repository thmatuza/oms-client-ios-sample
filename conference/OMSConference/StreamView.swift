//
//  StreamView.swift
//  OMSConference
//
//  Created by Tomohiro Matsuzawa on 2019/01/16.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import Foundation

let MAX_CONNECTERS = 4
protocol StreamViewDelegate: NSObjectProtocol {
    /// Called when publish button is touched
    func quitBtnDidTouchedDown(_ view: StreamView?)
}

class StreamView: UIView {
    // Auto-adjust to the screen size
    var screenSize = CGRect.zero

    private var statsLabel: UILabel
    private var isStatsLabelVisiable = false

    private(set) var localVideoView: RTCCameraPreviewView
    private(set) var remoteVideoView: (UIView & RTCVideoRenderer)
    var act: UIActivityIndicatorView

    private var _stats = ""
    var stats: String {
        get {
            return _stats
        }
        set(stats) {
            if stats.isEmpty && isStatsLabelVisiable {
                statsLabel.removeFromSuperview()
            } else if !stats.isEmpty && !isStatsLabelVisiable {
                addSubview(statsLabel)
            }
            statsLabel.text = stats
        }
    }
    weak var delegate: StreamViewDelegate?

    override init(frame: CGRect) {
        #if RTC_SUPPORTS_METAL
        remoteVideoView = RTCEAGLVideoView()
        //    _remoteVideoView = [[RTCMTLVideoView alloc]initWithFrame:CGRectZero];
        #else
        remoteVideoView = RTCEAGLVideoView()
        #endif
        localVideoView = RTCCameraPreviewView()
        act = UIActivityIndicatorView()
        act.startAnimating()
        statsLabel = UILabel()
        isStatsLabelVisiable = false

        super.init(frame: frame)
        backgroundColor = UIColor.white

        addSubview(remoteVideoView)
        addSubview(localVideoView)
        addSubview(act)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        screenSize = UIScreen.main.bounds
        var `right`: CGFloat = 0
        var bottom: CGFloat = 0
        if #available(iOS 11.0, *) {
            `right` = safeAreaInsets.`right`
            bottom = safeAreaInsets.bottom
        }

        // local view
        localVideoView.translatesAutoresizingMaskIntoConstraints = false

        addConstraint(NSLayoutConstraint(
            item: localVideoView, attribute: .right, relatedBy: .equal,
            toItem: self, attribute: .right, multiplier: 1.0, constant: -`right`))
        addConstraint(NSLayoutConstraint(
            item: localVideoView, attribute: .bottom, relatedBy: .equal,
            toItem: self, attribute: .bottom, multiplier: 1.0, constant: -bottom))
        addConstraint(NSLayoutConstraint(
            item: localVideoView, attribute: .width, relatedBy: .greaterThanOrEqual,
            toItem: self, attribute: .width, multiplier: 0.25, constant: 0))
        addConstraint(NSLayoutConstraint(
            item: localVideoView, attribute: .height, relatedBy: .greaterThanOrEqual,
            toItem: self, attribute: .height, multiplier: 0.25, constant: 0))

        // remote view
        let remoteVideoViewFrame = CGRect(x: 0, y: 0, width: screenSize.size.width, height: screenSize.size.height)
        remoteVideoView.frame = remoteVideoViewFrame

        remoteVideoView.contentMode = UIView.ContentMode.scaleAspectFill // <— Doesn’t seem to work?

        // indicater
        let actSize = Float(screenSize.size.width / 10.0)
        act.frame = CGRect(
            x: screenSize.size.width / 2.0 - CGFloat(actSize),
            y: screenSize.size.height / 2.0 - CGFloat(actSize),
            width: CGFloat(2 * actSize), height: CGFloat(2 * actSize))
        act.style = .whiteLarge
        //  self.act.color = [UIColor redColor];
        act.hidesWhenStopped = true

        // Stats label
        let statsLabelFrame = CGRect(x: screenSize.size.width - 140, y: 0, width: 140, height: 100)
        statsLabel.frame = statsLabelFrame
        statsLabel.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        statsLabel.textColor = UIColor.black
        statsLabel.font = statsLabel.font.withSize(12)
        statsLabel.lineBreakMode = .byWordWrapping
        statsLabel.numberOfLines = 0

        for view: UIView in subviews {
            view.transform = transform
        }
    }
}
