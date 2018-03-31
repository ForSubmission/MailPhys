//
// Copyright (c) 2018 ANONYMISED
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import IOBluetooth

/// Singleton that takes care of connecting to bluetooth devices
class BluetoothMaster: NSObject, IOBluetoothDeviceInquiryDelegate, IOBluetoothDevicePairDelegate, IOBluetoothDeviceAsyncCallbacks, BluetoothUnpackerDelegate {
    
    static let shared = BluetoothMaster()
    
    // MARK: - Instance properties
    
    // fix these
    var l2cappsm = UnsafeMutablePointer<BluetoothL2CAPPSM>.allocate(capacity: 1)
    var rfcId = UnsafeMutablePointer<BluetoothRFCOMMChannelID>.allocate(capacity: 1)
    var rfcChannel: IOBluetoothRFCOMMChannel?
    
    // mac addresses are hardcoded here to identify the two devices
    
    let device2mac = "00-06-66-d7-cc-43"
    let device1mac = "00-06-66-88-da-6a"
    let unpacker1 = BluetoothUnpacker()

    /// Default pairing code (1234)
    static let codeArr = [UInt8]("1234".utf8) // 4 characters
    var code = BluetoothPINCode(data: (codeArr[0], codeArr[1], codeArr[2], codeArr[3], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)) // DA6A

    var enquiry: IOBluetoothDeviceInquiry!
    var pairing: IOBluetoothDevicePair!
    weak var device1: IOBluetoothDevice!
    
    /// Reference to BluetoothDebugController (if active)
    weak var debugController: BluetoothDebugController?

    /// Debug text
    /// Just append invidual strings to this
    var debugText = [String]() { didSet {
        if let debugController = self.debugController {
            DispatchQueue.main.async {
                debugController.textView.string = self.debugText.joined(separator: "\n")
                debugController.textView.scrollToEndOfDocument(nil)
            }
        }
    } }
    
    // MARK: - Init
    
    private override init() {
        
        super.init()
        
        unpacker1.delegate = self
        
        enquiry = IOBluetoothDeviceInquiry(delegate: self)
        enquiry.updateNewDeviceNames = false
        enquiry.inquiryLength = 4
    }
    
    // MARK: - Static methods
    
    /// Starts search for bluetooth devices and assigns the expected mac
    /// addresses to our device references.
    /// Once search is over, pairs to devices if they are not already paired.
    static func startSearch() {
        let val = shared.enquiry.start()
        if val == kIOReturnSuccess {
            shared.debugText.append("Search start success")
        } else {
            shared.outputResult("Search start", res: val)
        }
    }
    
    /// get sdp
    static func sdpQuery() {
        shared.debugText.append("Performing query...")
        shared.device1.performSDPQuery(shared)
    }
    
    /// disconnect rfcomm channel
    static func rfcDisconnect() {
        shared.outputResult("closeConnection()", res: shared.device1.closeConnection())
    }
    
    /// tell device to start streaming
    static func stopStream() {
        var cmd = Constants.STOP_SDBT_COMMAND
        shared.debugText.append("UNIXTIME: \(Date().timeIntervalSince1970)")
        shared.outputResult("stopStream()", res: shared.rfcChannel!.writeSync(&cmd, length: 1))
    }
    
    /// tell device to stop streaming
    static func startStream() {
        var cmd = Constants.START_SDBT_COMMAND
        shared.outputResult("startStream()", res: shared.rfcChannel!.writeSync(&cmd, length: 1))
        shared.debugText.append("UNIXTIME: \(Date().timeIntervalSince1970)")
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4.95) {
//            BluetoothMaster.shared.debugText.append("Stopping after 4.95 seconds...")
//            BluetoothMaster.stopStream()
//        }
    }
    
    // MARK: - Helper methods
    
    /// Appends text to debugText using the given message and IOReturn
    private func outputResult(_ text: String, res: IOReturn) {
        if let ioval = IOReturnValue(res) {
            debugText.append("\(text) returned \(ioval)")
        } else if let btval = BluetoothError(res) {
            debugText.append("\(text) caused a \(btval) bluetooth error")
        } else {
            debugText.append("\(text) resulted in an unkown error (\(res))")
        }
    }
    
