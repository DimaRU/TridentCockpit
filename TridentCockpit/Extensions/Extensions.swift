/////
////  Extensions.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

extension NSImage {
  func tinted(_ tintColor: NSColor) -> NSImage {
    guard self.isTemplate else { return self }

    let image = self.copy() as! NSImage
    image.lockFocus()

    tintColor.set()
    NSRect(origin: .zero, size: image.size).fill(using: .sourceAtop)

    image.unlockFocus()
    image.isTemplate = false

    return image
  }

  func rounded() -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()

    let frame = NSRect(origin: .zero, size: size)
    NSBezierPath(ovalIn: frame).addClip()
    draw(at: .zero, from: frame, operation: .sourceOver, fraction: 1)

    image.unlockFocus()
    return image
  }

  static func maskImage(cornerRadius: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: cornerRadius * 2, height: cornerRadius * 2), flipped: false) { rectangle in
      let bezierPath = NSBezierPath(roundedRect: rectangle, xRadius: cornerRadius, yRadius: cornerRadius)
      NSColor.black.setFill()
      bezierPath.fill()
      return true
    }
    image.capInsets = NSEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
    return image
  }
}


extension NSView {
  func roundCorners(withRadius cornerRadius: CGFloat) {
    wantsLayer = true
    layer?.cornerRadius = cornerRadius
  }
}

extension NSPoint {
  func constrained(to rect: NSRect) -> NSPoint {
    return NSMakePoint(x.clamped(to: rect.minX...rect.maxX), y.clamped(to: rect.minY...rect.maxY))
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

extension NSMenu {
    func recursiveSearch(tag: Int) -> NSMenuItem? {
        for item in items {
            if item.tag == tag { return item }
            if item.hasSubmenu, let item = item.submenu?.recursiveSearch(tag: tag) {
                return item
            }
        }
        return nil
    }
}

extension NSViewController {
    static func instantiate<T: NSViewController>() -> T {
        NSStoryboard.main!.instantiateController(withIdentifier: String(describing: T.self)) as! T
    }
}

extension NSWindow {
    func alert(message: String, informative: String, delay: Int = 5) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informative
        alert.alertStyle = .warning
        
        alert.beginSheetModal(for: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) { [weak self, weak alert] in
            guard let self = self, let alert = alert else { return }
            self.endSheet(alert.window, returnCode: .cancel)
        }
    }
    
    func alert(error: Error, delay: Int = 4) {
        let alert = NSAlert()
        alert.messageText = error.localizedDescription
        if let error = error as? NetworkError {
            alert.informativeText = error.message()
        }
        alert.alertStyle = .warning
        
        alert.beginSheetModal(for: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) { [weak self, weak alert] in
            guard let self = self, let alert = alert else { return }
            self.endSheet(alert.window, returnCode: .cancel)
        }
    }

}
