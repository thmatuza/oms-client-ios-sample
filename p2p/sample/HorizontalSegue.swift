//
//  HorizontalSegue.swift
//  OMSChat
//
//  Created by Tomohiro Matsuzawa on 2019/01/22.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import UIKit

class HorizontalSegue: UIStoryboardSegue {
    var isDismiss = false
    var isLandscapeOrientation = false

    override func perform() {
        let desViewController: UIViewController = destination

        let srcView: UIView? = source.view
        let desView: UIView? = desViewController.view

        if let transform = srcView?.transform {
            desView?.transform = transform
        }
        desView?.bounds = srcView?.bounds ?? CGRect.zero

        if isLandscapeOrientation {
            if isDismiss {
                desView?.center =
                    CGPoint(x: srcView?.center.x ?? 0.0, y: (srcView?.center.y ?? 0.0) -
                        (srcView?.frame.size.height ?? 0.0))
            } else {
                desView?.center =
                    CGPoint(x: srcView?.center.x ?? 0.0, y: (srcView?.center.y ?? 0.0) +
                        (srcView?.frame.size.height ?? 0.0))
            }
        } else {
            if isDismiss {
                desView?.center =
                    CGPoint(x: (srcView?.center.x ?? 0.0) -
                        (srcView?.frame.size.width ?? 0.0), y: srcView?.center.y ?? 0.0)
            } else {
                desView?.center =
                    CGPoint(x: (srcView?.center.x ?? 0.0) +
                        (srcView?.frame.size.width ?? 0.0), y: srcView?.center.y ?? 0.0)
            }
        }

        let mainWindow: UIWindow = UIApplication.shared.windows[0]
        if let desView = desView {
            mainWindow.addSubview(desView)
        }

        // slide newView over oldView, then remove oldView
        UIView.animate(withDuration: 0.5, animations: {
            desView?.center = CGPoint(x: srcView?.center.x ?? 0.0, y: srcView?.center.y ?? 0.0)

            if self.isLandscapeOrientation {
                if self.isDismiss {
                    srcView?.center =
                        CGPoint(x: srcView?.center.x ?? 0.0, y: (srcView?.center.y ?? 0.0) +
                            (srcView?.frame.size.height ?? 0.0))
                } else {
                    srcView?.center =
                        CGPoint(x: srcView?.center.x ?? 0.0, y: (srcView?.center.y ?? 0.0) -
                            (srcView?.frame.size.height ?? 0.0))
                }
            } else {
                if self.isDismiss {
                    srcView?.center = CGPoint(x: (srcView?.center.x ?? 0.0) +
                        (srcView?.frame.size.width ?? 0.0), y: srcView?.center.y ?? 0.0)
                } else {
                    srcView?.center = CGPoint(x: (srcView?.center.x ?? 0.0) -
                        (srcView?.frame.size.width ?? 0.0), y: srcView?.center.y ?? 0.0)
                }
            }
        }, completion: { finished in
            if finished {
                srcView?.removeFromSuperview()
                mainWindow.rootViewController = desViewController
            }
        })
    }
}
