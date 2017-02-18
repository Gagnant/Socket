//
//  Socket.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/22/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

public protocol TCPSocketDelegate {
	
	func socketDidConnect (_ socket: TCPSocket)
	func socketDidDisconnect (_ socket: TCPSocket)
	
	func socket (_ socket: TCPSocket, didReceiveData data: Data)
	func socket (_ socket: TCPSocket, didFailWithError error: Error)
	
}

public class TCPSocket {
	
	public enum Status {
		case opening, opened, closed, error
	}
	
	private(set) public var delegate: TCPSocketDelegate?
	private(set) public var delegateQueue: DispatchQueue?
	private(set) public var status: Status
	private(set) public var config: Config
	
	// MARK: -
	
	private static let workingThread = ThreadComponent.detachNew()
	
	private var inputStreamDelegate: StreamDelegate?
	private var outputStreamDelegate: StreamDelegate?
	private var inputStream: InputStream?
	private var outputStream: OutputStream?
	
	// MARK: -
	
	public init(with config: Config) {
		self.config = config
		self.status = .closed
		inputStreamDelegate = StreamDelegate(cInputStream)
		outputStreamDelegate = StreamDelegate(cOutputStream)
	}
	
	public convenience init(with config: Config, delegate: TCPSocketDelegate, delegateQueue: DispatchQueue = .main) {
		self.init(with: config)
		self.delegate = delegate
		self.delegateQueue = delegateQueue
	}
	
	deinit {
		disconnect()
	}
	
	public func connect() {
		TCPSocket.workingThread.perform {
			guard self.status == .closed else {
				return
			}
			
			Stream.getStreamsToHost(withName: self.config.host, port: self.config.port,
			                        inputStream: &self.inputStream, outputStream: &self.outputStream)
			
			self.status = .opening
			
			self.inputStream!.delegate = self.inputStreamDelegate
			self.inputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
			self.inputStream!.open()
			
			self.outputStream!.delegate = self.outputStreamDelegate
			self.outputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
			self.outputStream!.open()
		}
	}
	
	public func disconnect() {
		TCPSocket.workingThread.perform {
			self.inputStream?.close()
			self.inputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
			self.inputStream = nil
			
			self.outputStream?.close()
			self.outputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
			self.outputStream = nil
			
			self.status = .closed
			self.delegateQueue?.async {
				self.delegate?.socketDidDisconnect(self)
			}
		}
	}
	
	public func write(_ data: Data) {
		TCPSocket.workingThread.perform {
			guard self.status == .opened else {
				return
			}
			let bytes = [UInt8](data)
			self.outputStream?.write(bytes, maxLength: bytes.count)
		}
	}
	
	public func write(_ text: String) {
		TCPSocket.workingThread.perform {
			guard self.status == .opened else {
				return
			}
			let bytes = Array(text.utf8)
			self.outputStream?.write(bytes, maxLength: bytes.count)
		}
	}
	
	// MARK: - Private Section
	
	private func cInputStream(_ stream: Stream, event: Stream.Event) {
		switch event {
			case Stream.Event.openCompleted:
				handleOpenning()
			case Stream.Event.errorOccurred:
				handleError(error: stream.streamError!)
			case Stream.Event.hasBytesAvailable:
				let data = inputStream!.readAllData()
				delegateQueue?.async {
					self.delegate?.socket(self, didReceiveData: data)
				}
			case Stream.Event.endEncountered:
				self.disconnect()
			default: break
		}
	}
	
	private func cOutputStream(_ stream: Stream, event: Stream.Event) {
		switch event {
			case Stream.Event.openCompleted:
				handleOpenning()
			case Stream.Event.errorOccurred:
				handleError(error: stream.streamError!)
			default: break
		}
	}
	
	private func parseSettings() {
		if case Security.negitiated(let validates) = self.config.security {
			inputStream!.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)
			outputStream!.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)
			if !validates {
				let settings = [kCFStreamSSLValidatesCertificateChain as String: kCFBooleanFalse] as CFTypeRef
				let property = CFStreamPropertyKey(kCFStreamPropertySSLSettings)
				CFReadStreamSetProperty (inputStream, property, settings)
				CFWriteStreamSetProperty(outputStream, property, settings)
			}
		}
	}
	
	private func handleOpenning() {
		guard status == .opening,
		      inputStream!.streamStatus == .open,
		      outputStream!.streamStatus == .open else {
			return
		}
		status = .opened
		delegateQueue?.async {
			self.delegate?.socketDidConnect(self)
		}
	}
	
	private func handleError(error: Error) {
		guard status != .error else {
			return
		}
		status = .error
		delegateQueue?.async {
			self.delegate?.socket(self, didFailWithError: error)
		}
		disconnect()
	}
	
}
