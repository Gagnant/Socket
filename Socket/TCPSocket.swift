//
//  Socket.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/22/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

public protocol TCPSocketDelegate: class {

	/// Called when a transport connects and is ready for reading and writing.
	func socketDidConnect(_ socket: TCPSocket)

	/// Called when a socket disconnects with or without error.
	///
	/// If you call the disconnect method, and the socket wasn't already disconnected,
	/// then an invocation of this delegate method will be enqueued on the delegateQueue
	/// before the disconnect method returns.
	func socket(_ socket: TCPSocket, didDisconnectWithError error: Error?)

	/// Called when a socket has read in data.
	func socket(_ socket: TCPSocket, didReceiveData data: Data)
	
	/// Called when an error occurs in socket.
	func socket(_ socket: TCPSocket, didFailWithError error: Error)

}

public class TCPSocket {
	
	public enum Status {
		case opening, opened, closed(Error?)
	}

	// MARK: -
	
	private(set) public weak var delegate: TCPSocketDelegate?
	
	private(set) public var delegateQueue: DispatchQueue?
	private(set) public var status: Status
	private(set) public var config: Config
	
	private static let workingThread = ThreadComponent.detachNew()
	
	private var inputStreamDelegate: StreamDelegate?
	private var outputStreamDelegate: StreamDelegate?
	private var inputStream: InputStream?
	private var outputStream: OutputStream?
	
	// MARK: -
	
	public init(with config: Config) {
		self.config = config
		self.status = .closed(nil)
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
			guard case .closed = self.status else {
				return
			}
			self.status = .opening
			self.setupStreams()
		}
	}
	
	public func disconnect() {
		self.disconnect(withError: nil)
	}
	
	private func disconnect(withError error: Error?) {
		TCPSocket.workingThread.perform {
			if case .closed = self.status {
				return
			}
			self.disposeStreams()
			self.status = .closed(error)
			self.delegateQueue?.async {
				self.delegate?.socket(self, didDisconnectWithError: error)
			}
		}
	}
	
	public func write(_ data: Data) {
		TCPSocket.workingThread.perform {
			let bytes = [UInt8](data)
			self.outputStream?.write(bytes, maxLength: bytes.count)
		}
	}
	
	public func write(_ text: String) {
		TCPSocket.workingThread.perform {
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
				disconnect(withError: stream.streamError)
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
				disconnect(withError: stream.streamError)
			default: break
		}
	}
	
	private func handleOpenning() {
		guard case .opening = status, inputStream!.streamStatus == .open, outputStream!.streamStatus == .open else {
			return
		}
		status = .opened
		delegateQueue?.async {
			self.delegate?.socketDidConnect(self)
		}
	}
	
	private func setupSocketsSecurity() {
		if case Security.negitiated(let validates) = config.security {
			inputStream!.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)
			outputStream!.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)
			if !validates {
				let settings = [kCFStreamSSLValidatesCertificateChain as String: kCFBooleanFalse] as CFTypeRef
				let property = CFStreamPropertyKey(kCFStreamPropertySSLSettings)
				CFReadStreamSetProperty(inputStream, property, settings)
				CFWriteStreamSetProperty(outputStream, property, settings)
			}
		}
	}
	
	private func setupStreams() {
		Stream.getStreamsToHost(withName: config.host, port: config.port, inputStream: &inputStream, outputStream: &outputStream)
		setupSocketsSecurity()
		inputStream!.delegate = inputStreamDelegate
		outputStream!.delegate = outputStreamDelegate
		inputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		outputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		inputStream!.open()
		outputStream!.open()
	}
	
	private func disposeStreams() {
		self.inputStream?.close()
		self.outputStream?.close()
		self.inputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		self.outputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		self.inputStream = nil
		self.outputStream = nil
	}
	
}
