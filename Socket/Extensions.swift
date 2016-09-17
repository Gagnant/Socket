//
//  Extensions.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/27/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal class StreamDelegate: NSObject, Foundation.StreamDelegate {
   
   private var callback: Callback
   
   internal init(_ callback: @escaping Callback) {
      self.callback = callback
   }

   internal func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
      callback(aStream, eventCode)
   }
   
   internal typealias Callback = (Stream, Stream.Event) -> ()
   
}

internal extension InputStream {
   
   internal func readAllData() -> Data {
      
      let data   = NSMutableData()
      var buffer = [UInt8](repeating: 0, count: 4096)
      
      while self.hasBytesAvailable {
         
         let length = read(&buffer, maxLength: buffer.count)
         
         if length > 0 {
            data.append(buffer, length: length)
         }
      }
      
      return data as Data
   }
   
}

internal extension RunLoop {
   
   /**
    *  Schedules the execution of a block on the target run loop.
    *   - parameter: block   The block to execute
    */
   internal func performAndWakeUp(block: @escaping () -> Swift.Void) {
      
      guard #available(iOS 10.0, *) else {
         return RunLoopInvoker.invoke(onRunLoop: self, block)
      }
      
      return self.perform(block)
   }

}

