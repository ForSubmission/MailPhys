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

/// The HistoryManager stores all data for the current session,
/// outputs it at the end of the experiment. It also links a windows
/// to the eye tracker.
class HistoryManager: FixationDataDelegate {
    
    /// Returns a shared instance of this class. This is the designed way of accessing the history manager.
    static let sharedManager = HistoryManager()
    
    /// The timer that fires when we assume that the user starts reading. Pass the MailboxController as the userInfo object.
    fileprivate var entryTimer: Timer?
    
    /// The timer that fires after a certain amount of time passed, and generates an "exit event"
    fileprivate var exitTimer: Timer?
    
    /// The GCD queue in which all timers are created / destroyed (to prevent potential memory leaks, they all run here)
    fileprivate let timerQueue = DispatchQueue(label: "hiit.MailEye.HistoryManager.timerQueue", attributes: [])
    
    /// Eye tracking events are converted / sent to dime on this queue, to avoid conflicts
    /// between exit events and fixation receipt events
    fileprivate let eyeQueue = DispatchQueue(label: "hiit.MailEye.HistoryManager.eyeQueue", attributes: [])
    
    /// Queue on which static tracking fields are changed to prevent conflicts
    fileprivate static let storeQueue = DispatchQueue(label: "hiit.MailEye.HistoryManager.storeQueue", attributes: [])
    
    // MARK: - Behavioural trackers
    
    static let pointerMovementTracker = PointerMovementEventTracker()
    
    static let pointerClickTracker = PointerClickEventTracker()
    
    static let keyboardTracker = KeyboardEventTracker()

    // MARK: - Public tracking fields
    
    /// Unread message IDs should be stored here. Only add them here (so that we know which were unread), do not remove them.
    static var originallyUnreadIDs = Set<String>()
    
    /// Message IDs which are done. The IDs for which the user completes all tags are added here.
    static var doneMessages = Set<String>()
    
    /// Message IDs which were marked as corrupted by the user.
    static var corruptedMessages = Set<String>()
    
    /// When a user types some text in the reply box, the id of the message gets added here as a key and the unixtime gets added as a value
    static var replyTimes = [String: Int]()
    
    /// If true, we are doing a demo, hence nothing should be stored
    static var demoing = false { didSet {
        // if demo is being stopped, clear stores
        if oldValue && !demoing {
            resetFields()
        }
    } }
    
    /// If true, events are not recorded.
    /// Sends exit event on change
    static var paused: Bool = false { willSet {
        if let currentController = currentController {
            HistoryManager.entry(currentController)
        }
    } }
    
    // MARK: - Visit fields
    
    /// Message the the user is currently visiting (PASSIVE reading) can be the same as
    /// current work but it could also be something else.
    /// - Note: this must not be hashed (it is never written to disk)
    static var currentVisitId: String? { willSet {
        // if old value same as new value, do nothing
        guard currentVisitId != newValue else {
            return
        }
        storeQueue.sync {
            // store current visit in the proper place, depending on whether the id
            // is currently being worked on, or if it was already done (lastly, if not done
            // put in preVisits)
            if let id = currentVisitId, var doneVisit = currentVisit, doneVisit.done() {
                if let cw = currentWork, cw.id == id {
                    currentWork!.visits.append(doneVisit)
                } else if doneMessages.contains(id) {
                    postVisits.appendIfExists(k: id, v: doneVisit)
                } else {
                    preVisits.appendIfExists(k: id, v: doneVisit)
                }
            }
            // create a new visit, if needed
            currentVisit = newValue != nil ? Event() : nil
        }
    } }
    
    /// Represents the current visit, which will be stored in preVisits / postVisits or the current work depending on whether the user worked on the visited message before, after or during the message was being worked on
    static private(set) var currentVisit: Event?
    
    /// Visits on a given message that happen before starting to work on that message are stored here.
    static var preVisits: [String: [Event]] = [String: [Event]]()
    
    /// Visits on a given message that happen after starting to work on that message are stored here.
    static var postVisits: [String: [Event]] = [String: [Event]]()
    
    /// Selections on a message that happen before starting to work on that message are stored here.
    static var preSelections: [String: [Selection]] = [String: [Selection]]()
    
    /// Selections on a message that happen after starting to work on that message are stored here.
    static var postSelections: [String: [Selection]] = [String: [Selection]]()

    /// Gazes that happen on boxes related to messages that were not worked on yet are stored here (indexed by messageId).
    static var preGazes: [String: EyeData] = [String: EyeData]()
    
    /// Gazes that happen on boxes related to messages that were already done are stored here.
    /// (indexed by messageId).
    static var postGazes: [String: EyeData] = [String: EyeData]()
    
