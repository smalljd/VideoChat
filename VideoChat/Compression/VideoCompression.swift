//
//  VideoCompression.swift
//  VideoChat
//
//  Created by Jeff on 2/10/18.
//  Copyright © 2018 Jeff Small. All rights reserved.
//

import AVFoundation
import Foundation
import VideoToolbox

// Has to be global in order to be interpreted as a C function
func videoFrameFinishEncoding(_ outputCallbackReferenceContainer: UnsafeMutableRawPointer?,
                              sourceFrameReferenceContainer: UnsafeMutableRawPointer?,
                              status: OSStatus,
                              encoderInfoFlags: VTEncodeInfoFlags,
                              sampleBuffer: CMSampleBuffer?) {
    print("video frame finished encoding")

}

class VideoCompression {
    var status: OSStatus = -1
    static var `default` = VideoCompression()
    var compressionSession: VTCompressionSession? = nil

    private init() {}

    func createSession(width: Int32, height: Int32) {
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        status = VTCompressionSessionCreate(nil,
                                            width,
                                            height,
                                            kCMVideoCodecType_H264,
                                            nil,
                                            nil,
                                            nil,
                                            videoFrameFinishEncoding,
                                            observer,
                                            &compressionSession)
        status = VTSessionSetProperty(compressionSession!,
                                      kVTCompressionPropertyKey_RealTime,
                                      kCFBooleanTrue)
    }
}
