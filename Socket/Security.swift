//
//  Security.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/10/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
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
