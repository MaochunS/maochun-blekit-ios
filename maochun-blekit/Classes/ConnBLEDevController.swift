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
    @objc optional func writeDone(ret: Bool)
}

class ConnBLEDevController: NSObject {
    var bluetoothPeripheral : CBPeripheral!
    var delegate : ConnBLEDevControllerDelegate?
    
    private var maxSendDataSize = 20
    
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
    
    public var sendDataTimeout : Double = 0.5
    public var recvDataTimeout : Double = 0.5
    
    
    init(connectedWith peripheral : CBPeripheral){
        super.init()
        
        logw("ConnBLEDevController init")
        bluetoothPeripheral = peripheral
        bluetoothPeripheral.delegate = self
        bluetoothPeripheral.discoverServices([ConnBLEDevController.ServiceUUID])
        
    }
    
    func sendDataUnit(data: Data){
        print("SendDataUnit \(data.count)")
        print(data as NSData)
        
        let unitSize = maxSendDataSize;
         
        var dataLeft = data
        while dataLeft.count > unitSize {
            let dataUnit = dataLeft.subdata(in: 0..<unitSize)
            
            sendData(data: dataUnit)
            dataLeft = dataLeft.subdata(in: unitSize..<dataLeft.count)
        }
        
        if dataLeft.count > 0{
            sendData(data: dataLeft)
        }
    }
    
    func sendDataUnitSync(data: Data) -> Bool{
        let unitSize = maxSendDataSize;
         
        var ret = false
        var dataLeft = data
        while dataLeft.count > unitSize {
            let dataUnit = dataLeft.subdata(in: 0..<unitSize)
            
            ret = sendDataSync(data: dataUnit)
            dataLeft = dataLeft.subdata(in: unitSize..<dataLeft.count)
            
            if !ret{
                return ret
            }
        }
        
        if dataLeft.count > 0{
            ret = sendDataSync(data: dataLeft)
        }
        
        return ret
    }
    
    private func sendData(data: Data){
        //print("sendData \(data as NSData)")
        if bluetoothPeripheral.state == .connected, let txChar = self._TXCharacteristic{
            bluetoothPeripheral.writeValue(data, for: txChar, type: .withoutResponse)
        }else{
            logw("device disconnected. sendData abort!")
            delegate?.writeDone?(ret: false)
        }
    }
    
    func sendDataSync(data: Data) -> Bool{
        
        var ret = false
        
        if bluetoothPeripheral.state == .connected, let txChar = self._TXCharacteristic{
            sendcmdReqDG = DispatchGroup()
            self.sendcmdReqDG!.enter()
            bluetoothPeripheral.writeValue(data, for: txChar, type: .withoutResponse)
            let waitRet = self.sendcmdReqDG!.wait(timeout: .now() + self.sendDataTimeout)
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
    
    func sendDataRecvReply(data: Data) -> (ret: Bool, reply: Data?){
        
        var ret = false
        
        recvReplyDG = DispatchGroup()
        self.recvReplyDG!.enter()
        self.receivedData = nil
        
        if self.sendDataUnitSync(data: data){
            let waitRet = self.recvReplyDG!.wait(timeout: .now() + self.recvDataTimeout)
            switch waitRet{
            case .success:
                //print("sendCmdRecvDataSync success")
                ret = true
                break
                
            case .timedOut:
                //print("sendCmdRecvDataSync timeout")
                ret = false
                break
            }
        }
        
        self.recvReplyDG = nil
        return (ret, self.receivedData)
    }
    
    /*
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
    */
}

extension ConnBLEDevController: CBPeripheralDelegate{
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?){
        bluetoothPeripheral.readRSSI()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?){
        //print("rssi = \(RSSI)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        guard error == nil else {
            logw("Service discovery failed \(error?.localizedDescription ?? "")")
            delegate?.updateConnDevStatus?(status: ConnDevStatus.FindServiceFailed.rawValue)
            return
        }

        for aService: CBService in peripheral.services! {
            if aService.uuid.isEqual(ConnBLEDevController.ServiceUUID) {
                bluetoothPeripheral!.discoverCharacteristics(nil, for: aService)
                return
            }
        }
        
        logw("Didn't find the service. Device unsupported!")
        delegate?.updateConnDevStatus?(status: ConnDevStatus.UnsupportedDev.rawValue)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        
        guard error == nil else {
            print("Characteristics discovery failed \(error?.localizedDescription ?? "")")
            delegate?.updateConnDevStatus?(status: ConnDevStatus.FindCharacteristicsFailed.rawValue)
            return
        }
        
        if service.uuid.isEqual(ConnBLEDevController.ServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid.isEqual(ConnBLEDevController.TXCharacteristicUUID) {
                    logw("TX Characteristic found")
                    _TXCharacteristic = aCharacteristic
                }
                
                if aCharacteristic.uuid.isEqual(ConnBLEDevController.RXCharacteristicUUID) {
                    logw("RX Characteristic found")
                    _RXCharacteristic = aCharacteristic
                }
            }
            
            //Enable notifications on TX Characteristic
            if _TXCharacteristic != nil && _RXCharacteristic != nil {
                
                
                //delegate?.updateConnDevStatus?(status: ConnDevStatus.ConnDone.rawValue)
               
                logw("Set Rx notification value")
                bluetoothPeripheral!.setNotifyValue(true, for: _RXCharacteristic!)
                
                
            } else {
                logw("Didn't find the Tx/Rx characteristic. Unsupported device!")
                delegate?.updateConnDevStatus?(status: ConnDevStatus.UnsupportedDev.rawValue)
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        
        guard error == nil else {
            logw("Updating characteristic has failed \(error?.localizedDescription ?? "")")
            return
        }
        
        //let resultStr = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
        
        
        // try to print a friendly string of received bytes if they can be parsed as UTF8
        guard let dataReceived = characteristic.value else {
            logw("Notification received from: \(characteristic.uuid.uuidString), with empty value")
            self.recvReplyDG?.leave()
            return
        }
        
        
        //let str : String = NSString(data: dataReceived, encoding: String.Encoding.utf8.rawValue)! as String
        logw("\(Date().timeIntervalSince1970*1000) didReceiveData from characteristic \(characteristic.uuid.uuidString)")
        //logw(dataReceived as NSData)
        
        self.receivedData = dataReceived
        self.recvReplyDG?.leave()
        
        delegate?.readData?(data: dataReceived)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        guard error == nil else {
            logw("Writing value to characteristic failed \(error?.localizedDescription ?? "")")
            delegate?.writeDone?(ret: false)
            
            self.sendcmdReqDG?.leave()
            return
        }
        
        delegate?.writeDone?(ret: true)
        logw("Data has written to characteristic: \(characteristic.uuid.uuidString)")
        
        self.sendcmdReqDG?.leave()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            logw("Writing value to descriptor failed \(error?.localizedDescription ?? "")")
           
            return
        }
        
        logw("Data has written to descriptor: \(descriptor.uuid.uuidString)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        
        guard error == nil else {
            logw("Enabling notifications failed \(error?.localizedDescription ?? "")")
            
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
