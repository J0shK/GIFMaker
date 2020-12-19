//
//  FFMpeg+Output.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/18/20.
//

import Foundation

extension FFMpeg {
    struct Output: Codable {
        enum Progress: String, Codable {
            case `continue`
            case end
        }

        enum Stage: String, Codable {
            case none
            case preprocessing
            case processing
        }

        let frame: String
        let fps: String
        let stream: String
        let bitrate: String
        let totalSize: String
        let outTimeUs: String
        let outTimeMs: String
        let outTime: String
        let dupFrames: String
        let dropFrames: String
        let speed: String
        let progress: Progress
        let stage: Stage

        enum CodingKeys: String, CodingKey {
            case frame
            case fps
            case stream = "stream_0_0_q"
            case bitrate
            case totalSize = "total_size"
            case outTimeUs = "out_time_us"
            case outTimeMs = "out_time_ms"
            case outTime = "out_time"
            case dupFrames = "dup_frames"
            case dropFrames = "drop_frames"
            case speed
            case progress
            case stage
        }
    }
}
