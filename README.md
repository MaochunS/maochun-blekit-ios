# maochun-blekit

[![CI Status](https://img.shields.io/travis/maochuns/maochun-blekit.svg?style=flat)](https://travis-ci.org/maochuns/maochun-blekit)
[![Version](https://img.shields.io/cocoapods/v/maochun-blekit.svg?style=flat)](https://cocoapods.org/pods/maochun-blekit)
[![License](https://img.shields.io/cocoapods/l/maochun-blekit.svg?style=flat)](https://cocoapods.org/pods/maochun-blekit)
[![Platform](https://img.shields.io/cocoapods/p/maochun-blekit.svg?style=flat)](https://cocoapods.org/pods/maochun-blekit)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

maochun-blekit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'maochun-blekit'
```

## Usage

* Implement BLEDevControllerDelegate

```swift
    func enableBLESetting() {
        //Called when BLE is off
        //Ask user to turn on BLE
    }
    
    func newBLEDevice(newDev:BLEDev){
        //Return new device detected
        //Check if the device is the right one to connect with
        
        print("new dev \(newDev.name()) \(newDev.RSSI)")
        print("Advertisment dict \(newDev.advDict)")
        
    }
    
    func updateConnDevStatus(status: Int){
        guard let status = ConnDevStatus(rawValue: status) else{
            return
        }
        
       print("device update conn status \(status)")
        
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
```

* Init BLEManager

```swift 
BLEManager.shared.delegate = self
```

* Start / Stop scan for BLE device

```swift
BLEManager.shared.scanForPeripherals(true, serviceUUIDs: [self.ServiceUUID])
BLEManager.shared.scanForPeripherals(false)
```

* Connect / disconnect with BLE device

```swift
BLEManager.shared.connectDevice(dev: newDev, serviceUUID: self.ServiceUUID, 
                                rxCharUUID: self.RXCharacteristicUUID, 
                                txCharUUID: self.TXCharacteristicUUID)

BLEManager.shared.disconnectDevice()
```

* Send data to connected BLE device

### Send data synchronized

func sendDataSync(data theData: Data, timeoutInSecond:Double = 0.5) -> Bool

```swift
let ret = sendDataSync(data: testData, timeoutInSecond:0.5)
if ret{
    print("send data successful")
}else{
    print("send data failed!")
}
```


### Send data and receive reply synchronized

func sendDataRecvReply(data theData: Data, sendTimeoutInSecond:Double = 0.5, 
                       recvTimeoutInSecond:Double = 0.5) -> (ret:Bool, reply:Data?)

```swift
let (ret, reply) = BLEManager.shared.sendDataRecvReply(data: testData, 
                                    sendTimeoutInSecond: 0.5, recvTimeoutInSecond: 0.5)
if ret, let reply=reply{
    print("send data recv reply successfully! reply = \(reply)")
}else{
    print("send data recv reply failed!")
}
```

## Author

maochuns, maochuns.sun@gmail.com

## License

maochun-blekit is available under the MIT license. See the LICENSE file for more info.
