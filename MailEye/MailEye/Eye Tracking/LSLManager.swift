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

/// The LSLManager provides eye tracking data using LabStreamingLayer.
/// It is responsible for creating the LSL streams (using LSLFetcher instances) and checking that data is correctly formed.
class LSLManager: EyeDataProvider {
        
    // MARK: - EyeDataProvider fields
    
    /// Returns true if all LSL streams were successfully activated
    private(set) var available: Bool = false

    var fixationDelegate: FixationDataDelegate?

    private(set) var eyesLost: Bool = true { didSet {
        if eyesLost != oldValue {
            eyeStateChange(available: !eyesLost)
        }
    } }
    
    private(set) var lastValidDistance: CGFloat = 800.0
    
    // MARK: - LSL Stream objects references
    
    private var rawStream: LSLFetcher<RawEyePosition>?
    private var eventStream: LSLFetcher<FixationEvent>?
    
    // MARK: - EyeDataProvider functions
    
    /// Opens the lsl streams
    func start() {
        let rawSuccess = rawStream?.start() ?? false
        let fixationSuccess = eventStream?.start() ?? false
        if rawSuccess && fixationSuccess {
            eyeConnectionChange(available: true)
            available = true
        } else {
            AppSingleton.alertUser("Failed to initialize Lab Streaming Layer")
            eyeConnectionChange(available: false)
            available = false
        }
    }
    
    /// Stops the lsl streams
    func stop() {
        rawStream?.stop()
        eventStream?.stop()
        eyeConnectionChange(available: false)
        available = false
    }
    
    // MARK: - Private instance variables (for data processing)
    
    /// Last time we received a raw eye position timestamp
    private var lastRawTimestamp = Int.min
    
    /// Start time of the last fixation we received
    private var lastFixationStart = Int.min
    
    /// Last time that eyes were detected
    private var eyesLastSeen = Date.distantPast
    
    /// Last time that we sent a raw position sample
    private var lastSentRaw = Date.distantPast
    
    /// Minimum amount of time to leave between raw sample sending
    private var kMinRawInterval: TimeInterval = 1/60  // 60 Hz
    
    // MARK: - Initialization and callback definition
    
    init() {
        
        // Raw data (used for head position and whether eyes are present)
        let rawDataCallback: (Double, RawEyePosition?) -> Void = {
            _, rawPosition in
            
            guard let rawPosition = rawPosition, !rawPosition.zeroed() else {
                // no data found in this sample
                
                // if eyes are currently indicated as available, but too much time has passed,
                // change eye status
                if !self.eyesLost && self.eyesLastSeen.addingTimeInterval(EyeConstants.eyesMaxLostDuration).compare(Date()) == .orderedAscending {
                        self.eyesLost = true
                        self.sendLastPosition(RawEyePosition.zero)
                }
                return
            }
            
            // check that this timestamp is later than the latest received timestamp before proceeding.
            // (to avoid dispatching duplicate samples, which happen using the SMI Python API).
            guard self.lastRawTimestamp < rawPosition.timestamp else {
                return
            }
            self.lastRawTimestamp = rawPosition.timestamp
            
            self.eyesLost = false
            
            // send last raw position only if enough time has passed since last sent time
            let now = Date()
            if self.lastSentRaw.addingTimeInterval(self.kMinRawInterval).compare(now) == .orderedAscending {
                self.sendLastPosition(rawPosition)
                self.lastValidDistance = CGFloat(rawPosition.EyePositionZ)
                self.lastSentRaw = now
            }
            
            self.fixationDelegate?.receiveRaw(NSPoint(x: rawPosition.gazeX, y: rawPosition.gazeY), timepoint: rawPosition.timestamp)
            
            self.eyesLastSeen = Date()
        }
        
        // Fixation data (used to determine what the user is reading)
        let fixationDataCallback: (Double, FixationEvent?) -> Void = {
            _, fixationEvent in
            
            guard let fixationEvent = fixationEvent, fixationEvent.endTime != 0 else {
                return
            }
            
            // check that this fixation start is bigger than the latest received fixation
            // start before proceeding.
            // (to avoid dispatching duplicate samples, which happen using the SMI Python API).
            guard self.lastFixationStart < fixationEvent.startTime else {
                return
            }
            self.lastFixationStart = fixationEvent.startTime
            
            self.sendFixations([fixationEvent])
        }
        
        rawStream = LSLFetcher<RawEyePosition>(name: "SMI_Raw", dataCallback: rawDataCallback)
        eventStream = LSLFetcher<FixationEvent>(name: "SMI_Event", dataCallback: fixationDataCallback)
    }
}
