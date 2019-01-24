//
//  ConferenceConnectionViewController.swift
//  OMSConference
//
//  Created by Tomohiro Matsuzawa on 2019/01/16.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import Alamofire
import UIKit

class ConferenceConnectionViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var hostTb: UITextField!

    @IBAction func connectBtnTouchDown(_ sender: Any) {
        UserDefaults.standard.setValue(hostTb.text, forKey: "userDefaultURL")
        getTokenFromBasicSample(hostTb.text!, onSuccess: { token in
            self.conferenceClient?.join(withToken: token, onSuccess: { info in
                DispatchQueue.main.async(execute: {
                    if !info.remoteStreams.isEmpty {
                        let appDelegate = UIApplication.shared.delegate as? AppDelegate
                        appDelegate?.conferenceId = info.conferenceId
                        for s: OMSRemoteStream? in info.remoteStreams {
                            s?.delegate = appDelegate
                            if s is OMSRemoteMixedStream {
                                appDelegate?.mixedStream = s as? OMSRemoteMixedStream
                                break
                            }
                        }
                    }
                    self.performSegue(withIdentifier: "Login", sender: self)
                })
            }, onFailure: { err in
                print("Join failed. \(err)")
            })
        }, onFailure: {
            print("Failed to get token from basic server.")
        })

    }

    private func getTokenFromBasicSample(_ basicServer: String, onSuccess: @escaping (String) -> Void,
                                         onFailure: @escaping () -> Void) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.serverUrl = basicServer
        let params = [
            "room": "",
            "username": "user",
            "role": "presenter"
        ]
        AF.request(basicServer + "createToken/", method: .post, parameters: params,
                   encoding: JSONEncoding.default).response { response in
            var data: Data?
            switch response.result {
            case .failure(let error):
                print("Error: \(error)")
            case .success:
                if let responseObject = response.data {
                    data = Data(base64Encoded: responseObject)
                }
                if let data = data {
                    onSuccess(String(data: data, encoding: .utf8)!)
                }
            }
        }
    }

    private var conferenceClient: OMSConferenceClient?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        hostTb.delegate = self
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        conferenceClient = appDelegate?.conferenceClient
        let tmpStr = UserDefaults.standard.string(forKey: "userDefaultURL")
        if tmpStr != nil && (tmpStr?.count ?? 0) != 0 {
            hostTb.text = tmpStr
        }
        // Socket.IO library uese low level network APIs. In some iOS 10 devices, OS does not ask user for
        // network permission. As
        // a result, Socket.IO connection fails because app does not have network access. Following code
        // uese Objective-C API to trigger
        // a network request, so user will have the chance to allow network permission for this app.
        let request = NSMutableURLRequest()
        request.url = URL(string: "https://www.apple.com")
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {_, _, _ -> Void in
            // Nothing here.
        })
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hostTb.resignFirstResponder()
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let s = segue as? HorizontalSegue
        s?.isDismiss = false
    }
}
