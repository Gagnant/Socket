//
//  RunLoopInvoker.swift
//  Socket
//
//  Created by Andrew Visotskyy on 9/16/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal typealias Block = () -> Swift.Void

fileprivate class InvocationContext {
   
   var source  : CFRunLoopSource!
   var blocks  : [Block]
   
   init(_ source: CFRunLoopSource) {
      self.source = source
      self.blocks = []
   }
   
   init() {
      self.source = nil
      self.blocks = []
   }
   
}

internal class RunLoopInvoker {

   static fileprivate let queue = DispatchQueue(label: "com.gagnant.runloopinvoker.sync")
   
   
   static fileprivate var info: [RunLoop:InvocationContext] = [:]
   
   static internal func invoke(onRunLoop runLoop: RunLoop, _ block: @escaping Block) {
   
      let context = RunLoopInvoker.context(forRunLoop: runLoop)
      let runLoop = runLoop.getCFRunLoop()
      
      queue.sync {
         context.blocks.append(block)
      }
      
      CFRunLoopSourceSignal(context.source)
      CFRunLoopWakeUp      (runLoop)
   }
   
   fileprivate static func context(forRunLoop runLoop: RunLoop) -> InvocationContext {
      
      if let context = RunLoopInvoker.info[runLoop] {
         return context
      }
      
      var context = CFRunLoopSourceContext()
      
      context.version = 0
      context.perform = { pointer in

         var blocks: [Block] = []
         
         RunLoopInvoker.queue.sync {
         
            let context = RunLoopInvoker.info[RunLoop.current]!
            
            blocks = context.blocks
                     context.blocks.removeAll()
         }
         
         blocks.forEach { block in block() }
      }
            
      let source   = CFRunLoopSourceCreate(nil, 0, &context)
      let iContext = InvocationContext()
      
      CFRunLoopAddSource(runLoop.getCFRunLoop(), source!, CFRunLoopMode.defaultMode)
   
      iContext.source = source!
      info[runLoop]   = iContext
      
      return iContext
   }
   
}

