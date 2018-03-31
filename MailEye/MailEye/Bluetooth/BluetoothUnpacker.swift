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

/// Receives unpacked bluetooth data
@objc protocol BluetoothUnpackerDelegate: class {
    func btUnpacker(receiveTimestamp: UInt32)
}

/// The unpacker is a RFCOMM channel delegate that tells its own delegate every
/// time a new timestamp has been found in the channel (so that data can be
/// synchronized later)
class BluetoothUnpacker: NSObject, IOBluetoothRFCOMMChannelDelegate {
    
    // MARK: - Properties
    
    /// Delegate that receives timestamps
    weak var delegate: BluetoothUnpackerDelegate?
    
    // MARK: - Private properties
    
    /// Maximum timestamp index (2 since we can have 3 bytes for timestamp)
    private let maxI = 2
    
    /// The timestamp buffer contains three bytes, sequentially set as soon as a
    /// value of 0 (signaling data start) is found in the incoming data.
    /// This is because the three bytes immediately following 0 in the incoming data
    /// are the timestamp.
    private var tsBuffer: [UInt8] = [UInt8](repeating: 0, count: 3)
    
    /// The timestamp index points to 0 if 0 has been found in the incoming data,
    /// and is increased by 1 every subsequent byte. Once this reaches 2, the
    /// tsBuffer is converted into an UInt32 and sent to the delegate.
    private var tsIndex = 999
    
    // MARK: - Private methods
    
    /// Converts the timestamp buffer into a UInt32 and sends it to the delegate
    func sendTsBuffer() {
        guard let delegate = self.delegate else {
            return
        }
        
        // assuming big endian
        let ts: UInt32 = (UInt32(tsBuffer[0]) << 0) |
                         (UInt32(tsBuffer[1]) << 8) |
                         (UInt32(tsBuffer[2]) << 16)
        delegate.btUnpacker(receiveTimestamp: ts)
    }
    
    // MARK: - IOBluetoothRFCOMMChannelDelegate
    
    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        let data = Data(bytes: dataPointer, count: dataLength)
        for d in data {
            // if 0, point at start of buffer. If not, set to buffer if tsIndex <= max
            if d == 0 {
                tsIndex = 0
            } else if tsIndex <= maxI {
                tsBuffer[tsIndex] = d
                if tsIndex == 2 {
                    sendTsBuffer()
                }
                tsIndex += 1
            }
        }
    }
    
    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
    }

    func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
    }

}
