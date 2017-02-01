//
//  Extensions+Thread.swift
//  Socket
//
//  Created by Andrew Visotskyy on 1/30/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

@objc private class InvocationContext: NSObject {
  
  private let block: () -> Void
  
  fileprivate init(with block: @escaping () -> Swift.Void) {
    self.block = block
  }
  
  @objc fileprivate func invoke() {
    self.block()
  }
  
}

extension Thread {
  
  @available(iOS 2.0, *)
  internal convenience init(with block: @escaping () -> Swift.Void) {
    let context = InvocationContext(with: block)
    self.init(target: context, selector: #selector(InvocationContext.invoke), object: nil)
  }
  
  @available(iOS 2.0, *)
  internal func perform(_ block: @escaping () -> Swift.Void) {
  	let context = InvocationContext(with: block)
    context.perform(#selector(InvocationContext.invoke), on: self, with: nil, waitUntilDone: false)
  }
  
}
