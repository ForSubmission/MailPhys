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

/// All constants used are put here for convenience.
class EyeConstants {
    
    // MARK: - Preferences
    // Remember to set some default values in the appdelegate for each preference
    
    /// If we want to constrain maximum window size when eye tracking is on
    static let prefConstrainWindowMaxSize = "documentWindow.constrain_maxSize_eye"
    
    /// Dominant eye
    static let prefDominantEye = "eye.dominant"
    
    /// Which eye tracker to use (as Int, see EyeDataProviderType `rawValue`s)
    static let prefEyeTrackerType = "eye.eyeTrackerType"
    
    /// Draw debug circle
    static let prefDrawDebugCircle = "debug.drawCircle"
    
    /// Monitor DPI
    static let prefMonitorDPI = "monitor.DPI"
    
    /// URL of the DiMe server (bound in the preferences window)
    static let prefDiMeServerURL = "dime.serverinfo.url"
    
    /// Username of the DiMe server (bound in the preferences window)
    static let prefDiMeServerUserName = "dime.serverinfo.userName"
    
    /// Password of the DiMe server (bound in the preferences window)
    static let prefDiMeServerPassword = "dime.serverinfo.password"
    
    /// List of strings that prevent document history tracking if found in source pdf text
    static let prefStringBlockList = "preferences.blockStringList"
    
    // MARK: - History-specific constants
    
    /// Amount of seconds which is required to assume that the user did read a specific document
    /// during a single session
    static let minTotalReadTime: TimeInterval = 30.0
    
    /// Amount of seconds that are needed before we assume user is reading (after, we start recording the current readingevent).
    static let minReadTime: TimeInterval = 1.5
    
    /// Amount of seconds after which we assume the user stopped reading.
    /// This always always close (sends to dime) a "live" reading event.
    /// (It is assumed the user went away from keyboard after this time passes).
    static let maxReadTime: TimeInterval = 900
    
    /// Date formatter shared in DiMe submissions (uses date format below)
    static let diMeDateFormatter = EyeConstants.makeDateFormatter()
    
    /// Date format used for DiMe submission
    static let diMeDateFormat = "Y'-'MM'-'d'T'HH':'mm':'ssZ"
    
    // MARK: - Eye Tracking
    
    /// If eyes are lost for this whole period (seconds) an eye lost notification is sent
    static let eyesMaxLostDuration: TimeInterval = 7.0

    // MARK: - Notifications
    
    /// String notifying that the eye tracker connection status changed
    ///
    /// **UserInfo dictionary fields**:
    ///
    /// - "available": Boolean, true if eye tracker went up, false if down
    static let eyeConnectionNotification = Notification.Name("anon.forsubmission.eyeConnectionChanged")
    
    /// String notifying that eyes were lost/seen
    ///
    /// **UserInfo dictionary fields**:
    ///
    /// - "available": Boolean, true if eyes can be seen, false if they were lost
    static let eyesAvailabilityNotification = Notification.Name("anon.forsubmission.eyesAvailabilityNotification")
    
    /// String identifying the notification sent when a new raw sample (for eye position) is received from the eye tracker.
    /// The sample regarding the last (most recent) event is sent
    ///
    /// **UserInfo dictionary fields**:
    /// - "xpos": last seen position, x (Double)
    /// - "ypos": last seen position, y (Double; in SMI coordinate system, which is different from OS X)
    /// - "zpos": last seen position, z (Double; distance from camera)
    static let eyePositionNotification = Notification.Name("anon.forsubmission.eyePosition")
        
    // MARK: - Static functions
    
    fileprivate static func makeDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = EyeConstants.diMeDateFormat
        return dateFormatter
    }
}

/// Eye (left or right). Using same coding as SMI_LSL data streaming.
public enum Eye: Int {
    case left = -1
    case right = 1
}
