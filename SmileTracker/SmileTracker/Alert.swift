//
//  Alert.swift
//  SmileTracker
//
//  Created by mac on 05/02/19.
//  Copyright © 2019 MMF. All rights reserved.
//

import UIKit
class Alert {
    static func toast(title:String?,message:String?,time:TimeInterval,presenterVC viewController: UIViewController,completion : (()->Void)?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        viewController.present(alert, animated: true) {
            Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { (timer) in
                alert.dismiss(animated: true, completion: {
                    if completion != nil{
                        completion!()
                    }
                })
            })
        }
    }
}
