//
//  BLEDevController.swift
//  BLETest
//
//  Created by Maochun Sun on 2019/6/20.
//  Copyright © 2019 Maochun Sun. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum ConnDevStatus : Int{
    case BLEOff = 0
    case ConnFailed
    case FindServiceFailed
    case FindCharacteristicsFailed
    case ConnDone
    case UnsupportedDev
    case WriteFailed
    case WriteDone
    case ReadFailed
    case Disconnected
}

@objc public protocol BLEDevControllerDelegate : NSObjectProtocol{
    func enableBLESetting()
    @objc optional func newBLEDevice(newDev:BLEDev)
    @objc optional func updateBLEDevice(dev:BLEDev)
    @objc optional func updateConnDevStatus(status: Int)
}

open class BLEManager : NSObject {
    
    private var receivedBytes: [UInt8] = []
    
    private var centralManager : CBCentralManager?
    private var connBLEDevCtrl : ConnBLEDevController?
    
    private var pairedPeripheral : CBPeripheral?
    private var pairedDevUUID = ""
    
    private var theBLEDevArr : [BLEDev] = []
    
    private var maxSendDataSize = 20
    

    public var delegate : BLEDevControllerDelegate?
    
    public static let shared: BLEManager = {
        let shared = BLEManager()
        
        return shared
    }()
    
    private override init(){
        super.init()
        
        let centralQueue = DispatchQueue(label: "com.maochun.scanForBLEQueue", attributes: [])
        self.centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        self.centralManager?.delegate = self
        
    }
    
    public var isStatePoweredOn: Bool {
        return centralManager?.state == .poweredOn
    }
    
    public func numOfScanDev() -> Int{
        return theBLEDevArr.count
    }
    
    public func getBLEDev(index: Int) -> BLEDev?{
        if index < theBLEDevArr.count{
            return theBLEDevArr[index]
        }
        return nil
    }
    
    public func getBLEDev() -> [BLEDev]{
        return self.theBLEDevArr
    }
    
    public func scanForPeripherals(_ enable:Bool, serviceUUIDs: [CBUUID]? = nil) {
        
        DispatchQueue.main.async {
            if enable == true {
                logw("Start scan BLE")
                self.theBLEDevArr.removeAll()
                
                let options: NSDictionary = NSDictionary(objects: [NSNumber(value: true as Bool)], forKeys: [CBCentralManagerScanOptionAllowDuplicatesKey as NSCopying])
                
                self.centralManager?.scanForPeripherals(withServices: serviceUUIDs, options: options as? [String : AnyObject])
                //self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
                

            } else {
                logw("Stop scan BLE")
                self.centralManager?.stopScan()
                
            }
        }

    }
    
    public func isConnectWithDevice() -> Bool{
        if let connDev = connBLEDevCtrl {
            return connDev.bluetoothPeripheral.state == .connected
        }
        
        return false
    }
    
    public func connectedDeviceName() -> String?{
        if let connDev = connBLEDevCtrl, connDev.bluetoothPeripheral.state == .connected{
            return connDev.bluetoothPeripheral.name
        }
        
        return nil
    }
    

    public func reconnectPairedDevice(){
        logw("BLEManager reconnectPairedDevice")
        if let pairedUUID = UUID(uuidString: self.pairedDevUUID),
            let peripheralArray = centralManager?.retrievePeripherals(withIdentifiers: [pairedUUID]){
            if peripheralArray.count > 0 {
                
                //self.pairedPeripheral = peripheralArray.first!
                
                self.connectPeripheral(peripheral: self.pairedPeripheral!)
                
                return
                
            }else{
                logw("retrievePeripherals failed!")


            }
        }else{
            logw("no paired device")
        }
    }
    
    public func pairDevice(dev:BLEDev, serviceUUID:CBUUID, rxCharUUID:CBUUID, txCharUUID:CBUUID){
        let aPeripheral = dev.peripheral
        self.pairedDevUUID = aPeripheral.identifier.uuidString
        self.connectDevice(dev: dev, serviceUUID: serviceUUID, rxCharUUID: rxCharUUID, txCharUUID: txCharUUID)
    }
    
    public func unpairDevice(){
        logw("BLEManager unpairPeripheral")
        
        self.pairedPeripheral = nil
        self.pairedDevUUID = ""
        
        disconnectDevice()
    }
    
    public func connectDevice(dev:BLEDev, serviceUUID:CBUUID, rxCharUUID:CBUUID, txCharUUID:CBUUID) {
        ConnBLEDevController.ServiceUUID = serviceUUID
        ConnBLEDevController.RXCharacteristicUUID = rxCharUUID
        ConnBLEDevController.TXCharacteristicUUID = txCharUUID
        let aPeripheral = dev.peripheral
        self.connectPeripheral(peripheral: aPeripheral)
    }
    
