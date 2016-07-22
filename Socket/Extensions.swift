//
//  Extensions.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/27/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal class StreamDelegate: NSObject, NSStreamDelegate {
   
   private var callback: Callback
   
   internal init(_ callback: Callback) {
      self.callback = callback
   }
   
   internal func stream(stream: NSStream, handleEvent eventCode: NSStreamEvent) {
      callback(stream, eventCode)
   }
   
   internal typealias Callback = (NSStream, NSStreamEvent) -> ()
   
}

internal extension NSInputStream {
   
   internal func readAllData() -> NSData {
      
      let data   = NSMutableData()
      var buffer = [UInt8](count: 4096, repeatedValue: 0)
      
      while self.hasBytesAvailable {
         
         let length = read(&buffer, maxLength: buffer.count)
         
         if length > 0 {
            data.appendBytes(buffer, length: length)
         }
      }
      
      return data
   }
   
}