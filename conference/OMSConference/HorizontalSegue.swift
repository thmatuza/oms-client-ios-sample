//
//  HorizontalSegue.swift
//  OMSConference
//
//  Created by Tomohiro Matsuzawa on 2019/01/16.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import UIKit

class HorizontalSegue: UIStoryboardSegue {
    var isDismiss = false

    override func perform() {
        let desViewController: UIViewController = destination

        let srcView: UIView = source.view
        let desView: UIView = desViewController.view

        let transform = srcView.transform
        desView.transform = transform
        desView.bounds = srcView.bounds

        if isDismiss {
            desView.center = CGPoint(x: srcView.center.x - srcView.frame.size.width, y: srcView.center.y)
        } else {
            desView.center = CGPoint(x: srcView.center.x + srcView.frame.size.width, y: srcView.center.y)
        }

        let mainWindow: UIWindow = UIApplication.shared.windows[0]
        mainWindow.addSubview(desView)

        // slide newView over oldView, then remove oldView
        UIView.animate(withDuration: 0.5, animations: {
            desView.center = CGPoint(x: srcView.center.x, y: srcView.center.y)

            if self.isDismiss {
                srcView.center = CGPoint(x: srcView.center.x + srcView.frame.size.width, y: srcView.center.y)
            } else {
                srcView.center = CGPoint(x: srcView.center.x - srcView.frame.size.width, y: srcView.center.y)
            }
        }, completion: { finished in
            if finished {
                srcView.removeFromSuperview()
                mainWindow.rootViewController = desViewController
            }
        })
    }
}
