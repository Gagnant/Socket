//
//  Socket.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/22/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

public protocol TCPSocketDelegate {
   
   func socketDidConnect    (_ socket: TCPSocket)
   func socketDidDisconnect (_ socket: TCPSocket)
   
   func socket (_ socket: TCPSocket, didReceiveData data: Data)
   func socket (_ socket: TCPSocket, didFailWithError error: NSError)
   
}

public class TCPSocket {
   
   public let queue = DispatchQueue(label: "com.gagnant.socket.socketqueue", attributes: [])

   public var delegate: TCPSocketDelegate?
   
   private(set) public var status:  Status
   private(set) public var host:    String
   private(set) public var port:    Int
   private(set) public var options: Settings
   
   private var outputStreamDelegate: StreamDelegate?
   private var inputStreamDelegate:  StreamDelegate?
   private var outputStream:         OutputStream?
   private var inputStream:          InputStream?
   private var runLoop:              RunLoop?

   public init(host: String, port: Int) {
      
      options = [
         SocketSecurityLevel:SocketSecurityLevelNegotiated as AnyObject,
         SocketValidatesCertificateChain:true as AnyObject
      ]
      
      self.runLoop  = nil
      self.delegate = nil
      self.status   = .closed
      self.port     = port
      self.host     = host
      
      inputStreamDelegate  = StreamDelegate(cInputStream )
      outputStreamDelegate = StreamDelegate(cOutputStream)
   }
   
   public convenience init(host: String, port: Int, settings: Settings) {
      self.init(host: host, port: port)
      
      settings.forEach {
         options[$0.key] = $0.value
      }
   }

   deinit {
      disconnect()
   }

   open func connect() {
      
      if self.status != .closed {
         self.disconnect()
      }
      
      self.status = .opening
      
      Stream.getStreamsToHost(withName: host, port: port, inputStream: &inputStream,
                                                         outputStream: &outputStream)
      
      inputStream! .delegate = inputStreamDelegate       
      outputStream!.delegate = outputStreamDelegate       
      
      self.parseSettings()
      
      queue.async {
         
         self.inputStream! .schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
         self.outputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
         
         self.inputStream! .open()
         self.outputStream!.open()

         self.runLoop = RunLoop.current
         self.runLoop?.run()
      }
   }
   
   open func disconnect() { runLoop?.performAndWakeUp {
      
      self.inputStream? .close()
      self.outputStream?.close()
      
      self.inputStream? .remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
      self.outputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
      
      self.inputStream? .delegate = nil
      self.outputStream?.delegate = nil
      
      self.inputStream  = nil
      self.outputStream = nil
      
      self.status = .closed
      self.delegate?.socketDidDisconnect(self)
   }}
   
   open func write(_ text: String) { runLoop?.performAndWakeUp {
      
      guard self.status == .opened else {
         return
      }
      
      let data = Array(text.utf8)
      let length = data.count
		
      self.outputStream?.write(data, maxLength: length)
   }}

   private func cInputStream(_ stream: Stream, event: Stream.Event) {
      
      switch event {
         
         case Stream.Event.openCompleted:
            self.handleSocketOpenning()
         
         case Stream.Event.errorOccurred:
            delegate?.socket(self, didFailWithError: stream.streamError! as NSError)
            disconnect()
         
         case Stream.Event.hasBytesAvailable:
            let data = inputStream!.readAllData()
				delegate?.socket(self, didReceiveData: data)
			
         case Stream.Event.endEncountered:
            self.disconnect()
         
         default: break
      }
   }

   private func cOutputStream(_ stream: Stream, event: Stream.Event) {
		
      switch event {
         
         case Stream.Event.openCompleted:
            self.handleSocketOpenning()
         
         case Stream.Event.errorOccurred:
            delegate?.socket(self, didFailWithError: stream.streamError! as NSError)
            disconnect()
         
         default: break
      }
   }

   private func parseSettings() {
      
      if options[SocketSecurityLevel] as? String == SocketSecurityLevelNegotiated {
      
         inputStream! .setProperty(StreamSocketSecurityLevel.negotiatedSSL as Any, forKey: Stream.PropertyKey.socketSecurityLevelKey)
         outputStream!.setProperty(StreamSocketSecurityLevel.negotiatedSSL as Any, forKey: Stream.PropertyKey.socketSecurityLevelKey)
      
         if options[SocketValidatesCertificateChain] as? Bool == false {
            
            let settings = [
               kCFStreamSSLValidatesCertificateChain as String: kCFBooleanFalse
            ]
            
            let property = CFStreamPropertyKey(kCFStreamPropertySSLSettings)
            let value    = settings as CFTypeRef
            
            CFReadStreamSetProperty (inputStream,  property, value)
            CFWriteStreamSetProperty(outputStream, property, value)
         }
      }
   }
   
   private func handleSocketOpenning() {
      
      guard self.status == .opening else {
         return
      }
      
      if inputStream!.streamStatus  == Stream.Status.open &&
         outputStream!.streamStatus == Stream.Status.open {
         
         delegate?.socketDidConnect(self)
         status = .opened
      }
   }
   
}

