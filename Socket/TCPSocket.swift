//
//  TCPSocket.swift
//  SocketSample
//
//  Created by Andrew Visotskyy on 6/22/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

public protocol TCPSocketDelegate {
    
   func socketDidConnect       (socket: TCPSocket)
   func socketDidDisconnect    (socket: TCPSocket)
   func socketDidReceiveMessage(socket: TCPSocket, text: String)
    
   func didFailWithError(socket: TCPSocket, error: NSError)
    
}

public class TCPSocket {
    
   private var inputStream: NSInputStream!
   private var outputStream: NSOutputStream!
    
   private var inputStreamDelegate : StreamDelegate?
   private var outputStreamDelegate: StreamDelegate?
    
   public var delegate: TCPSocketDelegate?
    
   public init() {
      inputStreamDelegate  = StreamDelegate(function: { (s, e) in self.inputStream (s, event: e) })
      outputStreamDelegate = StreamDelegate(function: { (s, e) in self.outputStream(s, event: e) })
   }
    
   deinit {
      disconnect()
   }
    
   public func connect(host: String, port: UInt32) {
        
      var readStream : Unmanaged<CFReadStream >?
      var writeStream: Unmanaged<CFWriteStream>?
        
      CFStreamCreatePairWithSocketToHost(nil, host, port, &readStream, &writeStream)
      
      // Documentation suggests readStream and writeStream can be assumed to
      // be non-nil. If you believe otherwise, you can test if either is nil
      // and implement whatever error-handling you wish.
        
      inputStream  =  readStream!.takeRetainedValue()
      outputStream = writeStream!.takeRetainedValue()
        
      inputStream .delegate = inputStreamDelegate
      outputStream.delegate = outputStreamDelegate
        
      inputStream .scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
      outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
      inputStream .open()
      outputStream.open()
   }
    
   public func disconnect() {
        
      inputStream .close()
      outputStream.close()
        
      inputStream .removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
      outputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
      inputStream .delegate = nil
      outputStream.delegate = nil
        
      inputStream  = nil;
      outputStream = nil;
        
      delegate?.socketDidDisconnect(self)
   }
   
   public func write(text: String) {
      
      let data   = [UInt8](text.utf8)
      let length = data.count
      
      outputStream.write(data, maxLength: length)
   }
   
   private func inputStream(stream: NSStream, event: NSStreamEvent) {
        
      switch event {
            
         case NSStreamEvent.OpenCompleted:
            delegate?.socketDidConnect(self)
            
         case NSStreamEvent.ErrorOccurred:
            delegate?.didFailWithError(self, error: stream.streamError!)
            disconnect()
            
         case NSStreamEvent.HasBytesAvailable:
            
            let data = inputStream.readAllData()
            let text = String(data: data, encoding: NSUTF8StringEncoding)!
            
            if text != "" {
               delegate?.socketDidReceiveMessage(self, text: text)
            }
            
         case NSStreamEvent.EndEncountered:
            delegate?.socketDidDisconnect(self)
            
         default: break
      }
    }
    
    private func outputStream(stream: NSStream, event: NSStreamEvent) {
        
        switch event {
            
        case NSStreamEvent.OpenCompleted:
            delegate?.socketDidConnect(self)
            
        case NSStreamEvent.ErrorOccurred:
            delegate?.didFailWithError(self, error: stream.streamError!)
            disconnect()
            
        default: break
      }
   }
   
}