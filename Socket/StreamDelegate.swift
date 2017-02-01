//
//  StreamDelegate.swift
//  Socket
//
//  Created by Andrew Visotskyy on 1/31/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
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
