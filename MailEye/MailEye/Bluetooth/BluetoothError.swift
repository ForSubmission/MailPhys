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

///Bluetooth error codes. From http://www.btnode.ethz.ch/static_docs/doxygen/btnut/group__Bt__Error__Codes.html
enum BluetoothError: String {
    case UnknownHCICommand
    case NoConnection
    case HardwareFailure
    case PageTimeout
    case AuthenticationFailure
    case KeyMissing
    case MemoryFull
    case ConnectionTimeout
    case MaxNumberOfConnections
    case MaxNumberOfSCOConnectionsToADevice
    case ACLconnectionalreadyexists
    case CommandDisallowed
    case HostRejectedduetolimitedresources
    case HostRejectedduetosecurityreasons
    case HostRejectedduetoremotedeviceisonlyapersonaldevice
    case HostTimeout
    case UnsupportedFeatureorParameterValue
    case InvalidHCICommandParameters
    case OtherEndTerminatedConnectionUserEndedConnection
    case OtherEndTerminatedConnectionLowResources
    case OtherEndTerminatedConnectionAbouttoPowerOff
    case ConnectionTerminatedbyLocalHost
    case RepeatedAttempts
    case PairingNotAllowed
    case UnknownLMPPDU
    case UnsupportedRemoteFeature
    case SCOOffsetRejected
    case SCOIntervalRejected
    case SCOAirModeRejected
    case InvalidLMPParameters
    case UnspecifiedError
    case UnsupportedLMPParameterValue
    case RoleChangeNotAllowed
    case LMPResponseTimeout
    case LMPErrorTransactionCollision
    case LMPPDUNotAllowed
    case EncryptionModeNotAcceptable
    case UnitKeyUsed
    case QoSisNotSupported
    case InstantPassed
    case PairingwithUnitKeyNotSupported
    
    /// Initializes from a return value (Int32, which should be an alias for IOReturn).
    /// Returns nil if there's no match.
    init?(_ val: Int32 ) {
        switch val {
        case 0x01:
            self = .UnknownHCICommand
        case 0x02:
            self = .NoConnection
        case 0x03:
            self = .HardwareFailure
        case 0x04:
            self = .PageTimeout
        case 0x05:
            self = .AuthenticationFailure
        case 0x06:
            self = .KeyMissing
        case 0x07:
            self = .MemoryFull
        case 0x08:
            self = .ConnectionTimeout
        case 0x09:
            self = .MaxNumberOfConnections
        case 0x0A:
            self = .MaxNumberOfSCOConnectionsToADevice
        case 0x0B:
            self = .ACLconnectionalreadyexists
        case 0x0C:
            self = .CommandDisallowed
        case 0x0D:
            self = .HostRejectedduetolimitedresources
        case 0x0E:
            self = .HostRejectedduetosecurityreasons
        case 0x0F:
            self = .HostRejectedduetoremotedeviceisonlyapersonaldevice
        case 0x10:
            self = .HostTimeout
        case 0x11:
            self = .UnsupportedFeatureorParameterValue
        case 0x12:
            self = .InvalidHCICommandParameters
        case 0x13:
            self = .OtherEndTerminatedConnectionUserEndedConnection
        case 0x14:
            self = .OtherEndTerminatedConnectionLowResources
        case 0x15:
            self = .OtherEndTerminatedConnectionAbouttoPowerOff
        case 0x16:
            self = .ConnectionTerminatedbyLocalHost
        case 0x17:
            self = .RepeatedAttempts
        case 0x18:
            self = .PairingNotAllowed
        case 0x19:
            self = .UnknownLMPPDU
        case 0x1A:
            self = .UnsupportedRemoteFeature
        case 0x1B:
            self = .SCOOffsetRejected
        case 0x1C:
            self = .SCOIntervalRejected
        case 0x1D:
            self = .SCOAirModeRejected
        case 0x1E:
            self = .InvalidLMPParameters
        case 0x1F:
            self = .UnspecifiedError
        case 0x20:
            self = .UnsupportedLMPParameterValue
        case 0x21:
            self = .RoleChangeNotAllowed
        case 0x22:
            self = .LMPResponseTimeout
        case 0x23:
            self = .LMPErrorTransactionCollision
        case 0x24:
            self = .LMPPDUNotAllowed
        case 0x25:
            self = .EncryptionModeNotAcceptable
        case 0x26:
            self = .UnitKeyUsed
        case 0x27:
            self = .QoSisNotSupported
        case 0x28:
            self = .InstantPassed
        case 0x29:
            self = .PairingwithUnitKeyNotSupported
        // 0x2A-0xFF Reserved for Future Use.
        default:
            return nil
        }
    }
}
