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

/// Enum wrapper for IOReturn codes
enum IOReturnValue: String {
    case aborted
    case badArgument
    case badMedia
    case badMessageID
    case busy
    case cannotLock
    case cannotWire
    case deviceError
    case dmaError
    case error
    case exclusiveAccess
    case internalError
    case invalid
    case ioerror
    case ipcError
    case isoTooNew
    case isoTooOld
    case lockedRead
    case lockedWrite
    case messageTooLarge
    case noBandwidth
    case noChannels
    case noCompletion
    case noDevice
    case noFrames
    case noInterrupt
    case noMedia
    case noMemory
    case noPower
    case noResources
    case noSpace
    case notAligned
    case notAttached
    case notFound
    case notOpen
    case notPermitted
    case notPrivileged
    case notReadable
    case notReady
    case notResponding
    case notWritable
    case offline
    case overrun
    case portExists
    case rlderror
    case stillOpen
    case success
    case timeout
    case underrun
    case unformattedMedia
    case unsupported
    case unsupportedMode
    case vmError
    
    /// Initializes using the kernel contants.
    /// Returns nil if there's no match.
    init?(_ fromIOReturn: IOReturn) {
        switch fromIOReturn {
            
            case kIOReturnAborted:
                self = .aborted
            case kIOReturnBadArgument:
                self = .badArgument
            case kIOReturnBadMedia:
                self = .badMedia
            case kIOReturnBadMessageID:
                self = .badMessageID
            case kIOReturnBusy:
                self = .busy
            case kIOReturnCannotLock:
                self = .cannotLock
            case kIOReturnCannotWire:
                self = .cannotWire
            case kIOReturnDeviceError:
                self = .deviceError
            case kIOReturnDMAError:
                self = .dmaError
            case kIOReturnError:
                self = .error
            case kIOReturnExclusiveAccess:
                self = .exclusiveAccess
            case kIOReturnInternalError:
                self = .internalError
            case kIOReturnInvalid:
                self = .invalid
            case kIOReturnIOError:
                self = .ioerror
            case kIOReturnIPCError:
                self = .ipcError
            case kIOReturnIsoTooNew:
                self = .isoTooNew
            case kIOReturnIsoTooOld:
                self = .isoTooOld
            case kIOReturnLockedRead:
                self = .lockedRead
            case kIOReturnLockedWrite:
                self = .lockedWrite
            case kIOReturnMessageTooLarge:
                self = .messageTooLarge
            case kIOReturnNoBandwidth:
                self = .noBandwidth
            case kIOReturnNoChannels:
                self = .noChannels
            case kIOReturnNoCompletion:
                self = .noCompletion
            case kIOReturnNoDevice:
                self = .noDevice
            case kIOReturnNoFrames:
                self = .noFrames
            case kIOReturnNoInterrupt:
                self = .noInterrupt
            case kIOReturnNoMedia:
                self = .noMedia
            case kIOReturnNoMemory:
                self = .noMemory
            case kIOReturnNoPower:
                self = .noPower
            case kIOReturnNoResources:
                self = .noResources
            case kIOReturnNoSpace:
                self = .noSpace
            case kIOReturnNotAligned:
                self = .notAligned
            case kIOReturnNotAttached:
                self = .notAttached
            case kIOReturnNotFound:
                self = .notFound
            case kIOReturnNotOpen:
                self = .notOpen
            case kIOReturnNotPermitted:
                self = .notPermitted
            case kIOReturnNotPrivileged:
                self = .notPrivileged
            case kIOReturnNotReadable:
                self = .notReadable
            case kIOReturnNotReady:
                self = .notReady
            case kIOReturnNotResponding:
                self = .notResponding
            case kIOReturnNotWritable:
                self = .notWritable
            case kIOReturnOffline:
                self = .offline
            case kIOReturnOverrun:
                self = .overrun
            case kIOReturnPortExists:
                self = .portExists
            case kIOReturnRLDError:
                self = .rlderror
            case kIOReturnStillOpen:
                self = .stillOpen
            case 0:
                self = .success
            case kIOReturnTimeout:
                self = .timeout
            case kIOReturnUnderrun:
                self = .underrun
            case kIOReturnUnformattedMedia:
                self = .unformattedMedia
            case kIOReturnUnsupported:
                self = .unsupported
            case kIOReturnUnsupportedMode:
                self = .unsupportedMode
            case kIOReturnVMError:
                self = .vmError

        default:
            return nil
        }
    }
}
