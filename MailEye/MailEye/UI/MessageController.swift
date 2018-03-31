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

/// Represents an individual message. Manages a stack view of all paragraphs.
class MessageController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSTextViewDelegate, NSLayoutManagerDelegate, MessageReferenceView {
    
    var correspondingMessageId: String? { get {
        return messageId
    }}

    static let itemNib = NSNib(nibNamed: NSNib.Name(rawValue: "ThreadItemView"), bundle: Bundle.main)

    @IBOutlet weak var headerView: ReferenceView!
    @IBOutlet weak var doneTick: NSTextField!
    @IBOutlet weak var senderLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var subjectLabel: NSTextField!
    @IBOutlet weak var workingOnLabel: NSTextField!
    @IBOutlet weak var bodyScrollView: NSScrollView!
    
    @IBOutlet weak var threadCollectionView: ThreadCollectionView!
    
    /// When we start selecting text
    var selectionStartTime: Date?
    
    /// When we end selecting text
    var selectionEndTime: Date?
    
    /// If we are ready to parse message keywords
    var ready = false
    
    // Temporarily stores the reply controller for the current message,
    // until a new message is selected
    weak var currentReplyController: ReplyController?
    
    weak var mailbox: Mailbox? { get {
        return (parent as! MailboxController).representedObject as? Mailbox
    } }
    
    @IBOutlet var bodyView: BodyView!
    @IBOutlet weak var myOverlay: MyOverlay!
    
    var messageId: String? { didSet {
        if oldValue ?? "" != self.messageId ?? "" {
            self.currentReplyController = nil
        }
    } }
    
    var thread: [Message]? { didSet {
        DispatchQueue.main.async {
            self.threadCollectionView.reloadData()
        }
    } }
    
    // MARK: - Internal functions
    
    func messageSelected(_ num: Int, refreshThread: Bool = true) {
        self.ready = false
        
        guard let mailboxController = self.parent as? MailboxController else {
            return
        }
        
        guard let mb = mailbox, num >= 0, let currentMessage = mb.allMessages[num] else {
            mailboxController.tempWorkMessageIndex = -1
            return
        }
        
        // tell history manager to start recording
        mailboxController.entered(nil)
        
        // work on this message if it wasn't done already and current work is empty
        if HistoryManager.currentWork == nil && !HistoryManager.doneMessages.contains(currentMessage.id) {
            mailboxController.tempWorkMessageIndex = num
        } else {
            mailboxController.tempWorkMessageIndex = -1
        }
        
        // update current visit
        HistoryManager.currentVisitId = currentMessage.id
        
        mb.markAsRead(currentMessage.id)
        headerView.correspondingMessageId = currentMessage.id
        bodyView.correspondingMessageId = currentMessage.id
        
        self.dateLabel.stringValue = AppSingleton.userDateFormatter.string(from: currentMessage.date)
        if let senderName = currentMessage.senderName {
            self.senderLabel.stringValue = senderName
        } else {
            self.senderLabel.stringValue = currentMessage.sender
        }
        self.subjectLabel.stringValue = currentMessage.subject
        self.messageId = currentMessage.id
        let body = currentMessage.body
        let font = NSFont(name: "Helvetica", size: 16)!
        let attributes = [NSAttributedStringKey.font: font]
        let attrString = NSAttributedString(string: body, attributes: attributes)
        
        if refreshThread {
            self.thread = mb.getThread(forMessage: currentMessage)
        }
        
        DispatchQueue.main.async {
            self.doneTick?.isHidden = !HistoryManager.doneMessages.contains(currentMessage.id)
            self.bodyView.isHidden = true
            self.bodyView.setSelectedRange(NSRange(location: 0, length: 0))
            let textStorage = NSTextStorage(attributedString: attrString)
            self.bodyView?.layoutManager?.replaceTextStorage(textStorage)
            
            if let tc = self.bodyView.textContainer {
                self.bodyView?.layoutManager?.ensureLayout(for: tc)
            }
        }
    }
    
