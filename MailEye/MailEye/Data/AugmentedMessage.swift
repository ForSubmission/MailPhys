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

/// Facilitates conversion to the internal Message class to a struct
/// that can be submitted to DiMe
struct AugmentedMessage: DiMeData {
    
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
    
    // MARK: - User tags
    
    /// 1 to 4 when set
    private(set) var priority: Int = 0
    
    /// 1 to 4 when set
    private(set) var pleasure: Int = 0
    
    /// 1 to 4 when set
    private(set) var workload: Int = 0
    
    /// If this message was maked as spam by user
    private(set) var spam: Bool = false
    
    /// If this message was marked as corrupted by the user
    private(set) var corrupted: Bool = false
    
    /// If this message was marked as eagerly expected by user
    private(set) var eagerlyExpected = false
    
    // MARK: - Other fields
    
    /// Every time HistoryManager.completeAllAugmentedMessages()
    /// is called and this message was updated, a Date() is appended here.
    var dataUpdates: [Date] = []
    
    /// If the message was downloaded as unread from the mailbox
    var wasUnread: Bool
    
    var appId: String
    
    var _type: String = "AugmentedMessage"
    
    var type: String = "http://www.hiit.fi/ontologies/dime/#AugmentedMessage"
    
    var plainTextContent: String?
    
    var subject: String
    
    let fromString: String
    
    let from: Person?
    
    let bodySize: NSSize
    
    let containsAttachment: Bool
    
    /// This corresponds to Message.id
    /// It may be useful to re-reference the original message later.
    /// Commercial applications should not expose this for privacy reasons.
    var id: String
    
    let startUnixtime: Int
    
    var endUnixtime = 0
    
    var gazes: EyeData = EyeData.empty
    
    var pre_gazes: EyeData?
    
    var post_gazes: EyeData?
    
    var visits: [Event] = [Event]()
    
    var pre_visits: [Event]?
    
    var post_visits: [Event]?
    
    var keywords: [Keyword] = [Keyword]()
    
    var pre_keywords: [Keyword]?
    
    var post_keywords: [Keyword]?
    
    var selections: [Selection] = [Selection]()
    
    var pre_selections: [Selection]?
    
    var post_selections: [Selection]?
    
    var keyboardActivity: [Double] = []
    
    var pointerActivity: [Double] = []
    
    var clickActivity: [Double] = []
    
    /// two ints representing start and end times of keyboard events
    var keyboardTimes: [Event] = []
    
    /// two ints representing start and end times of pointer events
    var pointerTimes: [Event] = []
    
    /// two ints representing start and end times of click events
    var clickTimes: [Event] = []
    
    /// Unixtime of when the user first started typing a response in the reply box
    var replyTime = -1
    
    //    let toString: String
    //
    //    let to: [Person]
    //
    //    let ccString: String
    //
    //    let cc: [Person]
    
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

