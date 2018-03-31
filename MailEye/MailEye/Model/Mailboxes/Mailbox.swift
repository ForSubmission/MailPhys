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
import Cocoa

/// Mailbox is an abstract class that represents a mailbox that can fetch
/// a collection of messages from a source
class Mailbox {
    
    /// All messages in the mbox.
    /// **At init, it must contain nil messages for each possible message:**
    ///
    /// Example:
    /// `self.allMessages = [Message?](repeating: nil, count: nOfItemsInInbox)`
    var allMessages = [Message?]()
    
    /// Indexes message ids to entries in the allMessages array
    var messageIndex = [String: Int]()
     
    /// Message IDs which are unread. Remove items from this set once read.
    private(set) var unreadMessages = Set<String>()
    
    /// Progress done while loading all messages
    let loadingProgress = Progress()
    
    /// Message indices which did not load properly
    var erroneousMessages = [Int]()
    
    /// Replies to messages courrently being composed.
    /// Key is the message id corresponding to the replied-to message.
    /// Once the reply is completed, it should remove itself from here and
    /// save itself to disk.
    private(set) var replies = [(id: String, reply: String)]()
    
    /// A folder in which stuff related to this mailbox should be saved.
    lazy var folder: URL = AppSingleton.mailEyeInDownloads
    
    /// Must be called to initialize the allMessages array, do so once we have a count.
    init(nOfMessages: Int) {
        self.allMessages = [Message?](repeating: nil, count: nOfMessages)
    }
    
    // MARK: - Overridable
    
    /// Saves reply to a given message (also backing it up to disk).
    /// If overridden, should call super.
    func addReply(id: String, reply: String) {
        let prevReply = replies.map({$0}).index(where: {$0.id == id})
        if let i = prevReply {
            replies[i].reply = reply
        } else {
            replies.append((id: id, reply: reply))
        }
        
        NotificationCenter.default.post(name: Constants.repliedMessageNotification, object: nil, userInfo: ["messageId": id, "status": true])
        
        // skip saving if demoing
        guard !HistoryManager.demoing else { return }
        
        DispatchQueue.global(qos: .utility).async {
            [unowned self] in
            do {
                try self.saveReply(id)
            } catch {
                AppSingleton.alertUser("Could not save reply: \(error.localizedDescription)")
            }
        }
    }
    
    /// Removes reply to a given message (does not touch disk).
    /// If overridden, should call super.
    func removeReply(forId id: String) {
        guard let i = replies.index(where: {$0.id == id}) else {
            return
        }
        replies.remove(at: i)
        NotificationCenter.default.post(name: Constants.repliedMessageNotification, object: nil, userInfo: ["messageId": id, "status": false])
    }

    /// Preferred way to mark a message as read.
    /// If overridden, should call super.
    func markAsRead(_ messageId: String) {
        if unreadMessages.contains(messageId) {
            unreadMessages.remove(messageId)
            NotificationCenter.default.post(name: Constants.readMessageNotification, object: nil, userInfo: ["messageId": messageId])
        }
    }
    
    /// Preferred way to set a message as unread.
    /// If overridden, should call super.
    func markAsUnread(_ messageId: String) {
        unreadMessages.insert(messageId)
    }
    
    // MARK: - Stubs
    
    /// Given an index, should load a message and return it.
    /// Message 0 will be at top of the list, allMessages.count at the bottom
    func fetchMessage(atIndex: Int) throws -> Message {
        fatalError("fetchMessage must be overridden in subclass")
    }
    
    /// Given an index, this should return full contents for a message
    func fetchFullContents(atIndex: Int) throws -> String? {
        fatalError("fetchFullContents must be overridden in subclass")
    }

}
