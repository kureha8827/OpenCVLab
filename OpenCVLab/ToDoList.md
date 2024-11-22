# 2024_1121_2110
meshgridは必要ないから削除
mapX, YをMat型から配列にする
cv2.remap()時のみMat型にする


//            for i in 0..<Int(roi.width) {
//                for j in 0..<Int(roi.height) {
//                    if maxEllipse(SIMD2<Float>(Float(i), Float(j))) {
//                        let cur = self.currentPosition((i.f, j.f), (max_r.f, max_r.f, r))
//                        let delta = self.makeEnlargeDelta(cur, scale, maxScale)
//                        mapX.at(row: Int32(j), col: Int32(i)).v = max_r.f + (i.f - max_r.f) * delta
//                        mapY.at(row: Int32(j), col: Int32(i)).v = max_r.f + (j.f - max_r.f) * delta
//                    }
//                }
//            }
        
            // TODO: スライダを作成してリアルタイムに変化量を与えカクつきがないかチェックする
//            await withTaskGroup(of: Void.self) { group in
//                for i in 0..<Int(roi.width) {
//                    group.addTask {
//                    for j in 0..<Int(roi.height) {
//                            if maxEllipse(SIMD2<Float>(Float(i)-max_r, Float(j)-max_r)) {
//                                let cur = await self.currentPosition((i.f, j.f), (max_r.f, max_r.f, r))
//                                let delta = await self.makeEnlargeDelta(cur, scale, maxScale)
//                                mapX.at(row: Int32(j), col: Int32(i)).v = max_r.f + (i.f - max_r.f) * delta
//                                mapY.at(row: Int32(j), col: Int32(i)).v = max_r.f + (j.f - max_r.f) * delta
//                            }
//                        }
//                    }
//                }
//            }
            
//            DispatchQueue.concurrentPerform(iterations: Int(roi.width*roi.height)) { n in
//                let i = n / Int(roi.width)
//                let j = n % Int(roi.width)
//                let i_r = Float(i) - max_r
//                let j_r = Float(j) - max_r
//                if maxEllipse(SIMD2<Float>(i_r, j_r)) {
//                    let cur = self.currentPosition((i.f, j.f), (max_r.f, max_r.f, r))
//                    let delta = self.makeEnlargeDelta(cur, scale, maxScale)
//                    mapX.at(row: Int32(j), col: Int32(i)).v = max_r + i_r * Float(delta)
//                    mapY.at(row: Int32(j), col: Int32(i)).v = max_r + j_r * Float(delta)
//                }
//            }
            
