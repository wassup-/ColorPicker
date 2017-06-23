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

	/// The layer representing the hue circle
	internal let layerHueCircle: HueCircleLayer = HueCircleLayer()
	/// The layer representing the hue marker
	internal let layerHueMarker: MarkerLayer = MarkerLayer()
	/// The layer representing the saturation/brightness box
	internal let layerSaturationBrightnessBox: SaturationBrightnessLayer = SaturationBrightnessLayer()
	/// The layer representing the saturation/brightness marker
	internal let layerSaturationBrightnessMarker: MarkerLayer = MarkerLayer()

	/// The *hue* component of the currently selected color
	internal var _hue: CGFloat {
		get { return layerSaturationBrightnessBox.hue }
		set { layerSaturationBrightnessBox.hue = newValue }
	}

	/// The *saturation* component of the currently selected color
	internal var _saturation: CGFloat = 0
	/// The *brightness* component of the currently selected color
	internal var _brightness: CGFloat = 0
	/// The *alpha* component of the currently selected color
	internal var _alpha: CGFloat = 1

	/// The radius of the hue wheel
	internal var _radius: CGFloat = 0
	/// The size of the saturation/brightness box
	internal var _boxSize: CGFloat {
		let kBoxThickness: CGFloat = 0.7
		return sqrt(kBoxThickness * kBoxThickness * _radius * _radius / 2.0) * 2.0
	}
	/// The center of our view
	internal var _center: CGPoint {
		return CGPoint(x: bounds.midX, y: bounds.midY)
	}
	/// The thickness of the marker's border
	internal var _thickness: CGFloat {
		let kCircleThickness: CGFloat = 0.2
		return kCircleThickness * _radius
	}

	/// The hue gesture recognizer
	internal var hueGestureRecognizer: UILongPressGestureRecognizer!
	/// The saturation/brightness gesture recognizer
	internal var saturationBrightnessGestureRecognizer: UILongPressGestureRecognizer!

	// MARK: Public properties

	/// The delegate object
	open weak var delegate: ColorPickerDelegate? = nil

	/// Number of slices used to represent the color wheel
	open var slices: UInt {
		get { return layerHueCircle.slices }
		set { layerHueCircle.slices = newValue }
	}

	/// The currently selected color
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

	/// Send actions and notify delegate related to color changes
	fileprivate func notifyColorChanged() {
		sendActions(for: .valueChanged)
		delegate?.colorPicker(self, didFinishPickingWithColor: color)
	}

	/// Creates and returns a long press gesture recognizer with `self` as it's target
	/// - parameter action: The selector to send when a gesture is recognized
	/// - returns: A long press gesture recognizer that sends `action` to `self` upon recognition
	fileprivate func createLongPressGestureRecognizer(action: Selector) -> UILongPressGestureRecognizer {
		let recognizer = UILongPressGestureRecognizer(target: self, action: action)
		recognizer.minimumPressDuration = 0
		recognizer.allowableMovement = .greatestFiniteMagnitude
		recognizer.delegate = self
		return recognizer
	}

	/// Adds `sublayer` as a sublayer to `layer`, optionally setting it's frame to fill `layer`'s bounds
	/// - parameter sublayer: The layer to add as a sublayer to `layer`
	/// - parameter layer: The layer to add `sublayer` to
	/// - parameter fill: Whether or not to modify `sublayer`s frame to fill `layer`s bounds
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
		let radians: CGFloat = CGFloat(2 * Double.pi) * _hue
		let halfThickness: CGFloat = _thickness / 2.0
		let position = CGPoint(x: cos(radians) * (_radius  - halfThickness),
		                       y: -sin(radians) * (_radius - halfThickness))
		return CGRect(x: (position.x - halfThickness) + (bounds.width / 2.0),
		              y: (position.y - halfThickness) + (bounds.height / 2.0),
		              width: _thickness,
		              height: _thickness)
	}

	fileprivate func saturationBrightnessMarkerFrame() -> CGRect {
		let halfThickness: CGFloat = _thickness / 2.0
		let halfSize: CGFloat = _boxSize / 2.0
		return CGRect(x: (_saturation * _boxSize) - halfSize - halfThickness + (bounds.width / 2.0),
		              y: ((1.0 - _brightness) * _boxSize) - halfSize - halfThickness + (bounds.height / 2.0),
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

			var hue = radians / CGFloat(2 * Double.pi)
			if hue < 0 {
				hue += 1
			}
			_hue = hue

			CATransaction.begin()
			CATransaction.setDisableActions(true)
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
			CATransaction.setDisableActions(true)
			updateMarkerPositions()
			CATransaction.commit()
			
			notifyColorChanged()
		default:
			break
		}
	}
}
