//
//  Options.swift
//  Socket
//
//  Created by Andrew Visotskyy on 7/22/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

public enum Security {
   
  /// Specifies that no security level be set for a socket stream
  case none
   
  /// Specifies that the highest level security protocol that can be negotiated
  /// be set as the security protocol for a socket stream. The parameter is
  /// indicating whether the certificate chain should be validated or not
  case negitiated(validates: Bool)
  
}

public struct Settings {
   
  /// Security property indicating the security level of the target stream.
  public let security: Security
  
  // MARK: - Initializers
  
  public init(security: Security) {
    self.security = security
  }
  
}

// MARK: - Defaults

extension Security {
  public static var `default`: Security {
    return Security.negitiated(validates: true)
  }
}

extension Settings {
	public static var `default`: Settings {
  	return Settings(security: .default, reconnection: .default)
	}
}
