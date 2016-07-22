//
//  Options.swift
//  Socket
//
//  Created by Andrew Visotskyy on 7/22/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

public typealias Settings = Dictionary<String, AnyObject>

/*  Security property key indicating the security level of
 *  the target stream.
 */
public let SocketSecurityLevelKey = "SocketSecurityLevelKey"

/*  Specifies that the highest level security protocol that
 *  can be negotiated be set as the security protocol for a
 *  socket stream
 */
public let SocketSecurityLevelNegotiated = "SocketSecurityLevelNegotiated"

/*  Specifies that no security level be set for a socket
 *  stream.
 */
public let SocketSecurityLevelNone = "SocketSecurityLevelNone"

/*  Security property key indicating whether the certificate
 *  chain should be validated or not.  The value is true by
 *  default (not set).
 */
public let SocketValidatesCertificateChainKey = "SocketValidatesCertificateChainKey"