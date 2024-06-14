//
//  SwizzlingMethodInfo.swift
//  LocationSimulator
//
//  Created by Victor Zyabko on 2024-06-11.
//

import Foundation

extension LocationSimulator {

	/// Create / Contain swizzling method information.
	class SwizzlingMethodInfo {

		// MARK: - Public

		/// Create swizzling method information. Does not swizzle right away, isSwizzled does it.
		init?(forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
			if let originalMethod = class_getInstanceMethod(forClass, originalSelector),
				let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) {
				self.forClass = forClass
				self.originalSelector = originalSelector
				self.originalMethod = originalMethod
				self.swizzledSelector = swizzledSelector
				self.swizzledMethod = swizzledMethod
			} else {
				return nil
			}
		}

		let forClass: AnyClass
		let originalSelector: Selector
		let originalMethod: Method
		let swizzledSelector: Selector
		let swizzledMethod: Method

		/// Do swizzle / unswizzle.
		var isSwizzled: Bool {
			get {
				return _isSwizzled
			}
			set {
				if _isSwizzled != newValue {
					_isSwizzled = newValue
					if _isSwizzled {
						method_exchangeImplementations(self.swizzledMethod, self.originalMethod)
					} else {
						method_exchangeImplementations(self.originalMethod, self.swizzledMethod)
					}
				}
			}
		}

		/// Do swizzle
		func swizzle() {
			self.isSwizzled = true
		}

		/// Do unswizzle
		func unswizzle() {
			self.isSwizzled = false
		}

		/// Use original method in handler.
		func usingOriginalMethod(handler: () -> ()) {
			if _isSwizzled {
				self.unswizzle()
				handler()
				self.swizzle()
			} else {
				handler()
			}
		}

		/// Use swizzled method in handler.
		func usingSwizzledMethod(handler: () -> ()) {
			if _isSwizzled {
				handler()
			} else {
				self.swizzle()
				handler()
				self.unswizzle()
			}
		}

		// MARK: - Private

		deinit {
			self.unswizzle()
		}

		private var _isSwizzled = false

		// MARK: -

	}

}
