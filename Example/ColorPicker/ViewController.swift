//
//  ViewController.swift
//  ColorPicker
//
//  Created by Tom Knapen on 03/31/2017.
//  Copyright (c) 2017 Tom Knapen. All rights reserved.
//

import ColorPicker
import UIKit

class ViewController: UIViewController {

	let colorPicker = ColorPicker()

    override func viewDidLoad() {
        super.viewDidLoad()

		colorPicker.translatesAutoresizingMaskIntoConstraints = true
		colorPicker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		colorPicker.frame = view.bounds
		view.addSubview(colorPicker)

		colorPicker.delegate = self
    }

	func colorChanged(_ sender: ColorPicker) {
		view.backgroundColor = sender.color
	}

}

extension ViewController: ColorPickerDelegate {

	func colorPicker(_ colorPicker: ColorPicker, didFinishPickingWithColor color: UIColor) {
		view.backgroundColor = color
	}

}
