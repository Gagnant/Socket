//
//  Socket.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/22/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

public protocol TCPSocketDelegate {
  
  func socketDidConnect (_ socket: TCPSocket)
  func socketDidDisconnect (_ socket: TCPSocket)
  
  func socket (_ socket: TCPSocket, didReceiveData data: Data)
  func socket (_ socket: TCPSocket, didFailWithError error: Error)
  
}

public class TCPSocket {
  
  public var delegate: TCPSocketDelegate?
  public var delegateQueue: DispatchQueue = DispatchQueue.main
  
  private static let workingThread = ThreadComponent.detachNew()
  
  private(set) public var port: 		Int
  private(set) public var host: 		String
  private(set) public var status: 	Status
  private(set) public var settings: Settings
  
  private var outputStreamDelegate: StreamDelegate?
  private var inputStreamDelegate: 	StreamDelegate?
  private var outputStream: 				OutputStream?
  private var inputStream: 					InputStream?
  
  // MARK: -
  
  public init(host: String, port: Int, settings: Settings = Settings.default) {
    self.settings = settings
    self.status = .closed
    self.port = port
    self.host = host
    inputStreamDelegate = StreamDelegate(cInputStream)
    outputStreamDelegate = StreamDelegate(cOutputStream)
  }
  
  deinit {
    disconnect()
  }
  
  open func connect() {
    guard self.status == .closed else {
      return
    }
    Stream.getStreamsToHost(withName: host, port: port, inputStream: &inputStream, outputStream: &outputStream)

    status = .opening
    inputStream! .delegate = inputStreamDelegate
    outputStream!.delegate = outputStreamDelegate
    
    self.parseSettings()
    
    TCPSocket.workingThread.perform {
      self.inputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
      self.outputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
      self.inputStream!.open()
      self.outputStream!.open()
    }
  }
  
  open func disconnect() { TCPSocket.workingThread.perform {
    self.inputStream?.close()
    self.outputStream?.close()
    self.inputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    self.outputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    self.inputStream?.delegate = nil
    self.outputStream?.delegate = nil
    self.inputStream = nil
    self.outputStream = nil
    self.status = .closed
    self.delegate?.socketDidDisconnect(self)
  }}
  
  open func write(_ text: String) { TCPSocket.workingThread.perform {
    
    guard self.status == .opened else {
      return
    }
    
    let data = Array(text.utf8)
    let length = data.count
    
    self.outputStream?.write(data, maxLength: length)
  }}
  
  // MARK: - Private Section
  
  private func cInputStream(_ stream: Stream, event: Stream.Event) {
    switch event {
    	case Stream.Event.openCompleted:
      	self.handleOpenning()
    	case Stream.Event.errorOccurred:
      	handleError(error: stream.streamError!)
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
      	self.handleOpenning()
    	case Stream.Event.errorOccurred:
      	handleError(error: stream.streamError!)
    	default: break
    }
  }
  
  private func parseSettings() {
    if case Security.negitiated(let validates) = self.settings.security {
      inputStream!.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)
      outputStream!.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)
      if !validates {
        let settings = [kCFStreamSSLValidatesCertificateChain as String: kCFBooleanFalse]
        let property = CFStreamPropertyKey(kCFStreamPropertySSLSettings)
        let value = settings as CFTypeRef
        CFReadStreamSetProperty (inputStream, property, value)
        CFWriteStreamSetProperty(outputStream, property, value)
      }
    }
  }
  
  private func handleOpenning() {
    guard self.status == .opening else {
      return
    }
    if inputStream!.streamStatus == .open && outputStream!.streamStatus == .open {
      status = .opened
      delegate?.socketDidConnect(self)
    }
  }
  
  private func handleError(error: Error) {
    guard self.status != .error else {
      return
    }
    status = .error
    delegate?.socket(self, didFailWithError: error)
    disconnect()
  }
  
}
