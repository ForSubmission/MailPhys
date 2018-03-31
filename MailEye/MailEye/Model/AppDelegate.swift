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
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let openWindows = NSMutableArray()
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // defaults
        var defs = [String: Any]()
        defs[Constants.kServer] = ""
        defs[Constants.kUsername] = ""
        defs[Constants.kDiMeServerURL] = "http://localhost:8080/api"
        defs[Constants.kDiMeServerUserName] = "Test1"
        defs[Constants.kDiMeServerPassword] = "123456"
        defs[Constants.kFlagRepliedMessages] = false
        defs[Constants.kRecentImaps] = []
        defs[Constants.kDoNotCommunicateReadMessages] = false
        defs[Constants.kSinceDate] = Constants.defaultSinceDate
        defs[EyeConstants.prefDominantEye] = Eye.right.rawValue
        defs[EyeConstants.prefMonitorDPI] = 110  // defaulting monitor DPI to 110 as this is developing PC's DPI
        defs[EyeConstants.prefEyeTrackerType] = 0
        defs[EyeConstants.prefDrawDebugCircle] = false
        UserDefaults.standard.register(defaults: defs)
        UserDefaults.standard.synchronize()
        
        // initialise webkit on main queue
        DispatchQueue.main.async {
            let data = "<a href=\"nothing to see here\">link</a>".data(using: .utf8)!
            let _ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue, .timeout: 2.0, .webPreferences: stringWebPreferences], documentAttributes: nil)
        }

    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        DiMeSession.dimeConnect()
        
        // not using bluetooth for now
        // BluetoothMaster.startSearch()
        
        // setup debug view controller for events (if we want)
        if Constants.showDebugController {
            let debugWindow = NSWindow()
            let debugVC = AppSingleton.mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "DebugViewController")) as! DebugViewController
            debugWindow.contentViewController = debugVC
            AppSingleton.debugViewController = debugVC
            debugWindow.styleMask = [NSWindow.StyleMask.titled, NSWindow.StyleMask.resizable]
            debugVC.window = debugWindow
            debugWindow.orderFront(self)
        }
        
        // behavioural trackers
    
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.keyUp) { event in
            HistoryManager.keyboardTracker.receive(event: event)
        }
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.mouseMoved) { event in
            HistoryManager.pointerMovementTracker.receive(event: event)
        }
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDown) { event in
            HistoryManager.pointerClickTracker.receive(event: event)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyUp) { event in
            HistoryManager.keyboardTracker.receive(event: event)
            return event
        }
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.mouseMoved) { event in
            HistoryManager.pointerMovementTracker.receive(event: event)
            return event
        }
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDown) { event in
            HistoryManager.pointerClickTracker.receive(event: event)
            return event
        }
        
        let trusted  = AXIsProcessTrusted()
        if trusted == false {
            DispatchQueue.main.async {
                let str = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
                let d = [str: true] as CFDictionary
                AXIsProcessTrustedWithOptions(d)
            }
        }
        
        // If we want to use eye tracker, create it and associate us to it
        let eyeTrackerPref = UserDefaults.standard.object(forKey: EyeConstants.prefEyeTrackerType) as! Int
        if let eyeTrackerType = EyeDataProviderType(rawValue: eyeTrackerPref) {
            if let eyeTracker = eyeTrackerType.associatedTracker {
                AppSingleton.eyeTracker = eyeTracker
            }
        } else {
            if #available(OSX 10.12, *) {
                os_log("Failed to find a corresponding eye data provider type enum for Int: %d", type: .error, eyeTrackerPref)
            }
        }

        // init curl globally (should call cleanup before termination)
        curl_global_init(Int(CURL_GLOBAL_ALL))
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        curl_global_cleanup()
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        filenames.forEach() {
            let url = URL(fileURLWithPath: $0)
            
            self.loadMbox(fromUrl: url)
        }
    }
    
    @IBAction func runDemo(_ sender: AnyObject) {
        // do not store data when demoing
        HistoryManager.demoing = true

        try? (NSApplication.shared.delegate as? AppDelegate)?.loadCurlBox(serverWithDetails: Constants.publicServerDetails)
    }
    
    @objc func openDocument(_ sender: AnyObject) {
        // opens an existing mbox
        
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["public.data"]
        panel.begin() {
            result in
            guard result.rawValue == NSFileHandlingPanelOKButton,
                  let url = panel.url else {
                return
            }
            
            // make sure we store data from now on
            HistoryManager.demoing = false
            
            self.loadMbox(fromUrl: url)
        }
        
    }
    
    func loadMbox(fromUrl url: URL) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            if let mbox = Mbox(inUrl: url) {
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
                DispatchQueue.main.async {
                    self.createControllers(forMailbox: mbox)
                }
            } else {
                AppSingleton.alertUser("Failed to load data from: \(url.path)")
            }
            
        }
    }
    
    func loadCurlBox(serverWithDetails serverDetails: ServerDetails) throws {
        if let curlBox = try CurlBox(serverDetails: serverDetails) {
            DispatchQueue.main.async {
                self.createControllers(forMailbox: curlBox)
            }
        } else {
            AppSingleton.alertUser("Failed to load remote data from: \(serverDetails.address)")
        }
    }
    
    func createNewLoadingController() -> LoadingViewController  {
        let loadingController = AppSingleton.mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "LoadingViewController")) as! LoadingViewController
        let loadingWindow = DeallocatableWindow(contentViewController: loadingController)
        self.openWindows.add(loadingWindow)
        loadingWindow.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: "LoadingWindow"))
        loadingWindow.setFrameUsingName(NSWindow.FrameAutosaveName(rawValue: "LoadingWindow"))
        loadingWindow.orderFront(nil)
        loadingWindow.title = "Importing messages"
        return loadingController
    }
 
    /// Creates window controllers (mailbox and loading) for a mailbos
    /// - Attention: Must be called on main thread
    func createControllers(forMailbox mailbox: Mailbox) {
        
        let loadingController = createNewLoadingController()
        
        let mailboxWindowController = (AppSingleton.mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "MailboxWindowController")) as! NSWindowController)
        
        openWindows.add((mailboxWindowController.window as! MailboxWindow))
        
        let mailboxController = mailboxWindowController.contentViewController as! MailboxController
        
        mailbox.loadMbox(loadingController: loadingController, partialCompletionHandler: mailboxController.partialCompletionHandler(_:))
        
        mailboxController.representedObject = mailbox
        
        mailboxWindowController.shouldCascadeWindows = false
        mailboxWindowController.windowFrameAutosaveName = NSWindow.FrameAutosaveName(rawValue: "MailboxWindowController")
        mailboxWindowController.window?.setFrameUsingName(NSWindow.FrameAutosaveName(rawValue: "MailboxWindowController"))
        mailboxWindowController.showWindow(self)
        mailboxWindowController.window?.orderFront(self)

    }
    
}

