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

class Operation: Foundation.Operation {

    // MARK: - State
    
    /// Marking `state` as dynamic allows this property to be key-value observed.
    @objc dynamic var state = State.initializing
    
    /**
     Using the `@objc` prefix exposes this enum to the ObjC runtime,
     allowing the use of `dynamic` on the `state` property.
     */
    @objc enum State: Int {
        /// The `Operation` is being initialized (not ready yet)
        case initializing
        
        /// The `Operation` is ready to begin execution.
        case ready
        
        /// The `Operation` is executing.
        case executing
        
        /// The `Operation` has finished executing.
        case finished
        
        /// The `Operation` has been cancelled. Operations must set this
        /// state themselves upon checking super's `cancelled` flag.
        case cancelled
    }
    
    // MARK: - Observable properties (NSOperation)
    
    @objc override var isReady: Bool {
        return state == .ready
    }
    
    @objc override var isExecuting: Bool {
        return state == .executing
    }
    
    @objc override var isFinished: Bool {
        return state == .finished || state == .cancelled
    }
    
    /**
     Add the "state" key to the key value observable properties of `NSOperation`.
     */
    @objc class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return ["state"]
    }
    
    @objc class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return ["state"]
    }
    
    @objc class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return ["state"]
    }
}
