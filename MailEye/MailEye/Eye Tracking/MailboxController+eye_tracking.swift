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
import os.log

extension MailboxController {
    
    // MARK: - Statics
    
    /// Returns a predefined frame for the message window
    static func getWindowFrame(forScreen: NSScreen?) -> NSRect? {
        guard let screen = forScreen else {
            return nil
        }
        
        let kScreenSkipProportion: [CGFloat] = [1/6, 2/7]
        var shrankScreenRect = screen.frame
        
        // push origin right by the desired amount and shrink width by twice that
        let hpoints = screen.frame.width / screen.backingScaleFactor
        let horizontalOffset = hpoints * kScreenSkipProportion[0] / 2
        shrankScreenRect.origin.x += horizontalOffset
        shrankScreenRect.size.width = screen.frame.width * (1 - kScreenSkipProportion[0])
        
        // push origin up by etc etc (same as above)
        let vpoints = screen.frame.height / screen.backingScaleFactor
        let verticalOffset = vpoints * kScreenSkipProportion[1] / 2
        shrankScreenRect.origin.y += verticalOffset
        shrankScreenRect.size.height = screen.frame.height * (1 - kScreenSkipProportion[1])
        
        return shrankScreenRect
    }

    // MARK: - Internals
    
    /// Create all observers related to eye (and physio) tracking
    func setObservers() {
        
        // scroll view observers
        NotificationCenter.default.addObserver(self, selector: #selector(entered(_:)), name: NSView.frameDidChangeNotification, object: self.messageController.bodyView)
        
        // COMMENTING OUT NSScrollView.didEndLiveScrollNotification since these events are not sent when using mouse
        
        // thread scroll
        NotificationCenter.default.addObserver(self, selector: #selector(entered(_:)), name: NSScrollView.didLiveScrollNotification, object: self.allController.allMessagesTable.enclosingScrollView)
//        NotificationCenter.default.addObserver(self, selector: #selector(entered(_:)), name: NSScrollView.didEndLiveScrollNotification, object: self.allController.allMessagesTable.enclosingScrollView)
        
        // reference scroll
        NotificationCenter.default.addObserver(self, selector: #selector(entered(_:)), name: NSScrollView.didLiveScrollNotification, object: self.messageController.threadCollectionView.enclosingScrollView)
//        NotificationCenter.default.addObserver(self, selector: #selector(entered(_:)), name: NSScrollView.didEndLiveScrollNotification, object: self.messageController.threadCollectionView.enclosingScrollView)
        
        // message text view scroll
        NotificationCenter.default.addObserver(self, selector: #selector(entered(_:)), name: NSScrollView.didLiveScrollNotification, object: self.messageController.bodyView.enclosingScrollView)
//        NotificationCenter.default.addObserver(self, selector: #selector(entered(_:)), name: NSScrollView.didEndLiveScrollNotification, object: self.messageController.bodyView.enclosingScrollView)
        
        // window observers
        
        NotificationCenter.default.addObserver(self, selector: #selector(alteredWindow(_:)), name: NSWindow.didMoveNotification, object: self.view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(alteredWindow(_:)), name: NSWindow.didResizeNotification, object: self.view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(exited(_:)), name: NSWindow.didResignKeyNotification, object: self.view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(entered(_:)), name: NSWindow.didBecomeKeyNotification, object: self.view.window)
        
        // Get notifications about user's eyes (present or not)
        
        NotificationCenter.default.addObserver(self, selector: #selector(eyeStateCallback(_:)), name: EyeConstants.eyesAvailabilityNotification, object: nil)
    }
    
    /// Convert a screen coordinate to a FixationBox, a point within that box and an associated message id. Also gets a list of keywords associated to that point (body only)
    func screenToBox(_ pointOnScreen: NSPoint) -> (box: FixationBox, point: NSPoint, msgId: String, keywords: Set<String>?)? {
        
        let tinySize = NSSize(width: 1, height: 1)
        let tinyRect = NSRect(origin: pointOnScreen, size: tinySize)
        
        let rectInWindow = self.view.window!.convertFromScreen(tinyRect)
        let rectInView = self.view.convert(rectInWindow, from: self.view)
        let pointInView = rectInView.origin
        
        //  return nil if the point is outside this view
        if pointInView.x < 0 || pointInView.y < 0 || pointInView.x > view.frame.width || pointInView.y > view.frame.height {
            return nil
        }
        
        // otherwise get which view (thread, references, header, body) the point was in
        if let targetView = self.view.hitTest(pointInView), let triple = identifyTargetView(targetView, point: pointInView) {

            // if this is a body box, extract keywords from it
            let keywords: Set<String>?
            if triple.box == .body {
                // move overlay point
                if drawDebugCircle {
                    let oPoint = messageController.myOverlay.convert(pointInView, from: self.view)
                    messageController.myOverlay.moveFix(toPoint: oPoint)
                }
                
                var point = triple.point
                // invert point so that origin is on top left
                point.y = messageController.bodyView.frame.size.height - point.y
                if let _keyws = messageController.detectKeywords(forPointInBody: point) {
                    keywords = _keyws
                } else {
                    keywords = nil
                }
            } else {
                keywords = nil
            }
            
            return (triple.box, triple.point, triple.msgId, keywords)
        } else {
            return nil
        }

    }
    
    /// Converts a point into a box and a point in the box's coordinates
    private func identifyTargetView(_ view: NSView, point: NSPoint) -> (box: FixationBox, point: NSPoint, msgId: String)? {
        func stringIdentity(identifier: NSUserInterfaceItemIdentifier) -> FixationBox? {
            if identifier == Constants.bodyViewIdentifier {
                return .body
            } else if identifier == Constants.headerViewIdentifier {
                return .header
            } else if identifier == Constants.referenceViewIdentifier {
                return .reference
            } else if identifier == Constants.threadViewIdentifier {
                return .thread
            } else {
                return nil
            }
        }
        
        let _foundView: NSView?
        let _box: FixationBox?
        // if target has an identifier, point to it
        // if not, or if identifier was not a match, check the superview
        if let identifier = view.identifier, Constants.targetIdentifiers.contains(identifier) {
            _box = stringIdentity(identifier: identifier)
            _foundView = view
        } else if let superView = view.superview, let identifier = superView.identifier {
            _box = stringIdentity(identifier: identifier)
            _foundView = superView
        } else {
            _foundView = nil
            _box = nil
        }
        
        guard let foundView = _foundView, let box = _box else {
            return nil
        }
        
        var subPoint = foundView.convert(point, from: self.view)
        
        /// invert y if in body so that origin is on bottom left like all others
        if box == .body {
            subPoint.y = messageController.bodyView.frame.height - subPoint.y
        }
        
        let refView = (foundView as? MessageReferenceView) ?? foundView.superview as? MessageReferenceView
        
        guard let msgId = refView?.correspondingMessageId else {
            return nil
        }
        
        return (box: box, point: subPoint, msgId: msgId)
    }
    
    /// Called when scrolling, focusing into window
    @objc func entered(_ notification: Notification?) {
        guard let win = self.view.window, win.isKeyWindow else {
            return
        }
        
        if let notif = notification, notif.isPassiveStart, let msgId = messageController.correspondingMessageId {
            HistoryManager.currentVisitId = msgId
        }
        
        HistoryManager.entry(self)
        lastStartedReading = Date()
    }
    
    /// Called when closing / focusing out of window
    @objc func exited(_ notification: Notification?) {
        
        if let notif = notification, notif.isPassiveEnd {
            HistoryManager.currentVisitId = nil
        }
        
        HistoryManager.exit()
        lastStartedReading = nil
    }
    
    /// Called when window is moved
    @objc func alteredWindow(_ notification: Notification?) {
        // do nothing when using no eye tracker or mock mouse tracker
        guard let tracker = AppSingleton.eyeTracker,
            !(tracker is MockMouseTracker)
            else {
            return
        }
        
        entered(notification)
        if !moveLock, let newFrame = MailboxController.getWindowFrame(forScreen: self.view.window?.screen), let currentFrame = self.view.window?.frame, newFrame != currentFrame {
            moveLock = true
            DispatchQueue.main.async {
                self.view.window!.setFrame(newFrame, display: true)
                self.moveLock = false
            }
        }
    }
    
    ///
    @objc func eyeStateCallback(_ notification: Notification?) {
        if self.view.window!.isKeyWindow, let notification = notification {
            let uInfo = notification.userInfo as! [String: AnyObject]
            let avail = uInfo["available"] as! Bool
            if avail {
                entered(notification)
            } else {
                exited(notification)
            }
        }
    }
    
}
