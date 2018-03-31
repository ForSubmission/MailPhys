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
import os.log

/// Represents a mailbox fetched from a remote imap server using curl
class CurlBox: Mailbox {
        
    // MARK: - Private fields
    
    /// Maps message IDs to uid in the imap server
    var uidIndex = [String: Int]()
    
    /// Message UIDs which are maked as unseen by server on
    /// first connect are kept here.
    private(set) var unreadUids: [Int]
    
    /// The UIDs in the "recent" past, in descending order
    let recentUIDs: [Int]
    
    /// A set of UIDs which have been flagged on server.
    /// These won't be touched.
    let flaggedOnServer: Set<Int>
    
    let serverDetails: ServerDetails
    
    // MARK: - Init
    
    init?(serverDetails: ServerDetails) throws {
        
        self.serverDetails = serverDetails
        
        guard let serverInfo = try CurlWrapper.getInfo(serverDetails: serverDetails) else {
            return nil
        }
        
        // serverInfo.msgCount is unused, recentUIDs is used instead
        
        self.unreadUids = serverInfo.unread
        
        self.recentUIDs = try CurlWrapper.getUIDs(serverDetails).reversed()
        
        self.flaggedOnServer = try Set(CurlWrapper.getUIDs(serverDetails, flag: .flagged))
        
        // ready
        super.init(nOfMessages: recentUIDs.count)
    }
    
    // MARK: - Private methods

    /// Sets a flag to the given value for the given message id.
    func setFlag(_ flag: CurlWrapper.Flag, to: Bool = true, messageId: String) {
        // convert id to uid
        guard let uid = uidIndex[messageId] else {
            if #available(OSX 10.12, *) {
                os_log("Failed to find uid for id: %@", type: .error, messageId)
            }
            return
        }
        let serverDetails = self.serverDetails
        DispatchQueue.global(qos: .utility).async {
            // attempt mark as read
            do {
                try CurlWrapper.setFlag(flag, to: to, uid: uid, serverDetails: serverDetails)
            } catch {
                if #available(OSX 10.12, *) {
                    os_log("Failed to set message as read: %@", type: .error, error.localizedDescription)
                }
            }
        }
    }

    /// Sets the "Flagged" flag to the given value only if the message
    /// was not flagged on server and the given preference is set.
    func conditionallySetFlagged(messageId: String, flagged: Bool) {
        guard self.serverDetails.flagReplied else {
            return
        }
        
        guard let uid = uidIndex[messageId] else {
            if #available(OSX 10.12, *) {
                os_log("Failed to find uid for: %@", type: .error, messageId)
            }
            return
        }
        
        guard !flaggedOnServer.contains(uid) else { return }
        
        let serverDetails = self.serverDetails
        DispatchQueue.global(qos: .utility).async {
            do {
                try CurlWrapper.setFlag(.flagged, to: flagged, uid: uid, serverDetails: serverDetails)
            } catch {
                if #available(OSX 10.12, *) {
                    os_log("Failed to set message as read: %@", type: .error, error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Overridden methods
    
    override func fetchFullContents(atIndex: Int) throws -> String? {
        return try CurlMessage(serverDetails: self.serverDetails, uid: atIndex + 1)?.fullContents
    }
    
    override func fetchMessage(atIndex: Int) throws -> Message {
        let uid = recentUIDs[atIndex]
        let isUnread = self.unreadUids.contains(uid)
        guard let curlMessage = try CurlMessage(serverDetails: self.serverDetails, uid: uid, resetRead: isUnread) else {
            throw Message.Error.curlFail
        }
        let message = try Message(fromCurlMessage: curlMessage)
        uidIndex[message.id] = uid
        // we set read back to its original state, since when we download
        // curl sets seen automatically
        if isUnread {
            markAsUnread(message.id)
            HistoryManager.originallyUnreadIDs.insert(message.id)
        }
        return message
    }
    
    override func markAsRead(_ messageId: String) {
        // we set read on server first, then super will set internal unreadmessages
        if !serverDetails.dontTouchUnread && unreadMessages.contains(messageId) {
            setFlag(.seen, messageId: messageId)
        }
        super.markAsRead(messageId)
    }
    
    override func addReply(id: String, reply: String) {
        super.addReply(id: id, reply: reply)
        conditionallySetFlagged(messageId: id, flagged: true)
    }
    
    override func removeReply(forId id: String) {
        super.removeReply(forId: id)
        conditionallySetFlagged(messageId: id, flagged: false)
    }
    
}
