//
//  CGPoint.swift
//  ColorPicker-Swift
//
//  Created by Tom Knapen on 31/03/2017.
//
//

import CoreGraphics

extension CGPoint {

	func squaredDistance(to other: CGPoint) -> CGFloat {
		return ((x - other.x) * (x - other.x)) + ((y - other.y) * (y - other.y))
	}

}
