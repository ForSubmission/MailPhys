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

extension Notification {
    
    /// Returns true if this notification is related to the user starting to passively read the email
    /// (two cases: making the mailbox window key, or eyes starting to become detected)
    var isPassiveStart: Bool { get {
        if name == NSWindow.didBecomeKeyNotification { return true }
        
        if name == EyeConstants.eyesAvailabilityNotification, let uInfo = self.userInfo, let avail = uInfo["available"] as? Bool, avail == true {
            return true
        }
        
        return false
    } }
    
    /// Returns true if this notification is related to the user stopping to passively read the email
    /// (two cases: the mailbox window loses key, or eyes were lost)
    var isPassiveEnd: Bool { get {
        if name == NSWindow.didResignKeyNotification { return true }

        if name == EyeConstants.eyesAvailabilityNotification, let uInfo = self.userInfo, let avail = uInfo["available"] as? Bool, avail == false {
            return true
        }

        return false
    } }
    
}