    /// Keywords that happen on boxes related to message that the user did not yet work on are stored here.
    static var preKeywords: [String: [Keyword]] = [String: [Keyword]]()
    
    /// Keywords that happen on boxes related to message that the user already completed are stored here.
    static var postKeywords: [String: [Keyword]] = [String: [Keyword]]()
    
    /// Causes the HistoryManager to save raw gaze data.
    /// Set to true when the user starts working on a message and to false as soon as done is pressed.
    static var trackRawGaze: Bool = false { didSet {
        if oldValue {
            storeQueue.async {
                var outData = [String: [Any]]()
                
                outData["Xs"] = rawXs
                rawXs = []
                outData["Ys"] = rawYs
                rawYs = []
                outData["Ts"] = rawTs
                rawTs = []
                
                // do nothing else if demoing
                guard !demoing else { return }
                
                guard let id = currentWorkMessageId else { return }
                let url = AppSingleton.mailEyeInDownloads.appendingPathComponent("Fixations_" + id.md5 + ".json")
                if let data = try? JSONSerialization.data(withJSONObject: outData, options: .prettyPrinted) {
                    try? data.write(to: url)
                }
            }
        }
    } }
    
    /// Raw Gaze Data
    fileprivate static var rawXs: [Double] = []
    /// Raw Gaze Data
    fileprivate static var rawYs: [Double] = []
    /// Raw Gaze Data
    fileprivate static var rawTs: [Int] = []

    // MARK: - Current work fields
    
    /// Message on which the user is currently working on (set when pressing start)
    /// - Note: data in this should be hashed (it *is* written to disk)
    static var currentWork: AugmentedMessage? = nil
    
    /// Message ID on which the user is currently working on.
    /// - Note: this must not be hashed (it *is never* written to disk)
    static var currentWorkMessageId: String?
    
    /// Row in main table on which the current message was found.
    static var currentWorkMessageRow: Int?

    /// Current target mailbox controler
    static var currentController: MailboxController? { get {
        return sharedManager.currentMailboxController
    } }
    
    // MARK: - Private tracking fields
    
    /// A boolean indicating that the user is (probably) reading. Essentially, it means we are after entry timer but before exit timer (or exit event).
    fileprivate(set) var userIsReading = false
    
    /// A unix timestamp (milliseconds Int) indicating when the user started reading
    fileprivate(set) var readingUnixTime = 0
    
    /// The current thing the user is probably looking at
    fileprivate weak var currentMailboxController: MailboxController?
    
    /// The timer that regularly updates all done augmented messages
    fileprivate let doneAugmentedMessageTimer: Timer?
    
