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
    // !!!: 仕様が怪しい
    func mask(image: UIImage) -> UIImage {
        guard let maskImage = image.cgImage,
            let selfImage = self.cgImage,
            let mask = maskImage.toGray(),
            let maskedImage = selfImage.masking(mask)
        else { return self }
        
        return UIImage(cgImage: maskedImage)
    }
    
    
    func trimming(area: CGRect) -> UIImage {
        let imgRef = self.cgImage?.cropping(to: area)
        let trimImage = UIImage(cgImage: imgRef!, scale: self.scale, orientation: self.imageOrientation)
        return trimImage
    }
}

extension CGImage {
    func toGray() -> CGImage? {
        let context = CGContext(
            data: nil,
            width: self.width,
            height: self.height,
            bitsPerComponent: self.bitsPerComponent,
            bytesPerRow: self.bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
        context?.draw(self, in: CGRect(x: 0, y: 0, width: self.width, height: self.height))
        guard let mask = context?.makeImage() else { return nil }
        return mask
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
