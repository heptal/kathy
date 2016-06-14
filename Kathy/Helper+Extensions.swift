//
//  Helper+Extensions.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa

extension NSView {

    var allSubviews: [NSView] {
        return allSubviewsWithDepth(Int.max)
    }

    func allSubviewsWithDepth(depth: Int) -> [NSView] {
        var allSubviews: [NSView] = []
        guard depth >= 0 else { return allSubviews }

        self.subviews.forEach { (subview) in
            allSubviews.append(subview)
            allSubviews.appendContentsOf(subview.allSubviewsWithDepth(depth - 1))
        }

        return allSubviews
    }

    func subviewWithIdentifier(identifier: String) -> NSView? {
        return self.allSubviews.filter { $0.identifier == identifier }.first
    }

}

extension String {

    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }

    func split(separator: String?) -> [String] {
        return self.componentsSeparatedByString(separator ?? " ")
    }

}

extension NSLayoutConstraint {

    class func soloConstraint(item: AnyObject, attr: NSLayoutAttribute, relation: NSLayoutRelation, amount: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: item, attribute: attr, relatedBy: relation, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: amount)
    }

}
