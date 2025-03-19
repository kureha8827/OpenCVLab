//
//  ContentView.swift
//  OpenCVLab
//
//  Created by kureha8827 on 2024/09/28.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject var model = ContentViewModel()
    @State private var sliderValue: Float = 0
    
    var body: some View {
        VStack(spacing: 20) {
            if model.imageToggle {
                VStack {
                    ZStack {
                        Image(uiImage: model.uiImage.last!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250)
                        Image(uiImage: model.roiImage.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: model.roiImage.size.width * 250 / model.width)
                            .position(
                                x: (model.roiImage.size.width/2 + model.roiImage.size.minX) * 250 / model.width,
                                y: (model.roiImage.size.height/2 + model.roiImage.size.minY) * 250 / model.width
                            )
//                            .position(
//                                x: model.roiImage.size.minX * 250 / model.width,
//                                y: model.roiImage.size.minY * 250 / model.width
//                            )
                    }
                    .frame(width: 250, height: model.height * 250 / model.width)
//                    .frame(width: 250)
                    Slider(value: $sliderValue, in: 0...100)
                        .frame(width: 300)
                    
//                    GeometryReader { _ in
//                        Circle()
//                            .foregroundStyle(.blue)
//                            .frame(width: model.tmp_r * 250 / model.width)
//                            .position(
//                                x: model.tmp_p * 250 / model.width,
//                                y: (model.height - model.tmp_q) * 250 / model.width
//                            )
//                        ForEach(model.landmarkPoints, id: \.self) { landmark in
//                            Circle()
//                                .foregroundStyle(.red)
//                                .frame(width: 4)
//                                .position(
//                                    x: landmark.x * 250 / model.width,
//                                    y: (model.height - landmark.y) * 250 / model.width
//                                )
//                        }
//                    }
                }
                .onDisappear {
                    model.mapXBuffer?.deallocate()
                    model.mapYBuffer?.deallocate()
                }
                Text("Output")
                
            } else {
                Image(uiImage: model.uiImage.last!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
                Text("Input")
            }
            
            Button {
                model.imageToggle.toggle()
            } label: {
                if model.imageToggle {
                    Text("toInputImage")
                } else {
                    Text("toOutputImage")
                }
            }
            
            Group {
                Button {
                    model.applyOpenCV()
    //                    print(model.detectedLandmarks)
                } label: {
                    Text("applyOpenCV")
                }
                Button {
                    model.temporarySave()
    //                    print(model.detectedLandmarks)
                } label: {
                    Text("temporarySave")
                }
            }
            .opacity(model.imageToggle ? 1 : 0)
        }
        .onChange(of: sliderValue) {
            model.filterSize = Int(sliderValue)
            model.applyOpenCV()
        }
    }
}
