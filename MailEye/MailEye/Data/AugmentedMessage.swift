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

import Cocoa

/// Contains everything that we need to represent a
/// message augmented by behavioural and gaze data.
/// Start and end times of events allow us to time-window
/// addionional physiological data to this message.
struct AugmentedMessage: DiMeData {
    
    // MARK: - Constant fields
    
    /// Type of this structure (useful when exporting)
    var _type: String = "AugmentedMessage"

    /// URL representation of type
    /// It doesn't point to anything but can be used for hierarchical representation of types
    var type: String = "http://www.hiit.fi/ontologies/dime/#AugmentedMessage"

    // MARK: - User tags
    
    /// 1 to 4, if set by user
    private(set) var priority: Int = 0
    
    /// 1 to 4, if set by user
    private(set) var pleasure: Int = 0
    
    /// 1 to 4, if set by user
    private(set) var workload: Int = 0
    
    /// If this message was maked as spam by user
    private(set) var spam: Bool = false
    
    /// If this message was marked as corrupted by the user
    private(set) var corrupted: Bool = false
    
    /// If this message was marked as eagerly expected by user
    private(set) var eagerlyExpected = false
    
    // MARK: - Mailbox-related fields
    
    /// If the message was downloaded as unread from the mailbox
    var wasUnread: Bool
    
    /// String uniquely identifying this message
    var appId: String
    
    /// Content, or hash of content of message's body
    var plainTextContent: String?
    
    /// Subject, or hash of message's subject
    var subject: String
    
    /// Name (if any) or e-mail of sender, or hash of name or e-mail of sender
    let fromString: String
    
    /// Type-representation of sender
    let from: Person?
    
    /// Size of whole body, in view coordinates
    let bodySize: NSSize
    
    /// True if an attachment was present in the mailbox
    let containsAttachment: Bool
    
    /// This corresponds to Message.id
    /// It may be useful to re-reference the original message later.
    /// Commercial applications should not expose this for privacy reasons.
    var id: String

    // MARK: - Data
    
    /// Timestamp when user started working on this message
    let startUnixtime: Int
    
    /// Timestap when user has done working on this message
    var endUnixtime = 0
    
    /// Fixations on body
    var gazes: EyeData = EyeData.empty
    
    /// Fixations on body, before the user started working on this message
    /// (i.e. the user was working on another message, then read this one
    /// before completing the previous)
    var pre_gazes: EyeData?
    
    /// Fixations on body, after the user completed this message.
    var post_gazes: EyeData?
    
    /// Array of start and end times of when the message was displayed on screen
    /// while the user was working on this message.
    var visits: [Event] = [Event]()
    
    /// Then the message was displayed on screen, but before the user
    /// started working on this message.
    var pre_visits: [Event]?
    
    /// Then the message was displayed on screen, after the user
    /// completed work on this message.
    var post_visits: [Event]?
    
    /// Keywords extracted from fixations detected in body, when
    /// the user was working on this message.
    var keywords: [Keyword] = [Keyword]()
    
    /// Keywords extracted from fixations detected in body, before
    /// the user started working on this message.
    var pre_keywords: [Keyword]?
    
    /// Keywords extracted from fixations detected in body, after
    /// the user completed work on this message.
    var post_keywords: [Keyword]?
    
    /// Selections made by user on message's body, when
    /// the user was working on this message.
    var selections: [Selection] = [Selection]()
    
    /// Selections made by user on message's body, before
    /// the user started working on this message.
    var pre_selections: [Selection]?
    
    /// Selections made by user on message's body, after
    /// the user completed work on this message.
    var post_selections: [Selection]?
    
    /// Array of chunks of keyboard activity detected when
    /// the user was working on this message (regardless of whether the window was front or not).
    /// See `KeyboardEventTracker` for more information.
    var keyboardActivity: [Double] = []
    
    /// Array of chunks of mouse movement activity detected when
    /// the user was working on this message (regardless of whether the window was front or not).
    /// See `PointerMovementEventTracker` for more information.
    var pointerActivity: [Double] = []
    
    /// Array of chunks of mouse click activity detected when
    /// the user was working on this message (regardless of whether the window was front or not).
    /// See `PointerClickEventTracker` for more information.
    var clickActivity: [Double] = []
    
