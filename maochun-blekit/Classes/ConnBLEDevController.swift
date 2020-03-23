//
//  ConnBLEDevController.swift
//  BLETest
//
//  Created by Maochun Sun on 2019/6/20.
//  Copyright © 2019 Maochun Sun. All rights reserved.
//

import Foundation
import CoreBluetooth



@objc protocol ConnBLEDevControllerDelegate : NSObjectProtocol{
    
    @objc optional func updateConnDevStatus(status: Int)
    @objc optional func readData(data: Data)
}

class ConnBLEDevController: NSObject {
    var bluetoothPeripheral : CBPeripheral!
    var delegate : ConnBLEDevControllerDelegate?
    
    /*
    fileprivate let _ServiceUUID             : CBUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    fileprivate let _TXCharacteristicUUID    : CBUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    fileprivate let _RXCharacteristicUUID    : CBUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    
    fileprivate let _ServiceUUID             : CBUUID = CBUUID(string: "0000ffe0-0000-1000-8000-00805f9b34fb")
    fileprivate let _TXCharacteristicUUID    : CBUUID = CBUUID(string: "0000ffe1-0000-1000-8000-00805f9b34fb")
    fileprivate let _RXCharacteristicUUID    : CBUUID = CBUUID(string: "0000ffe1-0000-1000-8000-00805f9b34fb")
    
    */
    
    static var ServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static var TXCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static var RXCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
   
    fileprivate var _Service: CBService?
    fileprivate var _RXCharacteristic: CBCharacteristic?
    fileprivate var _TXCharacteristic: CBCharacteristic?
    
    fileprivate var sendcmdReqDG : DispatchGroup?
    fileprivate var recvReplyDG : DispatchGroup?
    fileprivate var receivedData: Data?
    
    
    init(connectedWith peripheral : CBPeripheral){
        super.init()
        
        bluetoothPeripheral = peripheral
        bluetoothPeripheral.delegate = self
        bluetoothPeripheral.discoverServices([ConnBLEDevController.ServiceUUID])
        
    }
    
    func sendData(data: Data){
        //print("sendData \(data as NSData)")
        if bluetoothPeripheral.state == .connected, let txChar = self._TXCharacteristic{
            bluetoothPeripheral.writeValue(data, for: txChar, type: .withoutResponse)
        }else{
            print("sendData abort!")
        }
    }
    
    func sendDataSync(data: Data) -> Bool{
        
        var ret = false
        
        if bluetoothPeripheral.state == .connected, let txChar = self._TXCharacteristic{
            sendcmdReqDG = DispatchGroup()
            self.sendcmdReqDG!.enter()
            bluetoothPeripheral.writeValue(data, for: txChar, type: .withoutResponse)
            let waitRet = self.sendcmdReqDG!.wait(timeout: .now() + 0.2)
            switch waitRet{
            case .success:
                ret = true
                break
                
            case .timedOut:
                ret = false
                break
            }
            
            sendcmdReqDG = nil
            
        }else{
            return ret
        }
        
        return ret
    }
    
    func sendCmdRecvDataSync(data: Data) -> (ret: Bool, reply: Data?){
        print("sendCmdRecvDataSync")
        var ret = false
        
        if bluetoothPeripheral.state == .connected, let txChar = self._TXCharacteristic{
            //sendcmdReqDG = DispatchGroup()
            recvReplyDG = DispatchGroup()
            
            //self.sendcmdReqDG!.enter()
            self.recvReplyDG!.enter()
            self.receivedData = nil
            
            bluetoothPeripheral.writeValue(data, for: txChar, type: .withoutResponse)
            
            /*
            var waitRet = self.sendcmdReqDG!.wait(timeout: .now() + 2)
            switch waitRet{
            case .success:
                ret = true
                break
                
            case .timedOut:
                ret = false
                break
            }
            */
            let waitRet = self.recvReplyDG!.wait(timeout: .now() + 2)
            switch waitRet{
            case .success:
                print("sendCmdRecvDataSync success")
                ret = true
                break
                
            case .timedOut:
                print("sendCmdRecvDataSync timeout")
                ret = false
                break
            }
            
            self.sendcmdReqDG = nil
            self.recvReplyDG = nil
            
        }else{
            return (ret: false, reply: nil)
        }
        
        return (ret: ret, reply: self.receivedData)
    }
}

