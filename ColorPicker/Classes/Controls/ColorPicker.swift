//
//  ColorPicker.swift
//  ColorPicker-Swift
//
//  Created by Tom Knapen on 31/03/2017.
//

import UIKit

public protocol ColorPickerDelegate: class {

	func colorPicker(_ colorPicker: ColorPicker, didFinishPickingWithColor color: UIColor)

}

open class ColorPicker: UIControl, UIGestureRecognizerDelegate {

	// MARK: Private properties

	internal let layerHueCircle: HueCircleLayer = HueCircleLayer()
	internal let layerSaturationBrightnessBox: SaturationBrightnessLayer = SaturationBrightnessLayer()
	internal let layerHueMarker: MarkerLayer = MarkerLayer()
	internal let layerSaturationBrightnessMarker: MarkerLayer = MarkerLayer()

	internal var _hue: CGFloat {
		get { return layerSaturationBrightnessBox.hue }
		set { layerSaturationBrightnessBox.hue = newValue }
	}

	internal var _saturation: CGFloat = 0
	internal var _brightness: CGFloat = 0
	internal var _alpha: CGFloat = 1

	internal var _radius: CGFloat = 0
	internal var _boxSize: CGFloat {
		let kBoxThickness: CGFloat = 0.7
		return sqrt(kBoxThickness * kBoxThickness * _radius * _radius / 2.0) * 2.0
	}
	internal var _center: CGPoint {
		return CGPoint(x: bounds.midX, y: bounds.midY)
	}

	internal var _thickness: CGFloat {
		let kCircleThickness: CGFloat = 0.2
		return kCircleThickness * _radius
	}

	internal var hueGestureRecognizer: UILongPressGestureRecognizer!
	internal var saturationBrightnessGestureRecognizer: UILongPressGestureRecognizer!

	// MARK: Public properties

	open weak var delegate: ColorPickerDelegate? = nil

	open var slices: UInt {
		get { return layerHueCircle.slices }
		set { layerHueCircle.slices = newValue }
	}

	open var color: UIColor {
		get { return UIColor(hue: _hue, saturation: _saturation, brightness: _brightness, alpha: _alpha) }
		set {
			if !newValue.getHue(&_hue, saturation: &_saturation, brightness: &_brightness, alpha: &_alpha) {
				_hue = 0
				_saturation = 0
				newValue.getWhite(&_brightness, alpha: &_alpha)
			}

			updateMarkerPositions()
		}
	}

	// MARK: Initializers

	public convenience init(slices: UInt = 256) {
		self.init(frame: .zero)
		self.slices = slices
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}

	open override func awakeFromNib() {
		super.awakeFromNib()
		commonInit()
	}

	private func commonInit() {
		isOpaque = false
		color = .white

		addSublayer(layerHueCircle, to: layer, fill: true)
		addSublayer(layerSaturationBrightnessBox, to: layer, fill: true)

		addSublayer(layerHueMarker, to: layer, fill: false)
		addSublayer(layerSaturationBrightnessMarker, to: layer, fill: false)

		hueGestureRecognizer = createLongPressGestureRecognizer(action: #selector(self.handleDragHue(_:)))
		saturationBrightnessGestureRecognizer = createLongPressGestureRecognizer(action: #selector(self.handleDragSaturationBrightness(_:)))

		addGestureRecognizer(hueGestureRecognizer)
		addGestureRecognizer(saturationBrightnessGestureRecognizer)

		slices = 256
	}

	override open func layoutSubviews() {
		super.layoutSubviews()
		let resolution = min(bounds.width, bounds.height)
		_radius = resolution / 2.0

		updateMarkerPositions()
	}

	override open func layoutSublayers(of layer: CALayer) {
		super.layoutSublayers(of: layer)
		layer.sublayers?.forEach { layoutSublayer($0, of: layer) }
	}

	override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		switch gestureRecognizer {
		case hueGestureRecognizer:
			let position = gestureRecognizer.location(in: self)
			let dSquared = _center.squaredDistance(to: position)
			return ((_radius - _thickness) * (_radius - _thickness)) < dSquared && (dSquared < (_radius * _radius))
		case saturationBrightnessGestureRecognizer:
			let position = gestureRecognizer.location(in: self)
			let saturation = (position.x - center.x) / _boxSize + 0.5
			let brightness = (position.y - center.y) / _boxSize + 0.5
			return (saturation > -0.1) && (saturation < 1.1) && (brightness > -0.1) && (brightness < 1.1)
		default:
			return super.gestureRecognizerShouldBegin(gestureRecognizer)
		}
	}

}

// MARK: Helper functions
extension ColorPicker {

