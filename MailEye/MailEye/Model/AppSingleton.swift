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
import os.log

class AppSingleton {
    
    // MARK: - Statics
    
    /// True if we want to hash all outputted data
    static var hashEverything = true
    
    /// List of stop words to be excluded from keywords, converted
    /// from https://code.google.com/archive/p/stop-words/
    static let stopWords: Set<String> = {
        let url = Bundle.main.url(forResource: "stop-words", withExtension: "json")!
        let rawData = try! Data(contentsOf: url)
        let jsondec = JSONDecoder()
        return try! jsondec.decode(Set<String>.self, from: rawData)
    }()
    
    static var debugViewController: DebugViewController?
    
    static let mainStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
    
    static let userDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .short
        df.doesRelativeDateFormatting = true
        return df
    }()
        
    // MARK: - Convenience
    
    /// Gets a MailEye folder in downloads with the current time,
    /// creating it if necessary
    /// returns downloads itself if the folder is already occupied by a file (delete that and reopen mailbox)
    static var mailEyeInDownloads: URL = {
        let downloadsDir = try! FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short)
        let meyeDir = downloadsDir.appendingPathComponent("MailEye - \(dateString)")
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: meyeDir.path, isDirectory: &isDir) {
            if !isDir.boolValue {
                alertUser("MailEye folder in Downloads \(meyeDir) is already occupied by a file")
                return downloadsDir
            }
        } else {
            do {
                try FileManager.default.createDirectory(at: meyeDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                alertUser("Couldn't create MailEye folder in downloads (\(meyeDir)):\n\(error.localizedDescription)")
                return downloadsDir
            }
        }
        return meyeDir
    }()

    /// Writes dime data to disk
    static func writeToDownloads<T>(dimeData: T) where T: DiMeData {
        // do nothing if we are demoing
        guard !HistoryManager.demoing else { return }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(dimeData)
            let fileName = mailEyeInDownloads.appendingPathComponent(dimeData.appId + ".json")
            try data.write(to: fileName, options: [])
        } catch {
            if #available(OSX 10.12, *) {
                os_log("Write to downloads encoding error: %@", type: .error, error.localizedDescription)
            }
        }
    }
    
    /// Convenience function to show an alerting alert (with additional info)
    ///
    /// - parameter message: The message to show
    /// - parameter infoText: shows additional text
    static func alertUser(_ message: String, infoText: String) {
        let myAl = NSAlert()
        myAl.alertStyle = .warning
        myAl.icon = NSImage(named: NSImage.Name(rawValue: "NSCaution"))
        myAl.messageText = message
        myAl.informativeText = infoText
        DispatchQueue.main.async {
            myAl.runModal()
        }
    }
    
    /// Convenience function to show an alerting alert (without additional info)
    ///
    /// - parameter message: The message to show
    static func alertUser(_ message: String) {
        let myAl = NSAlert()
        myAl.alertStyle = .warning
        myAl.icon = NSImage(named: NSImage.Name(rawValue: "NSCaution"))
        myAl.messageText = message
        DispatchQueue.main.async {
            myAl.runModal()
        }
    }

    // MARK: - Eye tracking stuff
    
    /// The class that provides eye tracking data (set by app delegate on start).
    /// Changing this value causes the eye tracker to start.
    static var eyeTracker: EyeDataProvider? = nil { willSet {
        eyeTracker?.stop()
        eyeTracker?.fixationDelegate = nil
        } didSet {
            eyeTracker?.start()
            eyeTracker?.fixationDelegate = HistoryManager.sharedManager
        } }
    
    /// Offset for eye tracker correction
    static var eyeOffset: [CGFloat] = [0, 0]
    
    /// Convenience getter for user's distance from screen, which defaults to 80cm
    /// if not known
    static var userDistance: CGFloat { get {
        if let tracker = eyeTracker {
            return tracker.lastValidDistance
        } else {
            return 800
        }
        } }
    
    /// Convenience getter to know wheter we want to constrain max window size when eye tracker is on
    static var constrainMaxWindowSize: Bool { get {
        return UserDefaults.standard.object(forKey: EyeConstants.prefConstrainWindowMaxSize) as! Bool
        } }
    
    /// The user's dominant eye, as set in the preferences window.
    static var dominantEye: Eye { get {
        let eyeRaw = UserDefaults.standard.object(forKey: EyeConstants.prefDominantEye) as! Int
        return Eye(rawValue: eyeRaw)!
        } set {
            UserDefaults.standard.set(newValue.rawValue, forKey: EyeConstants.prefDominantEye)
        } }
    
    /// The dimensions of the screen the application is running within.
    /// It is assumed there is only one screen when using eye tracking.
    static var screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1680, height: 1050)
    
    /// Position of new PDF Document window (for cascading)
    static var nextDocWindowPos = NSPoint(x: 200, y: 350)
        
    /// Gets DPI programmatically
    static func getComputedDPI() -> Int? {
        guard NSScreen.screens.count > 0 else {
            AppSingleton.alertUser("Can't get find any displays", infoText: "Please try restarting the app.")
            return nil
        }
        let screen = NSScreen.screens[0]
        let id = CGMainDisplayID()
        let mmSize = CGDisplayScreenSize(id)
        
        let pixelWidth = screen.frame.width  //we could do * screen!.backingScaleFactor but OS X normalizes DPI
        let inchWidth = cmToInch(mmSize.width / 10)
        return Int(round(pixelWidth / inchWidth))
    }
    
}
