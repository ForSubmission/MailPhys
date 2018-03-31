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
import Cocoa

class Constants {
    
    /// Identifies a failed message (Message.id == "failed")
    static let failedMessageId = "failed"
    
    /// If we want to use DiMe
    static let useDime = false
    
    /// Default zoom level for eye-tracking keywords
    static let eyeZoom: CGFloat = 0.5
    
    /// How much time must pass before we automatically assume the user is working on the message they select on the left table
    static let workTime: TimeInterval = 0.5
    
    /// How many recent imap servers do we store
    static let recentImapsMaxNum = 15
    
    /// Gets appended to imap usernames for that server
    static let imapUsernameAppendages: [String: String] = ["outlook.office365.com": "@ad.helsinki.fi"]
    
    // MARK: - Shimmer bluetooth commands
    
    static let START_STREAMING_COMMAND: UInt8 = 0x07
    static let STOP_STREAMING_COMMAND: UInt8 = 0x20
    static let START_SDBT_COMMAND: UInt8 = 0x70
    static let STOP_SDBT_COMMAND: UInt8 = 0x97
    
    // MARK: - View identifiers
    
    static let headerViewIdentifier = NSUserInterfaceItemIdentifier(rawValue: "headerView")
    static let referenceViewIdentifier = NSUserInterfaceItemIdentifier(rawValue: "referenceView")
    static let threadViewIdentifier = NSUserInterfaceItemIdentifier(rawValue: "MailboxCell")
    static let bodyViewIdentifier = NSUserInterfaceItemIdentifier(rawValue: "bodyView")
    
    static let targetIdentifiers = [headerViewIdentifier, referenceViewIdentifier, threadViewIdentifier, bodyViewIdentifier]
    
    // MARK: - Debug
    
    static let showDebugController = false

    // MARK: - Notifications
    
    /// A message was selected
    /// Userinfo:
    /// - `messageId` should return a string pointing
    /// to the id of the selected message
    /// - `tableSelect` (optional) a bool. If true, the main thread table should show that this message was selected.
    static let selectMessageNotification = Notification.Name("anon.forsubmission.selectMessageNotification")
    
    /// A message was marked as done
    /// userInfo: ["messageId"] returns the string pointing to the message which is done
    static let doneMessageNotification = Notification.Name("anon.forsubmission.doneMessageNotification")
    
    /// A message was marked as read
    /// userInfo: ["messageId"] returns the string pointing to the message which has been read
    static let readMessageNotification = Notification.Name("anon.forsubmission.readMessageNotification")
    
    /// A message was marked as replied
    /// userInfo: ["messageId"] returns the string pointing to the message which has been replied
    ///           ["status"] returns a bool indicating whether it should be marked or unmarked
    static let repliedMessageNotification = Notification.Name("anon.forsubmission.repliedMessageNotification")
    
    /// String notifying that something changed in the dime connection.
    ///
    /// **UserInfo dictionary fields**:
    ///
    /// - "available": Boolean, true if dime went up, false if down
    static let diMeConnectionNotification = Notification.Name("anon.forsubmission.diMeConnectionChange")

    // MARK: - UserDefaults keys
    
    static let kDiMeServerURL = "dime.serverinfo.url"
    static let kDiMeServerUserName = "dime.serverinfo.userName"
    static let kDiMeServerPassword = "dime.serverinfo.password"
    static let kUsername = "server.username"
    static let kServer = "server.address"
    static let kSinceDate = "server.sinceDate"
    static let kFlagRepliedMessages = "server.flagReplied"
    static let kDoNotCommunicateReadMessages = "server.doNotCommunicateReadMessages"
    static let kRecentImaps = "server.recent.imap"
    static let defaultSinceDate: Date = {
        // default since date is 3 months ago
        let sinceSeconds: TimeInterval = 3.0 * 30.0 * 24.0 * 60.0 * 60.0
        let defaultSinceDate = Date().addingTimeInterval(-sinceSeconds)
        return defaultSinceDate
    }()
    
    enum Error: Swift.Error, LocalizedError {
        
        var errorDescription: String? { get {
            switch self {
            case .sortFail:
                return NSLocalizedString("Could not sort messages", comment: "Could not sort messages using the menu")
            }
            }}
        
        case sortFail
    }
    
}
