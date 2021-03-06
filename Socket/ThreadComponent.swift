//
//  NetworkThread.swift
//  Socket
//
//  Created by Andrew Visotskyy on 1/30/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal class ThreadComponent: NSObject {
	
	private var thread: Thread?
	private let condition: NSLock
	private let semaphore: DispatchSemaphore
	
	internal static func detachNew() -> ThreadComponent {
		let component = ThreadComponent()
		component.start()
		return component
	}
	
	internal override init() {
		condition = NSLock()
		semaphore = DispatchSemaphore(value: 0)
		super.init()
	}
	
	deinit {
		self.stop()
	}
	
	internal func start() {
		condition.lock()
		if thread == nil {
			thread = Thread(with: threadProc)
			thread?.start()
			semaphore.wait()
		}
		condition.unlock()
	}
	
	internal func stop() {
		self.condition.lock()
		if let thread = self.thread {
			thread.perform {
				CFRunLoopStop(CFRunLoopGetCurrent())
			}
			self.thread = nil
		}
		condition.unlock()
	}
	
	@objc private func threadProc() {
		var context = CFRunLoopSourceContext()
		context.version = 0
		context.perform = { pointer in }
		var source = CFRunLoopSourceCreate(nil, 0, &context)
		CFRunLoopAddSource(CFRunLoopGetCurrent(), source, CFRunLoopMode.commonModes)
		self.semaphore.signal()
		CFRunLoopRun()
		//Will get here after run loop will stop execution
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, CFRunLoopMode.commonModes)
		source = nil
	}
	
	internal func perform(block: @escaping () -> Void) {
		condition.lock()
		thread?.perform(block)
		condition.unlock()
	}
	
}