    // MARK: - IOBluetoothDeviceAsyncCallbacks
    
    func remoteNameRequestComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        outputResult("Name request", res: status)
    }
    
    func sdpQueryComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        outputResult("SDP Query complete", res: status)
        if status == kIOReturnSuccess {
            debugText.append("Available services:\n**")
            for service in device.services {
                let sdpService = service as! IOBluetoothSDPServiceRecord
                let attrs = (sdpService.sortedAttributes as! [IOBluetoothSDPServiceAttribute])
                debugText.append(sdpService.getServiceName() + ", attributes count: \(attrs.count)")
//                let lcapres = IOReturnValue(sdpService.getL2CAPPSM(l2cappsm))  // NO L2CAP
                let rfcres = sdpService.getRFCOMMChannelID(rfcId)
                outputResult("RFCOMM get channel id", res: rfcres)

//                debugText.append("*")
//                for attr in attrs {
//                    debugText.append("\(attr.getDataElement().getStringValue())")
//                }
//                debugText.append("*")
            }
            debugText.append("**")
            let opRes = device.openRFCOMMChannelSync(&rfcChannel, withChannelID: rfcId.pointee, delegate: unpacker1)
            outputResult("RFCOMM open channel", res: opRes)
        }
    }
    
    func connectionComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        outputResult("\(device.addressString) connection", res: status)
    }
    
    // MARK: - IOBluetoothDeviceInquiryDelegate
    
    func deviceInquiryDeviceFound(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
        let str = "Found addr: \(device.addressString)"
        debugText.append(str)
        if device.addressString == device1mac {
            debugText.append("Found mac \(device1mac) and assigned device 1")
            self.device1 = device
        }
    }
    
    func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        guard device1 != nil else {
            debugText.append("Nil device 1 after inqury, stopping")
            return
        }
        
        debugText.append("Enquiry done, pairing if needed")
        if !device1.isPaired() {
            pairing = IOBluetoothDevicePair(device: device1)
            pairing.delegate = self
            pairing.start()
            debugText.append("Pairing to device 1 started")
        } else {
            debugText.append("Already paired to device 1")
        }
    }
    
    func deviceInquiryStarted(_ sender: IOBluetoothDeviceInquiry!) {
        debugText.append("Enquiry started")
    }
    
    // MARK: - IOBluetoothDevicePairDelegate
    
    func devicePairingStarted(_ sender: Any!) {
        debugText.append("Pairing started")
    }
    
    func devicePairingFinished(_ sender: Any!, error: IOReturn) {
        outputResult("Pairing finished", res: error)
    }
    
    func devicePairingUserPasskeyNotification(_ sender: Any!, passkey: BluetoothPasskey) {
        debugText.append("Pairing passkey notification")
    }
    
    func devicePairingUserConfirmationRequest(_ sender: Any!, numericValue: BluetoothNumericValue) {
        debugText.append("Confirmation request number \(numericValue)")
    }
    
    func devicePairingPINCodeRequest(_ sender: Any!) {
        debugText.append("Pairing received pin request, sending code")
        //        let point: UnsafeMutablePointer<BluetoothPINCode> = UnsafeMutablePointer<BluetoothPINCode>.allocate(capacity: 1)
        //        point.initialize(to: code)
        //        print(point.pointee.data)
        pairing.replyPINCode(4, pinCode: &code)
    }
    
    func devicePairingConnecting(_ sender: Any!) {
        debugText.append("Pairing connecting")
    }
    
    func deviceSimplePairingComplete(_ sender: Any!, status: BluetoothHCIEventStatus) {
        debugText.append("Simple pairing complete: \(status)")
    }
    
    // MARK: - BluetoothUnpackerDelegate
    
    func btUnpacker(receiveTimestamp ts: UInt32) {
        debugText.append("timestamp: \(ts)")
    }
}
