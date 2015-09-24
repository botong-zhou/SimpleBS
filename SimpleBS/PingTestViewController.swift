//
//  NetworkTestViewController.swift
//  SimpleBS
//
//  Created by bin1991 on 15/9/17.
//  Copyright (c) 2015年 bin1991. All rights reserved.
//

import UIKit

class PingTestViewController: UIViewController, CDZPingerDelegate //,  UITextViewDelegate
{
    
    @IBOutlet weak var testAddressInput: UITextField!
    @IBOutlet weak var liveResultsView: UITextView!
    @IBOutlet weak var finalResultsView: UITextView!
    @IBOutlet weak var taskLabel: UILabel!
    @IBOutlet weak var OKTapped: UIButton!
    
    var pinger = CDZPinger()
    var currentTimes: Int = 0
    var errorTimes: Int = 0
    var allTime:[Int] = []
    var isBegin: Bool = true
    var finalOuput:String = ""
    var prefs = NSUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        OKTapped.addTarget(self, action: "onClick", forControlEvents: UIControlEvents.TouchUpInside)
        
        prefs = NSUserDefaults.standardUserDefaults()
        var lastHost = prefs.stringForKey("LastHost")
        if (lastHost != nil) {
            testAddressInput.text = lastHost
        }
        
        println("ViewController Ping")

//        liveResultsView.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    func pinger(pinger: CDZPinger!, didUpdateWithAverageSeconds seconds: NSTimeInterval) {
        let takesTime = Int(seconds * 1000)
        println("Received ping; average time \(takesTime) ms")
        var output = liveResultsView.text
        currentTimes = currentTimes + 1
        liveResultsView.text = output + "\n" + " 64 bytes from" + " \(testAddressInput.text):" + " icmp_seq=\(currentTimes)" + " ttl=58" + " time=" + "\(takesTime)" + " ms"
        allTime.append(takesTime)
    }
    
    func pinger(pinger: CDZPinger!, didEncounterError error: NSError!) {
        println("请求超时")
        errorTimes = errorTimes + 1
    }
    
    func onClick()
    {
        if isBegin {
            self.OKTapped.setTitle("停止", forState: UIControlState.Normal)
            isBegin = !isBegin
            prefs.setObject(testAddressInput.text, forKey: "LastHost")
            prefs.synchronize()
            if let addressInput = testAddressInput.text {
                testAddressInput.resignFirstResponder()
                self.pinger = CDZPinger(host: addressInput)
                self.pinger.startPinging()
                self.pinger.delegate = self
                self.taskLabel.text = " PING  \(addressInput):  56  data  bytes"
            }
        } else {
            self.OKTapped.setTitle("开始", forState: UIControlState.Normal)
            isBegin = !isBegin
            pinger.stopPinging()
            println("^C")
            println("\(allTime)")
            
            var lossPackets = String(format: "%.2f", (errorTimes / currentTimes) * 100) + "%"
            println("--- \(testAddressInput.text) ping statistics ---")
            println("\(currentTimes - 1) packets transmitted, \(currentTimes - errorTimes - 1) packets received, \(lossPackets) packet loss")
            finalOuput = " --- \(testAddressInput.text) ping statistics ---\n \(currentTimes - 1) packets transmitted, \(currentTimes - errorTimes - 1) packets received, \(lossPackets) packet loss\n"

            statistics()
        }
    }
    
    func statistics() {
        
        if allTime != [] {
            allTime.sort{ $0 < $1 }
//             //冒泡排序
//            for var i = 0; i < allTime.count - 1; ++i {
//                for var j = 0; j < allTime.count - 1 - i; ++j {
//                    if allTime[j] > allTime[j + 1] {
//                        var temp = allTime[j + 1]
//                        allTime[j + 1] = allTime[j]
//                        allTime[j] = temp
//                    }
//                }
//            }
            println("\(allTime)")
            let minTime = allTime.first!
            let maxTime = allTime.last!
            var avgTime: Int = 0
            var sumTime: Int = 0
            
            for var j = 0; j < allTime.count; ++j {
//                println("\(j)")
                sumTime = sumTime + allTime[j]
            }
            
            if currentTimes != 0 {
                avgTime = sumTime / currentTimes
            }
            
            println("round-trip min/avg/max = \(minTime)/\(avgTime)/\(maxTime) ms")
            
            finalResultsView.text = finalOuput + "round-trip min/avg/max = \(minTime)/\(avgTime)/\(maxTime) ms\n"
            
        } else {
            println("^C")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent?) {
        testAddressInput.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
