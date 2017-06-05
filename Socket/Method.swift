//
//  Weak.swift
//  Socket
//
//  Created by Andrew Visotskyy on 6/5/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal class Method {
	
	internal static func weak<T: AnyObject, A, B> (_ object: T, _ method: @escaping (T) -> (A, B) -> Void) -> (A, B) -> Void {
		return { [weak object] in
			guard let object = object else {
				return
			}
			method(object)($0, $1)
		}
	}
	
}
