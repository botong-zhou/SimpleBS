//
//  ViewController.swift
//  SimpleBS
//
//  Created by bin1991 on 15/9/15.
//  Copyright (c) 2015年 bin1991. All rights reserved.
//

import UIKit
import CoreTelephony
import MapKit
//import CoreLocation

class RootViewController: UIViewController, MKMapViewDelegate
{
    
    @IBOutlet weak var carrierNameLabel: UILabel!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var vioceAndDataLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var osNamelabel: UILabel!
    @IBOutlet weak var osVesionLabel: UILabel!
    @IBOutlet weak var currentLocationMapView: MKMapView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        getCarrierInfo()
        getDeviceInfo()
        
        //设置地图视图代理
        currentLocationMapView.delegate = self
        //显示当前位置
        currentLocationMapView.showsUserLocation = true

        println("ViewController Main")
    }
    //获取运营商数据
    func getCarrierInfo() {
        let telephonyInfo: CTTelephonyNetworkInfo = CTTelephonyNetworkInfo()
        
        if let carrier:CTCarrier = telephonyInfo.subscriberCellularProvider {
//            println("运营商信息: \(carrier.description)")
//            println("运营商名称: \(carrier.mobileNetworkCode)")
            let carrierCode = carrier.mobileNetworkCode
            let countryCode = carrier.mobileCountryCode
            
//            println("运营商名称: \(carrierNames[carrierCode]!)")
//            println("国家或地区: \(countryNames[countryCode]!)")
            self.carrierNameLabel.text = carrierNames[carrierCode]!
            self.countryNameLabel.text = countryNames[countryCode]!
        }
        
        //获取当前蜂窝网络数据类型并去掉前面没有用的23个字母
        if let networkInfo = telephonyInfo.currentRadioAccessTechnology {
            let fromIndex = advance(networkInfo.startIndex, 23)
            let networkType = networkInfo.substringFromIndex(fromIndex)
            
//            println("语音与数据: \(networkType)")
            self.vioceAndDataLabel.text = networkType
            
            //网络信号改变时输出新网络类型
            NSNotificationCenter.defaultCenter().addObserverForName(CTRadioAccessTechnologyDidChangeNotification,
                                                                    object: nil,
                                                                     queue: nil,
                                                                usingBlock: { note in
//                                                                    println("语音与数据类型已变更为: \(networkType)")
                                                                    self.vioceAndDataLabel.text = networkType
                                                                })
        }
    }
    //获取设备数据
    func getDeviceInfo() {
        let myDevice: UIDevice = UIDevice.currentDevice()
//        println("设备名称 : \(myDevice.name)")
//        println("系统名称 : \(myDevice.systemName)")
//        println("系统版本 : \(myDevice.systemVersion)")
        self.deviceNameLabel.text = myDevice.name
        self.osNamelabel.text = myDevice.systemName
        self.osVesionLabel.text = myDevice.systemVersion
        
    }
    //获取当前位置
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        let loc: CLLocationCoordinate2D = userLocation.coordinate
        let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(loc, 500, 500)
        self.currentLocationMapView.setRegion(region, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Model
    let carrierNames: [String: String] =
    [
        "01": "Cellcard",
        "02": "hello",
        "03": "S Telecom",
        "04": "qb",
        "05": "Star-Cell",
        "06": "Smart",
        "18": "Mfone",
        "11": "Seatel",
        "09": "Beeline",
        "08": "Metfone"
    ]
    
    let countryNames: [String: String] =
    [
        "460": "中华人民共和国",
        "456": "柬埔寨",
        "525": "新加坡"
    ]


}

