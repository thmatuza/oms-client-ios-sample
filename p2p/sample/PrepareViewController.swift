//
//  PrepareViewController.swift
//  OMSChat
//
//  Created by Tomohiro Matsuzawa on 2019/01/22.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import UIKit

class PrepareViewController: UIViewController {
    private weak var appDelegate: AppDelegate?

    @IBOutlet var remoteUserId: UITextField!

    @IBAction func call(_ sender: Any) {
        isCaller = true
        appDelegate?.remoteUserId = remoteUserId.text!
        peerClient?.allowedRemoteIds = [appDelegate?.remoteUserId ?? ""]
        DispatchQueue.main.async(execute: {
            self.performSegue(withIdentifier: "Dial", sender: self)
        })
    }

    @IBAction func logout(_ sender: Any) {
        peerClient?.disconnectWith(onSuccess: {
            DispatchQueue.main.async(execute: {
                self.performSegue(withIdentifier: "Logout", sender: self)
            })
        }, onFailure: nil)
    }

    private var isCaller = false
    private var peerClient: OMSP2PClient?

    override func viewDidLoad() {
        super.viewDidLoad()
        isCaller = false
        NotificationCenter.default.addObserver(
            self, selector: #selector(PrepareViewController.onInvited(_:)),
            name: NSNotification.Name("OnInvited"), object: nil)
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        peerClient = appDelegate?.peerClient
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func textField_DidEnd(onExit sender: UITextField) {
        // hide the keyboard
        sender.resignFirstResponder()
    }

    /*
     #pragma mark - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     }
     */
    @objc func onInvited(_ notification: Notification?) {
        let userInfo = notification?.userInfo
        if notification?.name.rawValue == "OnInvited" {
            isCaller = false
            guard let remoteUserId = userInfo?["remoteUserId"] as? String else {
                fatalError("no remoteUserId in userInfo")
            }
            appDelegate?.remoteUserId = remoteUserId
            DispatchQueue.main.async(execute: {
                self.performSegue(withIdentifier: "Dial", sender: self)
            })
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let s = segue as? HorizontalSegue
        if segue.identifier == "Logout" {
            s?.isDismiss = true
        } else {
            s?.isDismiss = false
            let svc = segue.destination as? StreamViewController
            svc?.isCaller = isCaller
        }
        s?.isLandscapeOrientation = false

    }
}
