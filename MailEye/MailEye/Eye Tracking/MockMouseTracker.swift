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

class MockMouseTracker: EyeDataProvider {
    
    var fixationDelegate: FixationDataDelegate? = nil
    
    var available: Bool = false
    
    var eyesLost: Bool = false
    
    var lastValidDistance: CGFloat = 300
    
    /// Mouse movement monitor. Constructed during start and destroyed during stop()
    var mouseTracker: Any? = nil

    func start() {
        // init monitors
        mouseTracker = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.mouseMoved) { event in
            
            // create event inverting Y
            let fixEv = FixationEvent(startTime: Int(event.timestamp), endTime: Int(event.timestamp) + 10, duration: 1, positionX: Double(NSEvent.mouseLocation.x), positionY: Double(AppSingleton.screenRect.height) - Double(NSEvent.mouseLocation.y), unixtime: Date().unixTime)
            self.sendFixations([fixEv])
            
            return event
        }

        
        eyeConnectionChange(available: true)
        available = true
    }

    func stop() {
        available = false
        eyeConnectionChange(available: false)
        
        // remove monitors
        if let mt = mouseTracker {
            NSEvent.removeMonitor(mt)
            self.mouseTracker = nil
        }
    }
    
}
