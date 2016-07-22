//
//  Socket.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/22/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

public protocol TCPSocketDelegate {
   
   func socketDidConnect       (socket: TCPSocket)
   func socketDidDisconnect    (socket: TCPSocket)
   func socketDidReceiveMessage(socket: TCPSocket, text: String)
   func socketDidFailWithError (socket: TCPSocket, error: NSError)
   
}

public class TCPSocket {
   
   private let queue = dispatch_queue_create("com.gagnant.socket.socketqueue", nil)
   
   /**
    *  This variable used when it's time to notify delegate
    *  that the socket was opened. It's purpose is to send
    *  notification only once, when both of streams (read &
    *  write) successfully opened.
    *
    *  Equality to 0 means that connection didn't established
    *  yet.
    */
   private var dispatchOnceToken: dispatch_once_t = 0
   
   private var inputStreamDelegate  : StreamDelegate?
   private var outputStreamDelegate : StreamDelegate?
   private var inputStream          : NSInputStream!
   private var outputStream         : NSOutputStream!
   private var options              : Settings
   
   public var delegate: TCPSocketDelegate?
   
   public init() {
      
      options = [
         SocketSecurityLevelKey:SocketSecurityLevelNegotiated,
         SocketValidatesCertificateChainKey:true
      ]
      
      inputStreamDelegate  = StreamDelegate(cInputStream )
      outputStreamDelegate = StreamDelegate(cOutputStream)
   }
   
   deinit {
      disconnect()
   }
   
   public func connect(host: String, port: UInt32, settings: Settings = Settings()) {
      
      self.disconnect()
      self.dispatchOnceToken = 0
      
      var readStream : Unmanaged<CFReadStream >?
      var writeStream: Unmanaged<CFWriteStream>?
      
      CFStreamCreatePairWithSocketToHost(nil, host, port, &readStream, &writeStream)
      
      inputStream  =  readStream!.takeRetainedValue()
      outputStream = writeStream!.takeRetainedValue()
      
      inputStream .delegate = inputStreamDelegate
      outputStream.delegate = outputStreamDelegate
      
      self.parseSettings(settings)
      
      dispatch_async(queue) {
         
         self.inputStream .scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
         self.outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
         
         self.inputStream .open()
         self.outputStream.open()
         
         NSRunLoop.currentRunLoop().run()
      }
   }
   
   public func disconnect() {
      
      guard self.dispatchOnceToken != 0 else { return }
      
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
      
      guard self.dispatchOnceToken != 0 else { return }
      
      let data   = [UInt8](text.utf8)
      let length = data.count
      
      self.outputStream.write(data, maxLength: length)
   }
   
   private func cInputStream(stream: NSStream, event: NSStreamEvent) {
      
      switch event {
         
         case NSStreamEvent.OpenCompleted:
            self.handleSocketOpenning()
         
         case NSStreamEvent.ErrorOccurred:
            delegate?.socketDidFailWithError(self, error: stream.streamError!)
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
   
   private func cOutputStream(stream: NSStream, event: NSStreamEvent) {
      
      switch event {
         
         case NSStreamEvent.OpenCompleted:
            self.handleSocketOpenning()
         
         case NSStreamEvent.ErrorOccurred:
            delegate?.socketDidFailWithError(self, error: stream.streamError!)
            disconnect()
         
         default: break
      }
   }
   
   private func parseSettings(settings: Settings) {
      
      settings.forEach({ options[$0] = $1 })
      
      if options[SocketSecurityLevelKey]!.isEqual(SocketSecurityLevelNegotiated) {
         
         inputStream .setProperty(NSStreamSocketSecurityLevelNegotiatedSSL, forKey: NSStreamSocketSecurityLevelKey)
         outputStream.setProperty(NSStreamSocketSecurityLevelNegotiatedSSL, forKey: NSStreamSocketSecurityLevelKey)
         
         if options[SocketValidatesCertificateChainKey]!.isEqual(false) {
            
            let settings = [
               kCFStreamSSLValidatesCertificateChain as String: kCFBooleanFalse
            ]
            
            CFReadStreamSetProperty (inputStream,  kCFStreamPropertySSLSettings, settings)
            CFWriteStreamSetProperty(outputStream, kCFStreamPropertySSLSettings, settings)
         }
      }
      
   }
   
   private func handleSocketOpenning() {
      
      if inputStream.streamStatus == NSStreamStatus.Open &&
         outputStream.streamStatus == NSStreamStatus.Open {
         
         dispatch_once(&dispatchOnceToken, { self.delegate?.socketDidConnect(self) })
      }
      
   }
   
}