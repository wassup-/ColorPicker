//
//  HueCircleLayer.swift
//  ColorPicker-Swift
//
//  Created by Tom Knapen on 31/03/2017.
//

import CoreGraphics
import QuartzCore
import UIKit.UIColor

class HueCircleLayer: CALayer {

	let thicknessRatio: CGFloat = 0.2

	var slices: UInt = 0 {
		didSet { setNeedsDisplay() }
	}

	convenience init(_ slices: UInt) {
		self.init()
		self.slices = slices
	}

	override func draw(in ctx: CGContext) {
		super.draw(in: ctx)

		let radius: CGFloat = min(bounds.width, bounds.height) / 2.0
		let thickness: CGFloat = radius * thicknessRatio
		let innerRadius: CGFloat = radius - thickness

		let sliceAngle: CGFloat = CGFloat(2 * M_PI) / CGFloat(slices)
		let sliceAngle_2: CGFloat = sliceAngle / 2.0

		let path = CGMutablePath()
		path.move(to: CGPoint(x: cos(-sliceAngle_2) * innerRadius,
		                      y: sin(-sliceAngle_2) * innerRadius))
		path.addArc(center: .zero,
		            radius: innerRadius,
		            startAngle: -sliceAngle_2,
		            endAngle: sliceAngle_2 + 1.0e-2,
		            clockwise: false)
		path.addArc(center: .zero,
		            radius: radius,
		            startAngle: sliceAngle_2 + 1.0e-2,
		            endAngle: -sliceAngle_2,
		            clockwise: true)
		path.closeSubpath()

		ctx.translateBy(x: bounds.width / 2.0,
		                y: bounds.height / 2.0)

		for i in 0 ..< slices {
			let color = UIColor(hue: CGFloat(i) / CGFloat(slices),
			                    saturation: 1,
			                    brightness: 1,
			                    alpha: 1)
			ctx.addPath(path)
			ctx.setFillColor(color.cgColor)
			ctx.fillPath()
			ctx.rotate(by: -sliceAngle)
		}
	}

}
