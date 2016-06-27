//
//  Extensions.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/27/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation


class StreamDelegate: NSObject, NSStreamDelegate {
    
   var function: Callback
    
   init(function: (s: NSStream, e: NSStreamEvent) -> ()) {
      self.function = function
   }
    
   func stream(stream: NSStream, handleEvent eventCode: NSStreamEvent) {
      function(stream, eventCode)
   }
    
   typealias Callback = (NSStream, NSStreamEvent) -> ()
    
}

extension NSInputStream {
    
   func readAllData() -> NSData {
        
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