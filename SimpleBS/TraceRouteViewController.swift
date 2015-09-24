//
//  TraceRouteViewController.swift
//  SimpleBS
//
//  Created by bin1991 on 15/9/23.
//  Copyright (c) 2015年 bin1991. All rights reserved.
//

import UIKit

class TraceRouteViewController: UIViewController, UITextFieldDelegate , TraceRouteDelegate
{
    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var hostNameLabel: UILabel!    
    @IBOutlet weak var routeHopsTextView: UITextView!
    @IBOutlet weak var execButton: UIButton!
    
    var traceRoute:TraceRoute = TraceRoute()
    var prefs = NSUserDefaults()
    
    let ttl: Int32 = 20
    let timeout: Int32 = 5000000
    let port: Int32 = 80
    let maxAttempts: Int32 = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        
        execButton.addTarget(self, action: "beginTrace", forControlEvents: UIControlEvents.TouchUpInside)
        
        prefs = NSUserDefaults.standardUserDefaults()
        var lastHost = prefs.stringForKey("LastHost")
        if (lastHost != nil) {
            hostTextField.text = lastHost
        }
        
        traceRoute = TraceRoute(maxTTL: ttl, timeout: timeout, maxAttempts: maxAttempts, port: port)
        traceRoute.delegate = self
        
        println("ViewController TraceRoute")
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func beginTrace() {
        hostTextField.resignFirstResponder()
        if traceRoute.isRunning() {
            traceRoute.stopTrace()

        } else {
            prefs.setObject(hostTextField.text, forKey: "LastHost")
            prefs.synchronize()
            
            if let addressInput = hostTextField.text {
                NSThread.detachNewThreadSelector("doTraceRoute:", toTarget: traceRoute, withObject: addressInput)
                execButton.setTitle("停止", forState: UIControlState.Normal)
                routeHopsTextView.text = ""
                hostNameLabel.text = "traceroute \(addressInput)"
            }
        }
    }
    
    // MARK: - TraceRouteDelegate
    
    func newHop(hop: Hop!) {
        
        println("\(hop.hostAddress)")
        
        var output = routeHopsTextView.text
        routeHopsTextView.text = output + "\(hop.hostAddress)(\(hop.hostName)) \n"
    }
    
    func end() {
        execButton.setTitle("开始", forState: UIControlState.Normal)
    }
    
    func error(errorDesc: String!) {
        println("ERROR: \(errorDesc)")
        end()
    }
    
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent?) {
        hostTextField.resignFirstResponder()
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
