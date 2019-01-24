//
//  FileAudioFrameGenerator.swift
//  OMSConference
//
//  Created by Tomohiro Matsuzawa on 2019/01/16.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import Foundation

class FileAudioFrameGenerator: NSObject, RTCAudioFrameGeneratorProtocol {
    private var fd: UnsafeMutablePointer<FILE>?
    private var _sampleRate: Int = 0
    private var _channelNumber: Int = 0
    private var bufferSize: Int = 0

    init(path: String, sampleRate: Int, channelNumber: Int) {
        super.init()
        self._sampleRate = sampleRate
        self._channelNumber = channelNumber
        let sampleSize: Int = 16
        let framesIn10Ms: Int = sampleRate / 100
        bufferSize = framesIn10Ms * channelNumber * sampleSize / 8
        fd = fopen(path, "rb")
    }

    func channelNumber() -> UInt {
        return UInt(_channelNumber)
    }

    func sampleRate() -> UInt {
        return UInt(_sampleRate)
    }

    func frames(forNext10Ms buffer: UnsafeMutablePointer<UInt8>, capacity: UInt) -> UInt {
        if capacity < bufferSize {
            assert(false, "No enough memory to store frames for next 10 ms")
            return 0
        }
        if fread(buffer, 1, bufferSize, fd) != bufferSize {
            fseek(fd, 0, SEEK_SET)
            fread(buffer, 1, bufferSize, fd)
        }
        return UInt(bufferSize)
    }
}
