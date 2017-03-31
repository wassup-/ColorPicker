//
//  MarkerLayer.swift
//  ColorPicker-Swift
//
//  Created by Tom Knapen on 31/03/2017.
//

import CoreGraphics
import OpenGLES
import QuartzCore
import UIKit.UIColor

class MarkerLayer: CALayer {

	let thickness: CGFloat = 3.0
	let color: UIColor = .gray

	override func draw(in ctx: CGContext) {
		super.draw(in: ctx)
		
		ctx.setLineWidth(thickness)
		ctx.setStrokeColor(color.cgColor)
		ctx.addEllipse(in: bounds.insetBy(dx: thickness, dy: thickness))
		ctx.strokePath()
	}

}
