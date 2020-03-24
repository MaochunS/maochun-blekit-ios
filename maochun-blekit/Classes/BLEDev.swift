//
//  BLEDev.swift
//  BLETest
//
//  Created by Maochun Sun on 2019/6/20.
//  Copyright © 2019 Maochun Sun. All rights reserved.
//

import Foundation
import CoreBluetooth

public func logw(_ text: String) {
    if BLEManager.enableLog{
        print(text)
    }
    
}

open class BLEDev: NSObject {
    public var peripheral   : CBPeripheral
    public var RSSI         : Int
    public var advDict      : [String : Any]
    
    init(thePeripheral: CBPeripheral, theRSSI:Int, theAdvDict:[String : Any]) {
        peripheral = thePeripheral
        RSSI = theRSSI
        advDict = theAdvDict
    }
    
    public func name()->String{
        if let peripheralName = peripheral.name{
            return peripheralName
        }
            
        return "No name"
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        if let otherPeripheral = object as? BLEDev {
            return peripheral == otherPeripheral.peripheral
        }
        return false
    }
}
