//
//  ContentViewModel.swift
//  OpenCVLab
//
//  Created by kureha8827 on 2024/09/28.
//

import SwiftUI
import opencv2
import Vision
import simd

internal typealias Rect = Rect2i

@MainActor
class ContentViewModel: ObservableObject {
    typealias cv2 = Imgproc
    @Published var uiImage: [UIImage] = [UIImage(named: "input.jpg")!]
    var roiImage = RoiImage(image: UIImage(), size: CGRect())
    lazy var width = uiImage.last!.size.width
    lazy var height = uiImage.last!.size.height
    @Published var landmarkPoints: [CGPoint] = []
    @Published var imageToggle = true
    var detectedLandmarks: [VNFaceObservation] = []
    var leftEyeLandmarks: [CGPoint] = []
    @Published var mapXBuffer: UnsafeMutableBufferPointer<Float>? = nil
    @Published var mapYBuffer: UnsafeMutableBufferPointer<Float>? = nil
    
    // 以下, 一時描画用の変数
    @Published var tmp_p: CGFloat = 0
    @Published var tmp_q: CGFloat = 0
    @Published var tmp_r: CGFloat = 0
    
    @Published var filterSize: Int = 0
    private var didFilterSize: Int = 0
    
    init() {
        Task {
             
            await self.fetchImageProperty()
            self.leftEyeLandmarks = self.landmarkPoints[17...22].map { $0 }
        }
    }
    
    func applyOpenCV() {
        Task {
            /*
             例えばスライダを70にしてから写真を保存して、
             その後スライダを0に戻したときに元画像と同じ画像が出力されるようにしたい
             */
            let rate = filterSize - didFilterSize
            eyeEnlarge(leftEyeLandmarks, rate)
        }
    }
    
    
    func eyeEnlarge(_ points: [CGPoint], _ rate: Int) {
        Task {
            let scale: CGFloat = 1/(1 + rate.f*4/1000)
            let maxScale = 1.4
            let r = makeEllipseParameter(points)
            let (maxEllipse, max_p, max_q, max_r) = makeMaxareaEllipse(points, maxScale)
            let roi = CGRect(x: (max_p-max_r).f, y: (height-max_q.f-max_r.f).f, width: (max_r*2).f, height: (max_r*2).f)
            roiImage = RoiImage(image: uiImage.last!.trimming(area: roi), size: roi)
//            print(roiImage)
            
            let srcMat = Mat(uiImage: roiImage.image)
            let dstMat = Mat()
            let start = Date()
        
//             0からInt(roi.width*roi.height)までのfor文のようなもの
            if MapPointerHandler.eyeEnlarge.rawValue == 0 {
                mapXBuffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: Int(roi.width*roi.height))
                mapYBuffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: Int(roi.width*roi.height))
            }
            let dataX: Data
            let dataY: Data
            guard let xPtr = mapXBuffer else { return }
            guard let yPtr = mapYBuffer else { return }
            
            // このクロージャは暗黙的に＠Sendableとして扱われている
            // 下のコメントのコードに変更すると1.6倍ほど早くなるが下記の警告が出る
            // 'UnsafeMutableBufferPointer<Float>' in a @Sendable closure;
            // this is an error in the Swift 6 language mode
//            DispatchQueue.concurrentPerform(iterations: Int(roi.width*roi.height)) { n in
            for n in 0..<Int(roi.width*roi.height) {
                let i = n / Int(roi.width)
                let j = n % Int(roi.width)
                let i_r = Float(i) - max_r
                let j_r = Float(j) - max_r
                if maxEllipse(SIMD2<Float>(i_r, j_r)) {
                    // 画素に代入する値
                    let cur = self.currentPosition((CGFloat(i), CGFloat(j)), (CGFloat(max_r), CGFloat(max_r), r))
                    let delta = self.makeEnlargeDelta(cur, scale, maxScale)
                    xPtr[n] = max_r + j_r * Float(delta)
                    yPtr[n] = max_r + i_r * Float(delta)
                } else {
                    xPtr[n] = Float(j)
                    yPtr[n] = Float(i)
                }
            }
            
            dataX = Data(buffer: xPtr)
            dataY = Data(buffer: yPtr)
            let mapX = Mat(rows: Int32(roi.height), cols: Int32(roi.width), type: CvType.CV_32FC1, data: dataX)
            let mapY = Mat(rows: Int32(roi.height), cols: Int32(roi.width), type: CvType.CV_32FC1, data: dataY)
            
