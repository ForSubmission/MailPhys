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

/**
 Generalises the tracking of mouse and keyboard events.
 This class is not intended to be used directly, and should be subclassed instead.
 For each segment of data (e.g. message), we track a total (e.g. total pointer distance
 and total keystrokes). Each event must have a minimum within a given timeout
 (e.g. minimum 200 points total mouse movement over 2s or 5 keystrokes
 in 5 seconds) before recording a "sub-event".
 These values should be overridden by subclasses using the corresponding open variables.
 When an segment is terminated (email done), we return the number of "sub-events" recorded,
 representing bursts of activity.
 */
class BehaviouralEventTracker {
    
    // MARK: - Fields for subclasses
    
    /// Subclasses override this to specify the maximum time interval between
    /// events. Events that come with a bigger delay are split into sub-events
    open var maxDelay: TimeInterval { get { return 0 } }
    
    /// Minimum amount that should be present in a subtotal in order to be
    /// ackowledged (this could be minimum point distance or number of keystrokes).
    /// Subclasses should override this.
    open var minPartialTotal: Double { get { return 0 } }
    
    // MARK: - Constant / private fields
    
    /// Timestamp of last recorded event before delay checks.
    var lastTimestamp: TimeInterval = 0
    
    /// True if we do not want to record events
    var stopped = true
    
    /// Array of sub-event values, representing "bursts" of activity.
    private(set) var eventValues: [Double] = [0]
    
    /// Corresponding events (ms) for start of each entry in eventValues
    private(set) var startTimes: [Int] = [0]
    
    /// Corresponding unixtimes (ms) for end of each entry in eventValues
    private(set) var endTimes: [Int] = [0]
    
    // MARK: - Final methods
    
    /// Starts a new event, resets all info, and returns the result for the previously
    /// recorded data and their corresponding events (start and end unixtimes).
    final func reset() -> (values: [Double], events: [Event]) {
        stopped = true
        
        var retVal: (values: [Double], events: [Event]) = ([], [])
        
        for (i, val) in eventValues.enumerated() {
            if val >= minPartialTotal {
                retVal.values.append(val)
                retVal.events.append(Event(startTimes[i], endTimes[i]))
            }
        }
        
        // clear buffers
        clear()
        
        stopped = false
        
        return retVal
    }

    /// Receives a new event.
    final func receive(event: NSEvent) {
        guard !stopped else {
            return
        }
        
        let value = process(event: event)
        
        // check if a long time passed since last event,
        // if so we create a new "sub-event"
        let breakEvent = lastTimestamp + maxDelay < event.timestamp
        
        if !breakEvent {
            // if we don't need to break the event, add to last item in array and update end time accordingly
            eventValues[eventValues.count - 1] += value
            endTimes[eventValues.count - 1] = Date().unixTime
        } else {
            // otherwise, create a new sub event and its related starttime (endtime set to same as start)
            eventValues.append(value)
            startTimes.append(Date().unixTime)
            endTimes.append(Date().unixTime)
        }
        
        lastTimestamp = event.timestamp
        
    }
    
    // MARK: - Open methods
    
    /// Processes the event and adds a value to the sub-event array.
    /// Processing means we convert the event to a number (e.g. distance for pointer
    /// movements).
    /// Default implementation returns 1.
    open func process(event: NSEvent) -> Double {
        return 1
    }
    
    // MARK: - Private methods
    
    /// Clears all superclass buffers.
    private final func clear() {
        lastTimestamp = 0
        eventValues = [0]
        startTimes = [0]
        endTimes = [0]
    }
}