extension ConnBLEDevController: CBPeripheralDelegate{
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?){
        bluetoothPeripheral.readRSSI()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?){
        print("rssi = \(RSSI)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        guard error == nil else {
            print("Service discovery failed \(error.debugDescription)")
            delegate?.updateConnDevStatus?(status: ConnDevStatus.FindServiceFailed.rawValue)
            return
        }

        for aService: CBService in peripheral.services! {
            if aService.uuid.isEqual(ConnBLEDevController.ServiceUUID) {
                bluetoothPeripheral!.discoverCharacteristics(nil, for: aService)
                return
            }
        }
        
        delegate?.updateConnDevStatus?(status: ConnDevStatus.UnsupportedDev.rawValue)
        print("Device unsupported!")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        
        guard error == nil else {
            print("Characteristics discovery failed \(error.debugDescription)")
            delegate?.updateConnDevStatus?(status: ConnDevStatus.FindCharacteristicsFailed.rawValue)
            return
        }
        
        if service.uuid.isEqual(ConnBLEDevController.ServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid.isEqual(ConnBLEDevController.TXCharacteristicUUID) {
                    print("TX Characteristic found")
                    _TXCharacteristic = aCharacteristic
                }
                
                if aCharacteristic.uuid.isEqual(ConnBLEDevController.RXCharacteristicUUID) {
                    print("RX Characteristic found")
                    _RXCharacteristic = aCharacteristic
                }
            }
            
            //Enable notifications on TX Characteristic
            if _TXCharacteristic != nil && _RXCharacteristic != nil {
                
                
                //delegate?.updateConnDevStatus?(status: ConnDevStatus.ConnDone.rawValue)
               
                bluetoothPeripheral!.setNotifyValue(true, for: _RXCharacteristic!)
                
                
            } else {
                
                delegate?.updateConnDevStatus?(status: ConnDevStatus.UnsupportedDev.rawValue)
                print("Unsupported device!")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        
        guard error == nil else {
            print("Updating characteristic has failed \(error.debugDescription)")
           
            return
        }
        
        //let resultStr = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
        
        
        // try to print a friendly string of received bytes if they can be parsed as UTF8
        guard let dataReceived = characteristic.value else {
            print("Notification received from: \(characteristic.uuid.uuidString), with empty value")
            delegate?.updateConnDevStatus?(status: ConnDevStatus.ReadFailed.rawValue)
            self.recvReplyDG?.leave()
            return
        }
        
        
        
        //let str : String = NSString(data: dataReceived, encoding: String.Encoding.utf8.rawValue)! as String
        //print("\(Date().timeIntervalSince1970*1000) didReceiveData from characteristic \(characteristic.uuid.uuidString)")
        //print(dataReceived as NSData)
        
        self.receivedData = dataReceived
        self.recvReplyDG?.leave()
        
        delegate?.readData?(data: dataReceived)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        guard error == nil else {
            print("Writing value to characteristic has failed \(error.debugDescription)")
            delegate?.updateConnDevStatus?(status: ConnDevStatus.WriteFailed.rawValue)
            
            self.sendcmdReqDG?.leave()
            return
        }
        
        delegate?.updateConnDevStatus?(status: ConnDevStatus.WriteDone.rawValue)
        print("Data written to characteristic: \(characteristic.uuid.uuidString)")
        
        self.sendcmdReqDG?.leave()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Writing value to descriptor has failed \(error.debugDescription)")
           
            return
        }
        
        
        
        print("Data written to descriptor: \(descriptor.uuid.uuidString)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        
        guard error == nil else {
            print("Enabling notifications failed \(error.debugDescription)")
            
            delegate?.updateConnDevStatus?(status: ConnDevStatus.FindCharacteristicsFailed.rawValue)
            return
        }
        
        if characteristic.isNotifying {
            print("Notifications enabled for characteristic: \(characteristic.uuid.uuidString)")
            
        } else {
            print("Notifications disabled for characteristic: \(characteristic.uuid.uuidString)")
        }
        
        delegate?.updateConnDevStatus?(status: ConnDevStatus.ConnDone.rawValue)
    }
    
    
}
