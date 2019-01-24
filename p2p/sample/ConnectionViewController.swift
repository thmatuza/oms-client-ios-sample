//
//  ConnectionViewController.swift
//  OMSChat
//
//  Created by Tomohiro Matsuzawa on 2019/01/21.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import UIKit

class ConnectionViewController: UIViewController {
    weak var appDelegate: AppDelegate?

    @IBOutlet weak var urlTb: UITextField!
    @IBOutlet weak var tokenTb: UITextField!
    @IBOutlet weak var connectBtn: UIButton!

    @IBAction func textField_DidEnd(onExit sender: UITextField) {
        // hide the keyboard.
        sender.resignFirstResponder()
    }

    @IBAction func connectBtnTouchDown(_ sender: Any) {

        var tokenDict: [AnyHashable: Any] = [:]
        tokenDict["host"] = urlTb.text
        tokenDict["token"] = tokenTb.text
        UserDefaults.standard.setValue(urlTb.text, forKey: "userDefaultURL")
        UserDefaults.standard.setValue(tokenTb.text, forKey: "userDefaultToken")
        let tokenString: String
        do {
            let tokenData = try JSONSerialization.data(withJSONObject: tokenDict, options: .prettyPrinted)
            tokenString = String(data: tokenData, encoding: .utf8)!
        } catch {
            print("Failed to get token.")
            return
        }
        // TODO: Please avoid to execute connect immediatly after a previous session is closed. When
        // WebSocket old run loop ends, it may clean all event listeners binded, also includes listenrs for the new
        // session.
        peerClient?.connect(tokenString, onSuccess: { _ in
            print("Login success.")
            DispatchQueue.main.async(execute: {
                self.performSegue(withIdentifier: "MySegue", sender: self)
            })
        }, onFailure: { _ in
            print("Login fail.")
        })
    }

    private var peerClient: OMSP2PClient?

    func showMsg(_ msg: String?) {
        let alertController = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as? AppDelegate

        // register
        NotificationCenter.default.addObserver(
            self, selector: #selector(ConnectionViewController.on(_:)), name: nil, object: nil)

        peerClient = appDelegate?.peerClient
        var tmpStr = UserDefaults.standard.string(forKey: "userDefaultURL")
        if tmpStr != nil && (tmpStr?.count ?? 0) != 0 {
            urlTb.text = tmpStr
        }
        tmpStr = UserDefaults.standard.string(forKey: "userDefaultToken")
        if tmpStr != nil && (tmpStr?.count ?? 0) != 0 {
            tokenTb.text = tmpStr
        }

        // Socket.IO library uese low level network APIs. In some iOS 10 devices, OS does not ask user for
        // network permission. As a result, Socket.IO connection fails because app does not have network access.
        // Following code uese Objective-C API to trigger a network request, so user will have the chance to allow
        // network permission for this app.
        let request = URLRequest(url: URL(string: "https://www.apple.com")!)
        let queue = OperationQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { _, _, _ in
            // Nothing here.
        })
    }

    override func loadView() {
        super.loadView()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let s = segue as? HorizontalSegue
        s?.isDismiss = false
        s?.isLandscapeOrientation = false
    }

    @objc func on(_ notification: Notification?) {
    }
}