	fileprivate func notifyColorChanged() {
		sendActions(for: .valueChanged)
		delegate?.colorPicker(self, didFinishPickingWithColor: color)

		print("H: \(_hue), S: \(_saturation), B: \(_brightness), A: \(_alpha), slices: \(slices)")
	}

	fileprivate func createLongPressGestureRecognizer(action: Selector) -> UILongPressGestureRecognizer {
		let recognizer = UILongPressGestureRecognizer(target: self, action: action)
		recognizer.minimumPressDuration = 0
		recognizer.allowableMovement = .greatestFiniteMagnitude
		recognizer.delegate = self
		return recognizer
	}

	fileprivate func addSublayer(_ sublayer: CALayer, to layer: CALayer, fill: Bool) {
		if fill {
			sublayer.frame = bounds
		}

		layer.addSublayer(sublayer)
		sublayer.setNeedsDisplay()
	}

	fileprivate func layoutSublayer(_ sublayer: CALayer, of layer: CALayer) {
		switch sublayer {
		case layerHueCircle:
			sublayer.frame = bounds
		case layerSaturationBrightnessBox:
			sublayer.frame = CGRect(x: (bounds.width - _boxSize) / 2.0,
			                        y: (bounds.height - _boxSize) / 2.0,
			                        width: _boxSize,
			                        height: _boxSize)
		default:
			break
		}
	}

	fileprivate func hueMarkerFrame() -> CGRect {
		let radians: CGFloat = CGFloat(2 * M_PI) * _hue
		let position = CGPoint(x: cos(radians) * (_radius  - _thickness / 2.0),
		                       y: -sin(radians) * (_radius - _thickness / 2.0))
		return CGRect(x: (position.x - _thickness / 2.0) + (bounds.width / 2.0),
		              y: (position.y - _thickness / 2.0) + (bounds.height / 2.0),
		              width: _thickness,
		              height: _thickness)
	}

	fileprivate func saturationBrightnessMarkerFrame() -> CGRect {
		return CGRect(x: (_saturation * _boxSize) - (_boxSize / 2.0) - (_thickness / 2.0) + (bounds.width / 2.0),
		              y: ((1.0 - _brightness) * _boxSize) - (_boxSize / 2.0) - (_thickness / 2.0) + (bounds.height / 2.0),
		              width: _thickness,
		              height: _thickness)
	}

	fileprivate func updateMarkerPositions() {
		layerHueMarker.frame = hueMarkerFrame()
		layerSaturationBrightnessMarker.frame = saturationBrightnessMarkerFrame()
	}

}

// MARK: Interaction
extension ColorPicker {

	@objc fileprivate func handleDragHue(_ sender: UILongPressGestureRecognizer) {
		switch sender.state {
		case .began, .changed:
			let position = sender.location(in: self)
			let dSquared = _center.squaredDistance(to: position)
			guard dSquared > 1.0e-3 else { return }

			let radians = atan2(_center.y - position.y, position.x - _center.x)

			var hue = radians / CGFloat(2 * M_PI)
			if hue < 0 {
				hue += 1
			}
			_hue = hue

			CATransaction.begin()
			CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
			updateMarkerPositions()
			CATransaction.commit()

			notifyColorChanged()
		default:
			break
		}
	}

	@objc fileprivate func handleDragSaturationBrightness(_ sender: UILongPressGestureRecognizer) {
		switch sender.state {
		case .began, .changed:
			let position = sender.location(in: self)
			_saturation = max(0, min(1, (position.x - _center.x) / _boxSize + 0.5))
			_brightness = max(0, min(1, (_center.y - position.y) / _boxSize + 0.5))

			CATransaction.begin()
			CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
			updateMarkerPositions()
			CATransaction.commit()

			notifyColorChanged()
		default:
			break
		}
	}
}