    public func disconnectDevice(){
        logw("BLEManager disconnectPeripheral")
        guard connBLEDevCtrl != nil else {
            print("Peripheral not set")
            return
        }
        
        centralManager?.cancelPeripheralConnection(connBLEDevCtrl!.bluetoothPeripheral)
        
    }
    
    private func connectPeripheral(peripheral:CBPeripheral){
        centralManager?.connect(peripheral, options: nil)
    }
    
    public func sendData(byte byteArr : [UInt8]){
        let data = NSData(bytes: byteArr, length: byteArr.count) as Data
        
        //print("sendData \(Date().timeIntervalSince1970*1000) \(data.count)")
        //print(data as NSData)
        
        if data.count < self.maxSendDataSize{
            connBLEDevCtrl?.sendData(data: data)
        }else{
            self.sendDataUnit(data: data)
        }
    }
    
    func sendData(text aText : String){
        let data = aText.data(using: String.Encoding.utf8)!
        connBLEDevCtrl?.sendData(data: data)
    }
    
    func sendDataUnit(data: Data){
        print("SendDataUnit \(data.count)")
        print(data as NSData)
        
        let unitSize = maxSendDataSize;
         
        var dataLeft = data
        while dataLeft.count > unitSize {
            let dataUnit = dataLeft.subdata(in: 0..<unitSize)
            
            connBLEDevCtrl?.sendData(data: dataUnit)
            
            
            dataLeft = dataLeft.subdata(in: unitSize..<dataLeft.count)
        }
        
        if dataLeft.count > 0{
            connBLEDevCtrl?.sendData(data: dataLeft)
        }
        
    }
}

extension BLEManager :  CBCentralManagerDelegate{
    public func centralManagerDidUpdateState(_ central: CBCentralManager){
        var state : String
        switch(central.state){
        case .poweredOn:
            state = "Powered ON"
            break
            
        case .poweredOff:
            state = "Powered OFF"
            self.delegate?.enableBLESetting()
            break
            
        case .resetting:
            state = "Resetting"
            break
            
        case .unauthorized:
            state = "Unautthorized"
            self.delegate?.enableBLESetting()
            break
            
        case .unsupported:
            state = "Unsupported"
            break
            
        default:
            state = "Unknown"
            break
  
        }
        print("BLE Manager status \(state)")
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        
        if peripheral.name == nil || RSSI.intValue == 127{
            return
        }
       
        //print("dev name: \(peripheral.name)")
        
        let newDev = BLEDev(thePeripheral: peripheral, theRSSI: RSSI.intValue, theAdvDict: advertisementData)
        for dev in theBLEDevArr{
            
            if dev.isEqual(newDev){
                dev.RSSI = RSSI.intValue
                delegate?.updateBLEDevice?(dev: dev)
                   
                return
            }
        }
        
        theBLEDevArr.append(newDev)
        delegate?.newBLEDevice?(newDev: newDev)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        connBLEDevCtrl = ConnBLEDevController(connectedWith: peripheral)
        connBLEDevCtrl?.delegate = self
        
        if self.pairedDevUUID.count > 0{
            self.pairedPeripheral = peripheral
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?){
     
        delegate?.updateConnDevStatus?(status: ConnDevStatus.ConnFailed.rawValue)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        
        print("centralManager didDisconnectPeripheral")
      
        delegate?.updateConnDevStatus?(status: ConnDevStatus.Disconnected.rawValue)
        
        self.connBLEDevCtrl = nil
        
        if let pairPeripheral = self.pairedPeripheral {
            centralManager?.connect(pairPeripheral, options: nil)
        }
    }
}


extension BLEManager : ConnBLEDevControllerDelegate{
    
    
    func updateConnDevStatus(status: Int) {
        
        if status == ConnDevStatus.FindCharacteristicsFailed.rawValue ||
           status == ConnDevStatus.FindServiceFailed.rawValue ||
           status == ConnDevStatus.UnsupportedDev.rawValue{
            
            self.pairedPeripheral = nil
            self.pairedDevUUID = ""
            
            if self.isConnectWithDevice(){
                self.disconnectDevice()
            }
            
        }
        
        delegate?.updateConnDevStatus?(status: status)
    }
    
    func readData(data: Data){
        
        let bytes = [UInt8](data)
        receivedBytes.append(contentsOf: bytes)
    }
}



