//
//  Triangle.swift
//  
//
//  Created by Edon Valdman on 2/22/23.
//

import SwiftUI

/// A Triangle `Shape`. It will will automatically fill the space it's placed in, unless a specific frame is set.
public struct Triangle: Shape {
    /// Used as a means to set a way to calculate an `Angle` relative to the shape's size.
    public typealias AngleCalc = (CGRect) -> Angle
    
    /// Creates a basic ``Triangle/Triangle``.
    ///
    /// The angles will be calculated automatically, filling the frame of the shape.
    public init() {
        self.angleA = nil
        self.angleB = nil
    }
    
    /// Creates a ``Triangle/Triangle``, setting the lower corners to the provided angles.
    ///
    /// The top angle will be calculated automatically, as all three angles of a triangle must total 180 degrees.
    ///
    /// If the angles provided don't allow for the three angles to total 180 degrees, then it will fall back on ``init()``.
    /// - Parameters:
    ///   - angleA: The `Angle` of the lower left angle.
    ///   - angleB: The `Angle` of the lower right angle.
    public init(angleA: Angle, angleB: Angle) {
        self.init()
        guard .degrees(180) - angleA - angleB > .zero,
              angleA.degrees > .zero && angleB.degrees > .zero else {
            print("Angles are invalidated due to not summing to 180 degrees.")
            return
        }
        
        self.angleA = { _ in angleA }
        self.angleB = { _ in angleB }
    }
    
    public var angleA: AngleCalc?
    public var angleB: AngleCalc?
    public var angleC: AngleCalc? {
        guard let angleA, let angleB else { return nil }
        return { r in .degrees(180) - angleA(r) - angleB(r) }
    }
    
    private var insetAmount: CGFloat = 0
    
    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        
        if let angleA = angleA?(rect),
           let angleB = angleB?(rect),
           let angleC = angleC?(rect),
           angleA + angleB + angleC == .degrees(180) {
            /*
               C
            a<--->b
             B\ /A
               v
               c
             */
            
            let sideC = insetRect.width
            let sideAngleRatioC = sideC / CGFloat(sin(angleC.radians))
            let sideA = sideAngleRatioC * CGFloat(sin(angleA.radians))
            let sideB = sideAngleRatioC * CGFloat(sin(angleB.radians))
            
            // Adds corners in counter-clockwise order
            
            // Start in Upper Right Corner
            let pointA = CGPoint(x: insetRect.minX, y: insetRect.minY)
            path.move(to: pointA)
            
            // (x2,y2)=(x1+l⋅cos(angleA), y1+l⋅sin(angleA))
            let pointC = CGPoint(
                x: pointA.x + sideB * CGFloat(cos(angleA.radians)),
                y: pointA.y + sideB * CGFloat(sin(angleA.radians))
            )
            path.addLine(to: pointC)
            
            // Instead of using angleC, angleB is used because it's the relative angle that
            // the line is drawn at from pointC to pointB
            let pointB = CGPoint(
                x: pointC.x + sideA * CGFloat(cos(-angleB.radians)),
                y: (pointC.y + sideA * CGFloat(sin(-angleB.radians)))
            )
            path.addLine(to: pointB)
            
            path.closeSubpath()
            
            let scale: CGFloat
            if path.boundingRect.height / path.boundingRect.width < insetRect.height / insetRect.width {
                // boundingRect is fatter
                scale = insetRect.width / path.boundingRect.width
            } else {
                // boundingRect is skinnier
                scale = insetRect.height / path.boundingRect.height
            }
            return path
                .applying(.init(scaleX: 1, y: -1))
                .offsetBy(dx: 0,
                          dy: insetRect.height + insetAmount * 2
                            - (insetRect.height - pointC.y)
                )
                .applying(.init(scaleX: scale, y: scale))
                .offsetBy(dx: (insetRect.width - (insetRect.width * scale)) / 2,
                          dy: 0)
        } else {
            path.move(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
            path.addLine(to: CGPoint(x: insetRect.midX, y: insetRect.minY))
            path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY))
            path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
            path.closeSubpath()
        }
        
        return path
    }
}

extension Triangle: InsettableShape {
    public func inset(by amount: CGFloat) -> some InsettableShape {
        var insetShape = self
        insetShape.insetAmount += amount
        return insetShape
    }
}

extension Triangle {
    /// Creates a ``Triangle/Triangle``, setting the horizontal placement of the top vertex.
    ///
    /// The angles will be calculated automatically, filling the frame of the shape, and allowing for the top vertex's provided placement.
    /// - Parameter topVertexPlacement: The relative horizontal placement of the top vertex of the triangle.
    /// > Important: Value should be in the range of `0.0`-`1.0`.
    public init(topVertexPlacement: CGFloat) {
        let placement = max(0, min(1, topVertexPlacement))
        
        self.angleA = { r in .radians(Double(atan(r.height / (r.width * placement)))) }
        self.angleB = { r in .radians(Double(atan(r.height / (r.width * (1 - placement))))) }
    }
}

struct Triangle_Previews: PreviewProvider {
    static var previews: some View {
        Triangle(topVertexPlacement: 1)
            .strokeBorder(.green, lineWidth: 10)
    }
}
