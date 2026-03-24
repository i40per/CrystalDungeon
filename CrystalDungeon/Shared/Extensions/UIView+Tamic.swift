//
//  UIView+Tamic.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 21.03.2026.
//

import UIKit

// MARK: - UIView Layout Utilities
extension UIView {

    // MARK: - Layout Helpers
    /// Creates a view with Auto Layout enabled and applies initial configuration.
    static func disableTamic<T: UIView>(view: T, completion: (T) -> Void) -> T {
        view.translatesAutoresizingMaskIntoConstraints = false
        completion(view)
        return view
    }

    /// Adds multiple subviews in a single call.
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }

    /// Returns the nearest superview of the specified type.
    func superview<T>(of type: T.Type) -> T? {
        var currentView: UIView? = self

        while let view = currentView {
            if let typedView = view as? T {
                return typedView
            }
            currentView = view.superview
        }

        return nil
    }
}
