//
//  Options.swift
//  Socket
//
//  Created by Andrew Visotskyy on 7/22/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

public enum Security {
	
	/// Specifies that no security level be set for a socket stream
	case none
	
	/// Specifies that the highest level security protocol that can be negotiated
	/// be set as the security protocol for a socket stream. The parameter is
	/// indicating whether the certificate chain should be validated or not
	case negitiated(validates: Bool)
	
	// MARK: - Factory Initialization Methods
	
	public static var `default`: Security {
		return Security.negitiated(validates: true)
	}
	
}

public struct Config {
	
	/// The host this connection be connected to.
	public var host: String
	
	/// The port this connection to be connected on.
	public var port: Int
	
	/// Security property indicating the security level of the target stream.
	public var security: Security
	
	// MARK: - Initializers
	
	public init(host: String, port: Int, security: Security = .default) {
		self.host = host
		self.port = port
		self.security = security
	}
	
}