    /// Creates the history manager
    private init() {
        if #available(OSX 10.12, *) {
            doneAugmentedMessageTimer = Timer(timeInterval: 120, repeats: true) {_ in
                HistoryManager.completeAllAugmentedMessages()
            }
            RunLoop.current.add(doneAugmentedMessageTimer!, forMode: .commonModes)
        } else {
            doneAugmentedMessageTimer = nil
        }
    }
    
    // MARK: - External functions
    
    /// Resets all tracking variables to empty
    static func resetFields() {
        storeQueue.sync {
            doneMessages = []
            corruptedMessages = []
            trackRawGaze = false
            rawXs = []
            rawYs = []
            rawTs = []
            currentVisit = nil
            currentVisitId = nil
            currentWorkMessageId = nil
            currentWork = nil
            preGazes = [:]
            preVisits = [:]
            preKeywords = [:]
            preSelections = [:]
            postGazes = [:]
            postVisits = [:]
            postKeywords = [:]
            postSelections = [:]
        }
    }
    
    /// Tells the history manager that something new has happened.
    static func entry(_ mboxController: MailboxController) {
        // if we are tracking eyes, make sure eyes are available before starting
        if AppSingleton.eyeTracker?.available ?? false {
            if !(AppSingleton.eyeTracker?.eyesLost ?? true) {
                sharedManager.preparation(mboxController)
            }
        } else {
            sharedManager.preparation(mboxController)
        }
    }
    
    /// Tells the history manager to close the current event (we switched focus, or something similar)
    static func exit() {
        sharedManager.exitEvent(nil)
    }
    
    /// Some text was selected, store in pre, post selections or current work
    static func selectedText(msgId: String, selection: Selection) {
        // make sure current visit matches msgId (otherwise something went very wrong)
        guard msgId == currentVisitId else {
            return
        }
        storeQueue.sync {
            // store selection in the proper place, depending on whether the id
            // is currently being worked on, or if it was already done (lastly, if not done
            // put in preSelections)
            if let cw = currentWorkMessageId, cw == msgId {
                currentWork!.selections.append(selection)
            } else if doneMessages.contains(msgId) {
                postSelections.appendIfExists(k: msgId, s: selection)
            } else {
                preSelections.appendIfExists(k: msgId, s: selection)
            }
        }
    }
    
    /// Rewrites all augmented messages in default folder, adding
    /// data that was collected after they were done.
    /// **Synchronous**.
    static func completeAllAugmentedMessages() {
        
        // do nothing if we are demoing
        guard !HistoryManager.demoing else { return }
        
        storeQueue.sync {
            
            let IdsThatHaveData = Set(HistoryManager.postGazes.keys)
                .union(Set(HistoryManager.postVisits.keys))
                .union(Set(HistoryManager.postKeywords.keys))
                .union(Set(HistoryManager.postSelections.keys))
            
            guard IdsThatHaveData.count > 0 else {
                return
            }
            
            let msgsIds = HistoryManager.doneMessages.intersection(IdsThatHaveData)
            let decoder = JSONDecoder()
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            for id in msgsIds {
                let appId: String
                appId = AugmentedMessage.makeAppId(id)
                let url = AppSingleton.mailEyeInDownloads.appendingPathComponent(appId + ".json")
                
                do {
                    let dataIn = try Data(contentsOf: url)
                    var msgIn = try decoder.decode(AugmentedMessage.self, from: dataIn)
                    
                    // write in postgazes, postkeywords, postvisits and postselections
                    
                    if let pg = postGazes.removeValue(forKey: id) {
                        if msgIn.post_gazes == nil {
                            msgIn.post_gazes = pg
                        } else {
                            msgIn.post_gazes!.unite(otherData: pg)
                        }
                    }
                    
                    if let pv = postVisits.removeValue(forKey: id) {
                        if msgIn.post_visits == nil {
                            msgIn.post_visits = pv
                        } else {
                            msgIn.post_visits!.append(contentsOf: pv)
                        }
                    }
                    
                    if let pk = postKeywords.removeValue(forKey: id) {
                        if msgIn.post_keywords == nil {
                            msgIn.post_keywords = pk
                        } else {
                            msgIn.post_keywords!.append(contentsOf: pk)
                        }
                    }
                    
                    if let ps = postSelections.removeValue(forKey: id) {
                        if msgIn.post_selections == nil {
                            msgIn.post_selections = ps
                        } else {
                            msgIn.post_selections!.append(contentsOf: ps)
                        }
                    }
                                        
                    msgIn.dataUpdates.append(Date())
                    
                    let dataOut = try encoder.encode(msgIn)
                    try dataOut.write(to: url)
                    
                } catch {
                    if #available(OSX 10.12, *) {
                        os_log("Failed to complete message with id %@: %@", type: .error, id, error.localizedDescription)
                    }
                    continue
                }
            }
        }
    }
    
    static func pauseBehavioural() {
        pointerMovementTracker.stopped = true
        keyboardTracker.stopped = true
        pointerClickTracker.stopped = true
    }
    
    static func resumeBehavioural() {
        pointerMovementTracker.stopped = false
        keyboardTracker.stopped = false
        pointerClickTracker.stopped = false
    }
    
    static func resetBehavioural() {
        _ = pointerMovementTracker.reset()
        _ = keyboardTracker.reset()
        _ = pointerClickTracker.reset()
    }

    // MARK: - Protocol implementation
    
    func receiveNewFixationData(_ newData: [FixationEvent]) {
        
        guard !HistoryManager.paused else {
            return
        }
        
        if let mboxController = currentMailboxController {
            
            // translate all fixations to page points, and insert to corresponding data in the main dictionary
            for fixEv in newData {
                
                // run only on eye serial queue, and check if user is reading
                
                eyeQueue.sync {

                    if self.userIsReading {
                    
                        // convert to screen point and flip it (smi and os x have y coordinate flipped.
                        var screenPoint = NSPoint(x: fixEv.positionX, y: fixEv.positionY)
                        screenPoint.y = AppSingleton.screenRect.height - screenPoint.y
                        
                        // retrieve fixation and process quadruplet, if any
                        DispatchQueue.main.async {
                            if let quadruplet = mboxController.screenToBox(screenPoint) {
                                self.storeQuadruplet(quadruplet, fixEv)
                            }
                        }
                    }
                }
            }
        }

    }
    
    func receiveRaw(_ gazePoint: NSPoint, timepoint: Int) {
        guard HistoryManager.trackRawGaze else { return }
        HistoryManager.storeQueue.async {
            HistoryManager.rawXs.append(Double(gazePoint.x))
            HistoryManager.rawYs.append(Double(gazePoint.y))
            HistoryManager.rawTs.append(timepoint)
        }
    }
    
    // MARK: - Private functions
    
    /// Assigns retrieved eye tracking data (incl. keywords) to the correct
    /// index (preGazes vs. postGazes and preKeywords vs postKeywords, or currentWork)
    private func storeQuadruplet(_ quadruplet: (box: FixationBox, point: NSPoint, msgId: String, keywords: Set<String>?), _ fixation: FixationEvent) {
        
        HistoryManager.storeQueue.sync {
            
            // create eye datum, store it later
            let datum = EyeDatum(x: Double(quadruplet.point.x), y: Double(quadruplet.point.y), duration: fixation.duration, unixtime: fixation.unixtime)
            
            // create keywords, is any, store them later
            let keywords: [Keyword]?
            if let kwStrings = quadruplet.keywords {
                keywords = kwStrings.map({Keyword(fromWord: $0, gazeDuration: fixation.duration)})
            } else {
                keywords = nil
            }

            // first, check if the data is related to current work
            // use currentWorkMessageId because it s not hashed
            if let currentWorkId = HistoryManager.currentWorkMessageId, quadruplet.msgId == currentWorkId {
                // failsafe trap, just in case a mistake was made somewhere
                guard currentWorkId == HistoryManager.currentVisitId else {
                    if #available(OSX 10.12, *) {
                        os_log("Work id does not match visit id", type: .error)
                    }
                    return
                }
                guard HistoryManager.currentWork != nil else {
                    if #available(OSX 10.12, *) {
                        os_log("Could not find current work", type: .error)
                    }
                    return
                }
                HistoryManager.currentWork?.gazes.addDatum(box: quadruplet.box, datum: datum)
                
                // add keywords, if any
                keywords?.forEach({HistoryManager.currentWork?.addKeyword($0)})
            } else if HistoryManager.doneMessages.contains(quadruplet.msgId) {
                // otherwise check if message was already done to put in post
                HistoryManager.postGazes.addDatumIfExists(k: quadruplet.msgId, box: quadruplet.box, d: datum)
                // add keywords, if any
                keywords?.forEach({HistoryManager.postKeywords.addKeywordIfExists(k: quadruplet.msgId, kw: $0)})
            } else {
                // lastly, put in pre
                HistoryManager.preGazes.addDatumIfExists(k: quadruplet.msgId, box: quadruplet.box, d: datum)
                // add keywords, if any
                keywords?.forEach({HistoryManager.preKeywords.addKeywordIfExists(k: quadruplet.msgId, kw: $0)})
            }
        }  // end of storeQueue call
    }
    
    // MARK: - Internal functions
    
    /// Starts the "entry timer" and sets up references to the mailbox controller
    fileprivate func preparation(_ mboxController: MailboxController) {
        exitEvent(nil)
        
        timerQueue.sync {
            self.entryTimer = Timer(timeInterval: EyeConstants.minReadTime, target: self, selector: #selector(self.entryTimerFire(_:)), userInfo: mboxController, repeats: false)
            DispatchQueue.main.async {
                [weak self] in
                if let timer = self?.entryTimer {
                    RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
                }
            }
        }
    }
    
    // MARK: - Callbacks
    
    /// The document has been "seen" long enough, request information and prepare second (exit) timer
    @objc fileprivate func entryTimerFire(_ entryTimer: Timer) {
        self.entryTimer = nil
        
        guard let mboxController = entryTimer.userInfo as? MailboxController,
              let window = mboxController.view.window, window.isKeyWindow else {
            return
        }
        
        readingUnixTime = Date().unixTime
        userIsReading = true
        
        // retrieve status
        
        // prepare to convert eye coordinates
        self.currentMailboxController = mboxController
        
        // prepare exit timer, which will fire when the user is inactive long enough (or will be canceled if there is another exit event).
        timerQueue.sync {
            self.exitTimer = Timer(timeInterval: EyeConstants.maxReadTime, target: self, selector: #selector(self.exitEvent(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(self.exitTimer!, forMode: RunLoopMode.commonModes)
        }
    }
    
    /// The user has moved away, send current status (if any) and invalidate timer.
    /// - Note: clears all tracked controllers.
    @objc fileprivate func exitEvent(_ exitTimer: Timer?) {
        userIsReading = false
        self.currentMailboxController = nil
        
        // cancel previous entry timer, if any
        if let timer = self.entryTimer {
            timerQueue.sync {
                timer.invalidate()
                self.entryTimer = nil
           }
        }
        // cancel previous exit timer, if any
        if let timer = self.exitTimer {
            timerQueue.sync {
                timer.invalidate()
                self.exitTimer = nil
           }
        }
        
    }
 
}
