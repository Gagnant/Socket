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
		
		/// Socket is in the process of connecting.
		case opening
		
		/// Socket is opened and is ready for use.
		case opened
		
		/// Socket is closed with optional error.
		case closed(Error?)
	}

	// MARK: - Properties
	
	private static let workingThread = ThreadComponent.detachNew()

	private var unsafeDelegateQueue: DispatchQueue
	private var unsafeStatus: Status

	private weak var unsafeDelegate: TCPSocketDelegate?
	
	private var inputStreamDelegate: StreamDelegate?
	private var outputStreamDelegate: StreamDelegate?
	private var inputStream: InputStream?
	private var outputStream: OutputStream?
	
	// MARK: - Public properties
	
	public var delegate: TCPSocketDelegate? {
		get {
			return synchronized(self) {
				return unsafeDelegate
			}
		}
		set {
			synchronized(self) {
				unsafeDelegate = newValue
			}
		}
	}
	
	/// Socket uses the standard delegate paradigm and executes all delegate callbacks on a given
	/// delegate dispatch queue.
	public var delegateQueue: DispatchQueue {
		get {
			return synchronized(self) {
				return unsafeDelegateQueue
			}
		}
		set {
			synchronized(self) {
				unsafeDelegateQueue = newValue
			}
		}
	}
	
	/// Returns the state of socket.
	///
	/// A disconnected socket may be recycled.
	/// That is, it can be used again for connecting.
	///
	/// If a socket is in the process of connecting, it may be neither disconnected nor connected.
	private(set) public var status: Status {
		get {
			return synchronized(self) {
				return unsafeStatus
			}
		}
		set {
			synchronized(self) {
				unsafeStatus = newValue
			}
		}
	}
	
	/// Returns the configuration which was used to create the socket.
	public let config: Config
	
	// MARK: - Lifecycle
	
	public init(with config: Config, delegate: TCPSocketDelegate? = nil, delegateQueue: DispatchQueue = .main) {
		self.config = config
		self.unsafeStatus = .closed(nil)
		self.unsafeDelegate = delegate
		self.unsafeDelegateQueue = delegateQueue
		inputStreamDelegate = StreamDelegate(cInputStream)
		outputStreamDelegate = StreamDelegate(cOutputStream)
	}
	
	deinit {
		disconnect()
	}
	
	// MARK: - Connecting
	
	/// Connects the socket.
	///
	/// This method will start a background connect operation and immediately return.
	///
	/// The delegate callbacks are used to notify you when the socket connects, or if the host
	/// was unreachable.
	public func connect() {
		TCPSocket.workingThread.perform {
			guard case .closed = self.status else {
				return
			}
			self.status = .opening
			self.setupStreams()
		}
	}
	
	// MARK: - Disconnecting
	
	/// Disconnects immediately (synchronously).
	///
	/// If the socket is not already disconnected, an invocation to the
	/// socket:didDisconnectWithError: delegate method will be queued onto the delegateQueue
	/// asynchronously. In other words, the delegate method will be invoked sometime shortly
	/// after this method returns.
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
			self.delegateQueue.async {
				self.delegate?.socket(self, didDisconnectWithError: error)
			}
		}
	}
	
	// MARK: - Writing
	
	/// Writes data to the socket. If you pass in zero-length data, this method does nothing.
	public func write(_ data: Data) {
		TCPSocket.workingThread.perform {
			let bytes = [UInt8](data)
			self.outputStream?.write(bytes, maxLength: bytes.count)
		}
	}

	/// Writes UTF-8 encoded string to the socket.
	public func write(_ text: String) {
		TCPSocket.workingThread.perform {
			let bytes = Array(text.utf8)
			self.outputStream?.write(bytes, maxLength: bytes.count)
		}
	}
	
	// MARK: - Private section
	
	private func cInputStream(_ stream: Stream, event: Stream.Event) {
		switch event {
			case Stream.Event.openCompleted:
				handleOpenning()
			case Stream.Event.errorOccurred:
				disconnect(withError: stream.streamError)
			case Stream.Event.hasBytesAvailable:
				let data = inputStream!.readAllData()
				delegateQueue.async {
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
		delegateQueue.async {
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