    /// Paired to keyboardActivity, references each chunk to timestamps
    var keyboardTimes: [Event] = []
    
    /// Paired to pointerActivity, references each chunk to timestamps
    var pointerTimes: [Event] = []
    
    /// Paired to clickActivity, references each chunk to timestamps
    var clickTimes: [Event] = []
    
    /// Unixtime of when the user first started typing a response in the reply box
    var replyTime = -1

    // MARK: - Convenience
    
    /// Every time HistoryManager.completeAllAugmentedMessages()
    /// is called and this message was updated, a Date() is appended here.
    var dataUpdates: [Date] = []
    
    // MARK: - Coding Keys
    
    // we explicitly need these since we cannot
    // have a field named `@type` in Swift
    
    enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case appId
        case type
        case plainTextContent
        case subject
        case fromString
        case from
        case priority
        case pleasure
        case id
        case workload
        case spam
        case corrupted
        case eagerlyExpected
        case containsAttachment
        case bodySize
        case gazes
        case wasUnread
        case pre_gazes
        case post_gazes
        case startUnixtime
        case endUnixtime
        case dataUpdates
        case visits
        case pre_visits
        case post_visits
        case keywords
        case pre_keywords
        case post_keywords
        case keyboardActivity
        case pointerActivity
        case clickActivity
        case selections
        case pre_selections
        case post_selections
        case replyTime
        case keyboardTimes
        case pointerTimes
        case clickTimes
    }
    
    // MARK: - Init
    
    init(fromMessage message: Message, bodySize: NSSize, preVisits: [Event]?, preGazes: EyeData?, preKeywords: [Keyword]?, preSelections: [Selection]?) {
        let pte: String?
        let subject: String
        let fromString: String
        if AppSingleton.hashEverything {
            pte = nil
            subject = message.subject.md5
            fromString = message.senderName?.md5 ?? message.sender.md5
            self.from = nil
        } else {
            pte = message.body
            subject = message.subject
            fromString = message.senderName ?? message.sender
            if let sn = message.senderName, let p = Person(fromString: sn, email: message.sender) {
                self.from = p
            } else {
                self.from = nil
            }
        }
        
        self.id = message.id
        self.appId = AugmentedMessage.makeAppId(id)
        self.plainTextContent = pte
        self.subject = subject
        self.containsAttachment = message.containsAttachments
        self.fromString = fromString
        self.bodySize = bodySize
        self.pre_visits = preVisits
        self.pre_gazes = preGazes
        self.pre_keywords = preKeywords
        self.pre_selections = preSelections
        self.wasUnread = HistoryManager.originallyUnreadIDs.contains(id)
        startUnixtime = Date().unixTime
    }
        
    mutating func done(_ when: Date) {
        endUnixtime = when.unixTime
    }
    
    mutating func addKeyword(_ kw: Keyword) {
        guard kw.gazeDurations.count == 1 else {
            fatalError("Keyword to add must have only one gaze")
        }
        if let kwi = keywords.index(of: kw) {
            var newkw = keywords[kwi]
            newkw.add(gazeDuration: kw.gazeDurations[0])
            keywords[kwi] = newkw
        } else {
            keywords.append(kw)
        }
    }
    
    /// Sets all user defined tags (fields) and reply time
    mutating func setTags(priority: Int, pleasure: Int, workload: Int, spam: Bool, eager: Bool, corrupted: Bool) {
        self.priority = priority
        self.pleasure = pleasure
        self.workload = workload
        self.spam = spam
        self.eagerlyExpected = eager
        self.corrupted = corrupted
        if let rtime = HistoryManager.replyTimes[id] {
            self.replyTime = rtime
        }
    }
    
    /// Fetches and resets behavioural data. Must be called only once, when definitely done working on this message.
    mutating func fetchBehavioural() {
        (keyboardActivity, keyboardTimes) = HistoryManager.keyboardTracker.reset()
        
        (pointerActivity, pointerTimes) = HistoryManager.pointerMovementTracker.reset()
        
        (clickActivity, clickTimes) = HistoryManager.pointerClickTracker.reset()
    }
}