    @objc func messageDone(notification: Notification?) {
        guard let uinfo = notification?.userInfo,
            let id = uinfo["messageId"] as? String else {
                return
        }
        
        if id == messageId ?? "" {
            DispatchQueue.main.async {
                [unowned self] in
                self.doneTick.isHidden = false
            }
        }
        
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // collection view
        self.threadCollectionView.register(MessageController.itemNib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThreadItemView"))
        self.threadCollectionView.dataSource = self
        self.threadCollectionView.delegate = self
        self.bodyView.delegate = self
        self.bodyView.layoutManager?.delegate = self
        
        // redirect overlay events
        self.myOverlay.otherView = bodyScrollView

        NotificationCenter.default.addObserver(self, selector: #selector(messageDone(notification:)), name: Constants.doneMessageNotification, object: nil)
        
    }

    // MARK: - Segues
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let messageId = self.messageId else {
            return
        }
        
        if identifier.rawValue == "messageDone",
           let tvc = segue.destinationController as? TagViewController {
                // tag segue
                tvc.mailbox = self.mailbox
                tvc.messageId = messageId
        } else if identifier.rawValue == "composeReply",
            let rpc = segue.destinationController as? ReplyController {
                // reply segue
                currentReplyController = rpc
                rpc.replyToId = messageId
                // set mailbox after id
                rpc.mailbox = self.mailbox
                rpc.view.window?.makeKeyAndOrderFront(self)
        }
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: NSStoryboardSegue.Identifier, sender: Any?) -> Bool {
        
        // do not perform the segue if the controller already exists,
        // show it instead
        if identifier.rawValue == "composeReply" {
            if let crc = self.currentReplyController, let crcwin = crc.view.window {
                DispatchQueue.main.async {
                    [unowned self] in
                    crcwin.makeKeyAndOrderFront(self)
                }
            }
            return currentReplyController == nil
        } else {
            return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
        }
        
    }
    
    /// Returns a set of keywords related to the given point
    /// in body view coordinates.
    /// Returns nil if view is not ready
    func detectKeywords(forPointInBody pointInBody: NSPoint) -> Set<String>? {
        
        guard self.ready, HistoryManager.currentController != nil else { return nil }
        
        var splitSet: CharacterSet = .whitespacesAndNewlines
        splitSet.formUnion(.punctuationCharacters)
        
        guard let bodyView = self.bodyView, self.ready else {
                return nil
        }
        
        let maybeLayoutManager = bodyView.layoutManager
        let textStorage = bodyView.textStorage
        
        guard NSPointInRect(pointInBody, bodyView.visibleRect) else {
            return nil
        }
        
        let seenRect = getSeenRect(fromPoint: pointInBody, zoomLevel: Constants.eyeZoom)
        
        // In order to select the ranges that our rectangle encompasses, we first get a range of glyphs that starts in top left of our rect and ends bottom right.
        
        let startPoint = NSPoint(x: seenRect.minX, y: seenRect.minY)
        let endPoint = NSPoint(x: seenRect.maxX, y: seenRect.maxY)
        
        guard let textContainer = bodyView.textContainer else {
            return nil
        }
        
        guard let startGlyph = maybeLayoutManager?.glyphIndex(for: startPoint, in: textContainer, fractionOfDistanceThroughGlyph: nil),
              let endGlyph = maybeLayoutManager?.glyphIndex(for: endPoint, in: textContainer, fractionOfDistanceThroughGlyph: nil) else {
            return nil
        }
        
        // check that the result contains something
        guard endGlyph - startGlyph > 0 else {
            return nil
        }
        
        // outerRange is everything from start to end of rect, must
        // intersect this with line fragments to get what the user actually saw
        let outerRange = NSRange(location: startGlyph, length: endGlyph - startGlyph)
        
        // intersection between seen range and line fragments.
        // may contain partial words
        var sawFragments = [NSRange]()
        
        guard let layoutManager = maybeLayoutManager else {
            return nil
        }
        
        guard self.ready, HistoryManager.currentController != nil else { return nil }
        
        layoutManager.enumerateLineFragments(forGlyphRange: outerRange) {
            [weak self]
            
            _, rect, _, _, _ in
            
            if rect.intersects(seenRect), self?.ready ?? false, HistoryManager.currentController != nil {
                // For each intersection, we select the range that is between the midY edges
                let intersection = rect.intersection(seenRect)
                
                let innerStart = NSPoint(x: intersection.minX, y: intersection.midY)
                let innerEnd = NSPoint(x: intersection.maxX, y: intersection.midY)
                
                let innerStartChar = layoutManager.characterIndex(for: innerStart, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
                let innerEndChar = layoutManager.characterIndex(for: innerEnd, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
                
                // skip singleton or invalid line fragments
                if innerEndChar > innerStartChar {
                    let newRange = NSRange(location: innerStartChar, length: innerEndChar - innerStartChar)
                    sawFragments.append(newRange)
                }
            }
        }
        
        guard self.ready, HistoryManager.currentController != nil else { return nil }
        
        // combine all words in saw fragments in one array, filtering anything <= 2 characters of length
        var fragmentedWords = [String]()
        sawFragments.forEach() {
            if let substring = textStorage?.string.substring(nsRange: $0) {
                let a = String(substring).components(separatedBy: splitSet)
                fragmentedWords.append(contentsOf: a.filter({$0.count > 2 && $0 != ""}))
            }
        }
        
        guard self.ready, HistoryManager.currentController != nil else { return nil }
        
        // to remove word fragments, in sawFragments get the bounding rect of everything that touched our rect, and get all words in that
        
        let boundGlyphRange = layoutManager.glyphRange(forBoundingRectWithoutAdditionalLayout: seenRect, in: textContainer)
        let boundCharRange = layoutManager.characterRange(forGlyphRange: boundGlyphRange, actualGlyphRange: nil)
        
        guard let substring = textStorage?.string.substring(nsRange: boundCharRange) else {
            return nil
        }
        
        let boundWords = String(substring).components(separatedBy: splitSet)
        
        // intersect to get seen words
        let seenWords = boundWords.orderedIntersection(subset: fragmentedWords)
        
        // get a word set using lowercase only
        let wordset = Set<String>(seenWords.map({$0.lowercased()}))
        
        // remove stopwords
        let keywords = wordset.subtracting(AppSingleton.stopWords)
        
        if keywords.count > 0 {
            return keywords
        } else {
            return nil
        }
        
    }
    
    // MARK: - Collection data source
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return thread?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let it = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThreadItemView"), for: indexPath) as! ThreadItemView
        it.updateValues(fromMessage: thread![indexPath.item])
        return it
    }
    
    // MARK: - Collection view delegate
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        for ip in indexPaths {
            (collectionView.item(at: ip) as? ThreadItemView)?.setSelected(selected: true)
            if let refId = (collectionView.item(at: ip) as? ThreadItemView)?.referencedId {
                let uInfo: [String: Any] = ["messageId": refId]
                NotificationCenter.default.post(name: Constants.selectMessageNotification, object: self, userInfo: uInfo)
            }
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        for ip in indexPaths {
            (collectionView.item(at: ip) as? ThreadItemView)?.setSelected(selected: false)
        }
    }
    
    // MARK: - Text view delegate
    
    func textViewDidChangeSelection(_ notification: Notification) {
        if bodyView.selectedRanges.count == 1,
          let msgId = self.messageId,
          bodyView.selectedRanges[0].rangeValue.length > 0 {
            let sel = Selection(endTime: Date().unixTime, nOfCharacters: bodyView.selectedRanges[0].rangeValue.length)
            HistoryManager.selectedText(msgId: msgId, selection: sel)
        }
    }
    
    // MARK: - Layout manager delegate
    
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        if layoutFinishedFlag {
            DispatchQueue.main.async {
                self.bodyView?.needsDisplay = true
                self.bodyView?.isHidden = false
                self.ready = true
            }
        }
    }

}
