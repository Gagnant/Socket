//
//  Extensions.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/27/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal extension InputStream {
  
  internal func readAllData() -> Data {
    let data = NSMutableData()
    var buffer = [UInt8](repeating: 0, count: 4096)
    while self.hasBytesAvailable {
      let length = read(&buffer, maxLength: buffer.count)
      if length > 0 {
        data.append(buffer, length: length)
      }
    }
    return data as Data
  }
  
}
