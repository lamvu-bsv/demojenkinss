//
//  DrawCanvasView.swift
//  DemoProject
//
//  Created by Tai Ma on 7/23/20.
//  Copyright © 2020 Tai Ma. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct LineModel: Codable {
    var color: String
    var width: CGFloat
    var points: [CGPoint]
}

protocol DrawCanvasViewDelegate {
    func handleEndDraw()
}

class DrawCanvasView: UIView {

    var color: UIColor = .red
    var width: CGFloat = 1
    var delegate: DrawCanvasViewDelegate?
    var isDeleted: Bool = false {
        didSet {
            vDeleted?.removeFromSuperview()
            vDeleted = nil
        }
    }
    
    private var vDeleted: UIView?
    private(set) var lines: [LineModel] = []
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        lines.forEach({ line in
            context.setStrokeColor(UIColor(hex: line.color)!.cgColor)
            context.setLineWidth(line.width)
            context.setLineCap(.round)
            context.setBlendMode(.clear)
            for (index, point) in line.points.enumerated() {
                if index == 0 {
                    context.move(to: point)
                } else {
                    context.addLine(to: point)
                }
            }
            
            context.strokePath()
        })
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDeleted {
            let beganPoint = touches.first?.location(in: nil)
            vDeleted = UIView(frame: CGRect(x: beganPoint!.x, y: beganPoint!.y, width: 50, height: 50))
            vDeleted?.backgroundColor = .black
            self.addSubview(vDeleted!)
            vDeleted?.center = beganPoint!
            handleDeletedLine()
        } else {
            lines.append(LineModel(color: color.toHex ?? "#00000", width: width, points: []))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: nil) else { return }
        vDeleted?.center = point
        if isDeleted {
            handleDeletedLine()
        } else {
            guard var lastLine = lines.popLast() else { return }
            lastLine.points.append(point)
            lines.append(lastLine)
        }
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.handleEndDraw()
        vDeleted?.removeFromSuperview()
        vDeleted = nil
    }
    
    public func clear() {
        lines.removeAll()
        setNeedsDisplay()
    }
    
    public func undo() {
        lines.removeLast()
        setNeedsDisplay()
    }
    
    public func hanldeSocketLines(_ lines: [LineModel]) {
        self.lines.append(contentsOf: lines)
        setNeedsDisplay()
    }
    
    private func handleDeletedLine() {
        if let vDeleted = vDeleted {
            for (index, _) in lines.enumerated() {
                self.lines[index].points.removeAll(where: { vDeleted.frame.contains($0) })
            }
        }
    }
}


extension UIColor {

    // MARK: - Initialization

    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt32 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt32(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    // MARK: - Computed Properties

    var toHex: String? {
        return toHex()
    }

    // MARK: - From UIColor to String

    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }

}

