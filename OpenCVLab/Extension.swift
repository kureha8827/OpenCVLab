//
//  Extension.swift
//  OpenCVLab
//
//  Created by kureha8827 on 2024/09/28.
//

import Foundation
import opencv2

extension Mat {
    func cvtColor(code: ColorConversionCodes) -> Mat {
        let dstMat = Mat()
        Imgproc.cvtColor(src: self, dst: dstMat, code: code)
        return dstMat
    }
}

extension UIImage {
    func trimming(area: CGRect) -> UIImage {
        let imgRef = self.cgImage?.cropping(to: area)
        let trimImage = UIImage(cgImage: imgRef!, scale: self.scale, orientation: self.imageOrientation)
        return trimImage
    }
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
