/////
////  Extensions.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit

extension CGPoint {
  func constrained(to rect: CGRect) -> CGPoint {
    CGPoint(x: x.clamped(to: rect.minX...rect.maxX), y: y.clamped(to: rect.minY...rect.maxY))
  }
}

extension Comparable {
  func clamped(to range: ClosedRange<Self>) -> Self {
    if self < range.lowerBound {
      return range.lowerBound
    } else if self > range.upperBound {
      return range.upperBound
    } else {
      return self
    }
  }
}

extension BinaryInteger {
  func clamped(to range: Range<Self>) -> Self {
    if self < range.lowerBound {
      return range.lowerBound
    } else if self >= range.upperBound {
      return range.upperBound.advanced(by: -1)
    } else {
      return self
    }
  }
}

extension FloatingPoint {
  func clamped(to range: Range<Self>) -> Self {
    if self < range.lowerBound {
      return range.lowerBound
    } else if self >= range.upperBound {
      return range.upperBound.nextDown
    } else {
      return self
    }
  }
}