            cv2.remap(src: srcMat, dst: dstMat, map1: mapX, map2: mapY, interpolation: 2)
            roiImage.image = dstMat.toUIImage()
            let end = -start.timeIntervalSinceNow
            print("rate: \(rate)")
            print("frameTime: ", String(format: "%.5f", end))
            print("-----------------------------------------------")
        }
    }
    
    // 処理内容の反映
    // luminousでは他の処理を選択したときに実行される
    func temporarySave() {
        // TODO: roiと元画像の合成
        if roiImage.image == UIImage() || roiImage.size == CGRect() { return }
        let maskedImage: UIImage = roiImage.image
        let image: UIImage = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: UIGraphicsImageRendererFormat(
                for: UITraitCollection(displayScale: 1)
            )
        ).image { context in
            uiImage.last!.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            maskedImage.draw(in: roiImage.size, blendMode: .copy, alpha: 1)
        }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        uiImage.append(image)
        didFilterSize = filterSize
    }
        
    // ランドマーク座標の生成
    func fetchImageProperty() async {
        async let _ = detectLandmarks(uiImage.last!)
        for (c, v) in landmarkPoints.enumerated() {
            landmarkPoints[c].y = height - v.y
        }
    }
    
    // 顔ランドマーク検出の関数
    private func detectLandmarks(_ image: UIImage) async throws {
        guard let ciImage = CIImage(image: image) else { return }

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([request])
            if let results = request.results {
                for observation in results {
                    if let landmarks = observation.landmarks {
                        if let _ = landmarks.faceContour?.normalizedPoints {
                            self.fetchAllLandmarkPoints(from: landmarks)
                        }
                    }
                }
            }
        } catch {
            throw error
        }
    }
    
    
    private func fetchAllLandmarkPoints(from landmarks: VNFaceLandmarks2D) {

        // 顔の輪郭 0-16
        if let faceContour = landmarks.faceContour?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: faceContour)
        }
        
        // 左目 17-22
        if let leftEye = landmarks.leftEye?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: leftEye)
        }
        
        // 右目 23-28
        if let rightEye = landmarks.rightEye?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: rightEye)
        }
        
        // 左眉 29-34
        if let leftEyebrow = landmarks.leftEyebrow?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: leftEyebrow)
        }
        
        // 右眉 35-40
        if let rightEyebrow = landmarks.rightEyebrow?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: rightEyebrow)
        }
        
        // 外側の唇 41-54
        if let outerLips = landmarks.outerLips?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: outerLips)
        }
        
        // 内側の唇 55-60
        if let innerLips = landmarks.innerLips?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: innerLips)
        }
        
        // 左瞼 61
        if let leftPupil = landmarks.leftPupil?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: leftPupil)
        }
        
        // 右瞼 62
        if let rightPupil = landmarks.rightPupil?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: rightPupil)
        }
        
        // 鼻 63-70
        if let nose = landmarks.nose?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: nose)
        }
        
        // 鼻の中央（ブリッジ部分）71-76
        if let noseCrest = landmarks.noseCrest?.pointsInImage(imageSize: uiImage.last!.size) {
            landmarkPoints.append(contentsOf: noseCrest)
        }
    }

    
//    func meshgrid(_ width: CGFloat, _ height: CGFloat) async -> (Mat, Mat) {
//        let w = Int(width)
//        let h = Int(height)
//        
//        let xValues = Array(0..<w)
//        async let flatX: [Float] = Task {
//            var result: [Float] = []
//            for _ in 0..<h {
//                result += xValues.map { Float($0) } // xValuesをフラット化
//            }
//            return result
//        }.value
//            
//        async let flatY: [Float] = Task {
//            var result: [Float] = []
//            for i in 0..<h {
//                result += Array(repeating: i, count: w).map { Float($0) } // iをフラット化
//            }
//            return result
//        }.value
//        
//        let dataX = await flatX.withUnsafeBytes { Data($0) }
//        let dataY = await flatY.withUnsafeBytes { Data($0) }
//        
//        let mapX = Mat(rows: Int32(height), cols: Int32(width), type: CvType.CV_32FC1, data: dataX)
//        let mapY = Mat(rows: Int32(height), cols: Int32(width), type: CvType.CV_32FC1, data: dataY)
//        
//        return (mapX, mapY)
//    }
    
    
    private func makeEllipseParameter(_ points: [CGPoint]) -> CGFloat {
        let point2fPoints = points.map { CGPoint2Point2f($0) }
        let ellipse = cv2.fitEllipse(points: point2fPoints)
        let a, b, r: CGFloat
        a = ellipse.size.width.f
        b = ellipse.size.height.f
        r = a > b ? a/2 : b/2
        return r
    }
    
    
    private func makeMaxareaEllipse(_ points: [CGPoint], _ max_scale: CGFloat) -> (((SIMD2<Float>) -> Bool), Float, Float, Float) {
        let point2fPoints = points.map { CGPoint2Point2f($0) }
        let ellipse = cv2.fitEllipse(points: point2fPoints)
        let p = ellipse.center.x
        let q = ellipse.center.y
        let a = ellipse.size.width
        let b = ellipse.size.height
        let r = (a > b ? a : b) / 2 * Float(max_scale)
        
        func calcEllipse(_ point: SIMD2<Float>) -> Bool {
            let eq1 = simd_length_squared(point) - pow(r, 2)
            return eq1 <= 0
        }
        return (calcEllipse, p, q, r)
    }
    
    // nonisolatedをつけたメソッドはアクターのスレッド隔離ルールを無視し、同期的に呼び出される
    // nonisolatedをつけるためにはそのメソッドがスレッドセーフ(=外部から同時に変更してしまうなどの心配がないこと)である必要がある
    nonisolated private func currentPosition(_ cur: (CGFloat, CGFloat), _ ellipse_param: (CGFloat, CGFloat, CGFloat)) -> CGFloat {
        let (p, q, r) = ellipse_param
        let x = cur.0 - p
        let y = cur.1 - q
        let intersection = x*r/sqrt(pow(x, 2)+pow(y, 2))
        return x / intersection
    }
    
    
    nonisolated private func makeEnlargeDelta(_ src: CGFloat, _ scale: CGFloat, _ max_scale: CGFloat) -> CGFloat {
        return (scale - 1) / pow(abs(1-max_scale), 1/2) * abs(src-max_scale)/2 + 1
    }
    
    // ポインタに使用する新たなメモリを読み込むかどうかの変数
    // 0で未使用(読み込む必要有り), 1で使用済み(読み込む必要無し)
    enum MapPointerHandler: Int {
        case eyeEnlarge = 0
    }
}
