//
//  ViewController.swift
//  maochun-blekit
//
//  Created by maochuns on 03/20/2020.
//  Copyright (c) 2020 maochuns. All rights reserved.
//

import UIKit
import maochun_blekit
import CoreBluetooth

class ViewController: UIViewController {
    

    let ServiceUUID = CBUUID(string: "BC280001-610E-4C94-A5E2-0F352D4B5256")
    let TXCharacteristicUUID = CBUUID(string: "BC280003-610E-4C94-A5E2-0F352D4B5256")
    let RXCharacteristicUUID = CBUUID(string: "BC280002-610E-4C94-A5E2-0F352D4B5256")


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        BLEManager.shared.delegate = self
        BLEManager.shared.scanForPeripherals(true, serviceUUIDs: [self.ServiceUUID])
                    
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        BLEManager.shared.scanForPeripherals(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: BLEDevControllerDelegate {
    func enableBLESetting() {
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Bluetooth is off",
                                          message:"Please turn on your bluetooth",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Setting",
                                          style: .default,
                                          handler: {
                                            
                                            (action) in
                                            if action.style == .default{
                                                
                                                if let url = URL(string:UIApplication.openSettingsURLString)
                                                {
                                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                                }
                                                
                                            }
            }))
            
            
            alert.addAction(UIAlertAction(title: "Cancel",
                                          style: .default,
                                          handler: nil))
            
            
            self.present(alert, animated: true, completion:nil)
        }
    }
    
    func newBLEDevice(newDev:BLEDev){
        print("new dev \(newDev.name()) \(newDev.RSSI)")
        print("Advertisment dict \(newDev.advDict)")
        
        //Check if the device is the right one to connect with
        
        BLEManager.shared.scanForPeripherals(false)
        BLEManager.shared.connectDevice(dev: newDev, serviceUUID: self.ServiceUUID, rxCharUUID: self.RXCharacteristicUUID, txCharUUID: self.TXCharacteristicUUID)
    }
    
    func updateBLEDevice(dev:BLEDev){
        //print("update dev \(dev.name()) \(dev.RSSI)")
    }
    
    func updateConnDevStatus(status: Int){
        guard let status = ConnDevStatus(rawValue: status) else{
            return
        }
        
        logw("BaseViewController update conn status \(status)")
        
        switch status {
        case ConnDevStatus.BLEOff:
            self.enableBLESetting()
            break
            
        case ConnDevStatus.ConnFailed:
            //Connect with device failed
            break
            
        case ConnDevStatus.FindServiceFailed:
            //Connect with device failed
            break
        
        case ConnDevStatus.FindCharacteristicsFailed:
            //Connect with device failed
            break
            
        case ConnDevStatus.UnsupportedDev:
            //Connect with device failed
            break
            
        case ConnDevStatus.ConnDone:
            //Conect successful. Can send data to device
            //self.bleManager.sendDataRecvReply(data: testData, sendTimeoutInSecond: 0.5, recvTimeoutInSecond: 0.5)
            break
            
    
        case ConnDevStatus.Disconnected:
            //Device disconnected
            break
            
        }
    }
    
    
}
