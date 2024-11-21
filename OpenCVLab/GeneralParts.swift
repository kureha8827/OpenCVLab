//
//  GeneralParts.swift
//  OpenCVLab
//
//  Created by kureha8827 on 2024/10/17.
//

import Foundation
import opencv2


func CGPoint2Point2f(_ point: CGPoint) -> Point2f {
    return Point2f(x: Float(point.x), y: Float(point.y))
}


func point2f2CGPoint(_ point: Point2f) -> CGPoint {
    return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
}


func CGSize2Size2f(_ size: CGSize) -> Size2f {
    return Size2f(width: Float(size.width), height: Float(size.height))
}


func size2f2CGSize(_ size: Size2f) -> CGSize {
    return CGSize(width: CGFloat(size.width), height: CGFloat(size.height))
}

extension Int {
    public var f: CGFloat {
        return CGFloat(self)
    }
}


extension Float {
    public var f: CGFloat {
        return CGFloat(self)
    }
}


extension Double {
    public var f: CGFloat {
        return CGFloat(self)
    }
}
