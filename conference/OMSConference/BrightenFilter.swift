//
//  BrightenFilter.swift
//  OMSConference
//
//  Created by Tomohiro Matsuzawa on 2019/01/16.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import CoreImage
import Foundation

// A sample filter processing frames captured from RTCVideoCapturer.
class BrightenFilter: NSObject, RTCVideoCapturerDelegate {
    private weak var output: RTCVideoCapturerDelegate?
    private var context: CIContext
    private var filter: CIFilter
    private var buffer: CVPixelBuffer?

    // Processed frames will be pass to |output|.
    init(output: RTCVideoCapturerDelegate?) {
        assert(output != nil, "output cannot be nil.")
        //if super.init()

        enabled = false
        self.output = output
        context = CIContext()
        filter = CIFilter(name: "CIColorControls")!
        filter.setDefaults()
        filter.setValue(NSNumber(value: 0.2), forKey: "inputBrightness")

    }

    // Implement |RTCVideoCapturerDelegate|.
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        // If frame does not have a native handle, we need to convert I420 buffer to
        // CIImage. It is a rare case, so we don't handle it here.
        if (frame.buffer is RTCCVPixelBuffer) || !enabled {
            output?.capturer(capturer, didCapture: frame)
            return
        }
        if let pixelBuffer = (frame.buffer as? RTCCVPixelBuffer)?.pixelBuffer {
            filter.setValue(CIImage(cvImageBuffer: pixelBuffer), forKey: "inputImage")
        }
        guard let filteredImage = filter.outputImage else {
            return
        }
        buffer = nil
        let result = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(frame.width), Int(frame.height),
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, nil, &buffer)
        if result != kCVReturnSuccess {
            output?.capturer(capturer, didCapture: frame)
            return
        }
        guard let buffer = buffer else {
            return
        }
        context.render(filteredImage, to: buffer)
        let filteredFrame = RTCVideoFrame(buffer: RTCCVPixelBuffer(pixelBuffer: buffer), rotation: ._0, timeStampNs: 0)
        output?.capturer(capturer, didCapture: filteredFrame)
    }

    var enabled = false
}
