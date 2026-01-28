#!/usr/bin/env swift
//
//  convert-to-hls.swift
//  JWS Skills
//
//  End-to-end HLS conversion: Download MP4 → Convert (AVFoundation) → Upload CDN → Update Website
//
//  Usage:
//    swift convert-to-hls.swift <mp4-url>                    # Convert single video
//    swift convert-to-hls.swift --all                        # Convert all means.ai MP4s
//    swift convert-to-hls.swift --backup                     # Backup current page states
//    swift convert-to-hls.swift --revert <backup-file>       # Revert to backup
//    swift convert-to-hls.swift --dry-run                    # Test without making changes
//
//  The script will automatically update the website content to use the new HLS URLs.
//

import Foundation
import AVFoundation
import UniformTypeIdentifiers

// Disable stdout buffering for real-time output
setbuf(stdout, nil)

// Helper to flush output
func log(_ message: String) {
    print(message)
    fflush(stdout)
}

// MARK: - Configuration

// API servers by deployment
let apiServers: [String: String] = [
    "means": "https://outtakes.com",       // means.ai, outtakes.com, jws.ai
    "voosey": "https://api.voosey.com"     // voosey.com, dajh.com
]

// Default to means server for means.ai
let apiBaseURL = apiServers["means"]!
let masterKey = "2571123FD179EA45A21B5563D4B1D"

let backupDirectory = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".jws-hls-backups")

// Website IDs (from website-api.swift)
let websiteIDs: [String: String] = [
    "means.ai": "1CF4F6AF-A577-4875-BF1E-7BA14C1985B4",
    "outtakes.com": "1CF4F6AF-A577-4875-BF1E-7BA14C1985B5",
    "jws.ai": "1CF4F6AF-A577-4875-BF1E-7BA14C1985B7",
    "voosey.com": "1CF4F6AF-A577-4875-BF1E-7BA14C1985B4"
]

// Known MP4s on means.ai that need conversion
let meansAIMp4s = [
    "https://cdn.outtakes.com/company/media/9_Q29tcCAzOF8x_1.mp4",
    "https://cdn.outtakes.com/company/media/Sequence%2001_3.mp4",
    "https://cdn.voosey.com/media/083125-2.mp4",
    "https://cdn.neuraform.com/company/marketing/Comp%204.MP4",
    "https://ghf.nyc3.digitaloceanspaces.com/Website%202021_1.mp4",
    "https://cdn.revolusun.app/assets/videos/Commercial-V2-30-secs.mp4",
    "https://c.jws.ai/JWSpoweredby.mp4",
    "https://c.jws.ai/uc1.mp4"
]

// MARK: - Backup System

struct BackupManifest: Codable {
    let timestamp: Date
    let websiteHost: String
    let websiteID: String
    let pages: [PageBackup]
    let urlMapping: [String: String] // old -> new for reference

    struct PageBackup: Codable {
        let pageID: String
        let pageTitle: String
        let originalData: Data // Full JSON of page before modification
    }
}

func createBackup(websiteHost: String, pages: [(id: String, title: String, data: [String: Any])]) throws -> URL {
    try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

    let timestamp = ISO8601DateFormatter().string(from: Date())
    let filename = "backup-\(websiteHost)-\(timestamp).json"
    let backupURL = backupDirectory.appendingPathComponent(filename)

    var pageBackups: [BackupManifest.PageBackup] = []
    for page in pages {
        let jsonData = try JSONSerialization.data(withJSONObject: page.data, options: [.prettyPrinted, .sortedKeys])
        pageBackups.append(BackupManifest.PageBackup(
            pageID: page.id,
            pageTitle: page.title,
            originalData: jsonData
        ))
    }

    let manifest = BackupManifest(
        timestamp: Date(),
        websiteHost: websiteHost,
        websiteID: websiteIDs[websiteHost] ?? "",
        pages: pageBackups,
        urlMapping: [:]
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(manifest)
    try data.write(to: backupURL)

    return backupURL
}

func revertFromBackup(backupURL: URL) async throws {
    let data = try Data(contentsOf: backupURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let manifest = try decoder.decode(BackupManifest.self, from: data)

    print("\n" + String(repeating: "⚠", count: 35))
    print("REVERTING TO BACKUP")
    print("Timestamp: \(manifest.timestamp)")
    print("Website: \(manifest.websiteHost)")
    print("Pages: \(manifest.pages.count)")
    print(String(repeating: "⚠", count: 35))

    let api = WebsiteAPI(baseURL: apiBaseURL, masterKey: masterKey)

    for pageBackup in manifest.pages {
        guard let pageData = try JSONSerialization.jsonObject(with: pageBackup.originalData) as? [String: Any] else {
            print("[ERROR] Failed to parse backup for page: \(pageBackup.pageTitle)")
            continue
        }

        print("[Revert] \(pageBackup.pageTitle)...")
        try await api.updatePage(
            websiteID: manifest.websiteID,
            pageID: pageBackup.pageID,
            pageData: pageData
        )
        print("[Revert] \(pageBackup.pageTitle) ✓")
    }

    print("\n[SUCCESS] Reverted \(manifest.pages.count) pages to backup state")
}

func listBackups() {
    guard FileManager.default.fileExists(atPath: backupDirectory.path) else {
        print("No backups found.")
        return
    }

    do {
        let files = try FileManager.default.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "json" }
            .sorted { ($0.lastPathComponent) > ($1.lastPathComponent) }

        if files.isEmpty {
            print("No backups found.")
            return
        }

        print("Available backups:\n")
        for file in files {
            let data = try Data(contentsOf: file)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let manifest = try decoder.decode(BackupManifest.self, from: data)

            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium

            print("  \(file.lastPathComponent)")
            print("    Website: \(manifest.websiteHost)")
            print("    Date: \(formatter.string(from: manifest.timestamp))")
            print("    Pages: \(manifest.pages.count)")
            print("")
        }

        print("To revert: swift convert-to-hls.swift --revert <backup-file>")
    } catch {
        print("Error listing backups: \(error.localizedDescription)")
    }
}

// MARK: - HLS Conversion Engine (exact copy from JCS/JCSMedia/HLSConversionEngine.swift)

actor HLSConversionEngine {

    struct Configuration {
        let inputFileURL: URL
        let outputDirectoryURL: URL
        var startTimeOffset: CMTime = CMTime(value: 10, timescale: 1)
        var segmentDuration: Int = 6
        var segmentFileNamePrefix: String = "fileSequence"
        var indexFileName: String = "master.m3u8"
        var outputContentType: AVFileType = .mp4
    }

    enum HLSError: Error, LocalizedError {
        case sourceFileHasNoVideoTrack
        case sourceFileHasNoAudioTrack
        case cannotAddReader(String)
        case cannotAddWriter(String)
        case conversionFailed(Error)
        case downloadFailed(String)
        case unknown

        var errorDescription: String? {
            switch self {
            case .sourceFileHasNoVideoTrack: return "File has no video track"
            case .sourceFileHasNoAudioTrack: return "File has no audio track"
            case .cannotAddReader(let msg): return "Cannot add reader: \(msg)"
            case .cannotAddWriter(let msg): return "Cannot add writer: \(msg)"
            case .conversionFailed(let err): return "Conversion failed: \(err.localizedDescription)"
            case .downloadFailed(let msg): return "Download failed: \(msg)"
            case .unknown: return "Unknown error"
            }
        }
    }

    struct Segment {
        let index: Int
        let data: Data
        let isInitializationSegment: Bool
        let report: AVAssetSegmentReport?

        func fileName(forPrefix prefix: String) -> String {
            let ext = isInitializationSegment ? "mp4" : "m4s"
            return "\(prefix)\(index).\(ext)"
        }
    }

    struct SourceMedia {
        let asset: AVURLAsset
        let audioTrack: AVAssetTrack?
        let videoTrack: AVAssetTrack
        let videoDimensions: CGSize
    }

    struct IndexFileState {
        var content = ""
        var previousSegmentInfo: (fileName: String, timingTrackReport: AVAssetSegmentTrackReport)?
    }

    func convertToHLS(using config: Configuration) async throws -> URL {
        print("[HLS] Loading tracks from \(config.inputFileURL.lastPathComponent)")
        let sourceMedia = try await loadTracks(with: config)

        try FileManager.default.createDirectory(at: config.outputDirectoryURL, withIntermediateDirectories: true)

        let segments = try await generateSegments(sourceMedia: sourceMedia, config: config)

        for segment in segments {
            let fileName = segment.fileName(forPrefix: config.segmentFileNamePrefix)
            let segmentURL = config.outputDirectoryURL.appendingPathComponent(fileName)
            try segment.data.write(to: segmentURL)
        }

        let playlist = buildPlaylist(from: segments, config: config)
        let playlistURL = config.outputDirectoryURL.appendingPathComponent(config.indexFileName)
        try playlist.write(to: playlistURL, atomically: true, encoding: .utf8)

        print("[HLS] Generated \(segments.count) segments + playlist")
        return playlistURL
    }

    private func loadTracks(with config: Configuration) async throws -> SourceMedia {
        let asset = AVURLAsset(url: config.inputFileURL)
        let allTracks = try await asset.load(.tracks)

        let audioTrack = allTracks.first(where: { $0.mediaType == .audio })
        guard let videoTrack = allTracks.first(where: { $0.mediaType == .video }) else {
            throw HLSError.sourceFileHasNoVideoTrack
        }

        let videoDescriptions = try await videoTrack.load(.formatDescriptions)
        guard let videoCodec = videoDescriptions.first else {
            throw HLSError.sourceFileHasNoVideoTrack
        }

        let codecType = CMFormatDescriptionGetMediaSubType(videoCodec)
        let codecString = String(format: "%c%c%c%c",
                                (codecType >> 24) & 0xff,
                                (codecType >> 16) & 0xff,
                                (codecType >> 8) & 0xff,
                                codecType & 0xff)

        let dimensions = try await videoTrack.load(.naturalSize)

        print("[HLS] Video: \(codecString) \(Int(dimensions.width))x\(Int(dimensions.height))")
        print("[HLS] Audio: \(audioTrack != nil ? "yes" : "no")")

        return SourceMedia(asset: asset, audioTrack: audioTrack, videoTrack: videoTrack, videoDimensions: dimensions)
    }

    private func generateSegments(sourceMedia: SourceMedia, config: Configuration) async throws -> [Segment] {
        let readerWriter = try ReaderWriter(sourceMedia: sourceMedia, config: config)
        return try await readerWriter.startAndCollectSegments()
    }

    private func buildPlaylist(from segments: [Segment], config: Configuration) -> String {
        var state = IndexFileState()

        for segment in segments {
            let fileName = segment.fileName(forPrefix: config.segmentFileNamePrefix)

            if segment.isInitializationSegment {
                if state.content.isEmpty {
                    state.content = """
                    #EXTM3U
                    #EXT-X-TARGETDURATION:\(config.segmentDuration)
                    #EXT-X-VERSION:7
                    #EXT-X-MEDIA-SEQUENCE:1
                    #EXT-X-PLAYLIST-TYPE:VOD
                    #EXT-X-INDEPENDENT-SEGMENTS
                    #EXT-X-MAP:URI="\(fileName)"

                    """
                }
            } else if let report = segment.report,
                      let trackReport = report.trackReports.first(where: { $0.mediaType == .video }) {

                if let prev = state.previousSegmentInfo {
                    let duration = trackReport.earliestPresentationTimeStamp - prev.timingTrackReport.earliestPresentationTimeStamp
                    state.content += "#EXTINF:\(String(format: "%.5f", duration.seconds)),\n\(prev.fileName)\n"
                }
                state.previousSegmentInfo = (fileName, trackReport)
            }
        }

        if let final = state.previousSegmentInfo {
            let duration = final.timingTrackReport.duration
            state.content += "#EXTINF:\(String(format: "%.5f", duration.seconds)),\n\(final.fileName)\n"
        }

        state.content += "#EXT-X-ENDLIST\n"
        return state.content
    }
}

// ReaderWriter class - handles parallel audio/video transfer with AsyncThrowingStream
private final class ReaderWriter: NSObject, AVAssetWriterDelegate, @unchecked Sendable {

    private let assetReader: AVAssetReader
    private let assetWriter: AVAssetWriter
    private let audioReaderOutput: AVAssetReaderOutput?
    private let videoReaderOutput: AVAssetReaderOutput
    private let audioWriterInput: AVAssetWriterInput?
    private let videoWriterInput: AVAssetWriterInput
    private let startTimeOffset: CMTime

    private var segmentIndex = 0
    private var outputSegmentDataContinuation: AsyncThrowingStream<HLSConversionEngine.Segment, Error>.Continuation?

    init(sourceMedia: HLSConversionEngine.SourceMedia, config: HLSConversionEngine.Configuration) throws {
        assetReader = try AVAssetReader(asset: sourceMedia.asset)

        // Audio reader - decompress to LPCM
        if let audioTrack = sourceMedia.audioTrack {
            let audioSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM]
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioSettings)
            guard assetReader.canAdd(audioOutput) else {
                throw HLSConversionEngine.HLSError.cannotAddReader("audio")
            }
            assetReader.add(audioOutput)
            audioReaderOutput = audioOutput
        } else {
            audioReaderOutput = nil
        }

        // Video reader - decompress to raw frames
        let videoSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        videoReaderOutput = AVAssetReaderTrackOutput(track: sourceMedia.videoTrack, outputSettings: videoSettings)
        guard assetReader.canAdd(videoReaderOutput) else {
            throw HLSConversionEngine.HLSError.cannotAddReader("video")
        }
        assetReader.add(videoReaderOutput)

        // Writer with HLS profile
        guard let utType = UTType(config.outputContentType.rawValue) else {
            throw HLSConversionEngine.HLSError.unknown
        }
        assetWriter = AVAssetWriter(contentType: utType)
        assetWriter.outputFileTypeProfile = .mpeg4AppleHLS
        assetWriter.preferredOutputSegmentInterval = CMTime(seconds: Double(config.segmentDuration), preferredTimescale: 1)
        assetWriter.initialSegmentStartTime = config.startTimeOffset

        // Audio writer - AAC
        if sourceMedia.audioTrack != nil {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48000,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128000
            ]
            audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            guard assetWriter.canAdd(audioWriterInput!) else {
                throw HLSConversionEngine.HLSError.cannotAddWriter("audio")
            }
            assetWriter.add(audioWriterInput!)
        } else {
            audioWriterInput = nil
        }

        // Video writer - H.264
        let videoWriterSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: sourceMedia.videoDimensions.width,
            AVVideoHeightKey: sourceMedia.videoDimensions.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 5_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterSettings)
        guard assetWriter.canAdd(videoWriterInput) else {
            throw HLSConversionEngine.HLSError.cannotAddWriter("video")
        }
        assetWriter.add(videoWriterInput)

        self.startTimeOffset = config.startTimeOffset
        super.init()
        assetWriter.delegate = self
    }

    func startAndCollectSegments() async throws -> [HLSConversionEngine.Segment] {
        var collectedSegments: [HLSConversionEngine.Segment] = []

        let segmentStream = AsyncThrowingStream<HLSConversionEngine.Segment, Error> { continuation in
            self.outputSegmentDataContinuation = continuation
        }

        guard assetReader.startReading() else {
            throw assetReader.error ?? HLSConversionEngine.HLSError.unknown
        }
        guard assetWriter.startWriting() else {
            throw assetWriter.error ?? HLSConversionEngine.HLSError.unknown
        }

        assetWriter.startSession(atSourceTime: startTimeOffset)

        let collectorTask = Task {
            for try await seg in segmentStream {
                print("[HLS] Segment \(seg.index): \(seg.data.count / 1024) KB\(seg.isInitializationSegment ? " (init)" : "")")
                collectedSegments.append(seg)
            }
        }

        // Run audio and video transfer in PARALLEL
        let audioTask: Task<Void, Error>?
        if let audioOutput = self.audioReaderOutput, let audioInput = self.audioWriterInput {
            audioTask = Task {
                try await self.transferLoop(from: audioOutput, to: audioInput, offset: self.startTimeOffset)
                audioInput.markAsFinished()
            }
        } else {
            audioTask = nil
        }

        let videoTask = Task {
            try await self.transferLoop(from: self.videoReaderOutput, to: self.videoWriterInput, offset: self.startTimeOffset)
            self.videoWriterInput.markAsFinished()
        }

        do {
            if let audioTask { try await audioTask.value }
            try await videoTask.value
        } catch {
            audioTask?.cancel()
            videoTask.cancel()
            assetReader.cancelReading()
            assetWriter.cancelWriting()
            outputSegmentDataContinuation?.finish(throwing: error)
            throw error
        }

        try await finishWriter()
        outputSegmentDataContinuation?.finish()
        try await collectorTask.value

        return collectedSegments
    }

    private func transferLoop(from readerOutput: AVAssetReaderOutput, to writerInput: AVAssetWriterInput, offset: CMTime) async throws {
        while true {
            let status = assetWriter.status
            if status == .failed || status == .cancelled {
                throw assetWriter.error ?? HLSConversionEngine.HLSError.unknown
            }

            while !writerInput.isReadyForMoreMediaData {
                try Task.checkCancellation()
                try await Task.sleep(nanoseconds: 50_000_0)
            }

            guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else { return }

            let adjustedBuffer = try offsetTiming(sampleBuffer, by: offset)
            guard writerInput.append(adjustedBuffer) else {
                throw assetWriter.error ?? HLSConversionEngine.HLSError.unknown
            }
        }
    }

    private func offsetTiming(_ sampleBuffer: CMSampleBuffer, by offset: CMTime) throws -> CMSampleBuffer {
        let timingInfos = try sampleBuffer.sampleTimingInfos()
        let shifted = timingInfos.map { old -> CMSampleTimingInfo in
            var new = old
            new.presentationTimeStamp = old.presentationTimeStamp + offset
            if old.decodeTimeStamp.isValid {
                new.decodeTimeStamp = old.decodeTimeStamp + offset
            }
            return new
        }
        let newSampleBuffer = try CMSampleBuffer(copying: sampleBuffer, withNewTiming: shifted)
        try newSampleBuffer.setOutputPresentationTimeStamp(newSampleBuffer.outputPresentationTimeStamp + offset)
        return newSampleBuffer
    }

    private func finishWriter() async throws {
        let writer = self.assetWriter
        return try await withCheckedThrowingContinuation { continuation in
            writer.finishWriting {
                if writer.status == .completed {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: writer.error ?? HLSConversionEngine.HLSError.unknown)
                }
            }
        }
    }

    // AVAssetWriterDelegate - called when segments are ready
    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
        Task {
            guard let continuation = self.outputSegmentDataContinuation else { return }

            let isInit = segmentType == .initialization
            let segment = HLSConversionEngine.Segment(
                index: self.segmentIndex,
                data: segmentData,
                isInitializationSegment: isInit,
                report: segmentReport
            )
            self.segmentIndex += 1
            continuation.yield(segment)
        }
    }
}

// MARK: - Media Upload

struct MediaUploader {
    let baseURL: String  // Use same server as website API
    let dryRun: Bool

    struct PresignedResponse: Decodable {
        let url: String     // Signed URL for PUT upload
        let publicUrl: String  // Public URL after upload
    }

    struct UploadRequest: Encodable {
        let filename: String
        let totalBytes: Int
        let mediaType: String
    }

    func upload(data: Data, filename: String, contentType: String, mediaType: String) async throws -> String {
        if dryRun {
            let fakeURL = "https://cdn.means.ai/dry-run/\(filename)"
            print("[DRY-RUN] Would upload \(data.count / 1024) KB as \(filename)")
            return fakeURL
        }

        // 1. Get presigned URL (no auth required for this endpoint)
        let uploadReq = UploadRequest(filename: filename, totalBytes: data.count, mediaType: mediaType)

        var request = URLRequest(url: URL(string: "\(baseURL)/v1/media/presigned-url")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(uploadReq)

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: responseData, encoding: .utf8) ?? ""
            throw NSError(domain: "Upload", code: 1, userInfo: [NSLocalizedDescriptionKey: "Presigned URL failed: \(body)"])
        }

        let presigned = try JSONDecoder().decode(PresignedResponse.self, from: responseData)

        // 2. Upload to S3
        // The presigned URL was signed with specific headers - we must match them exactly
        var uploadRequest = URLRequest(url: URL(string: presigned.url)!)
        uploadRequest.httpMethod = "PUT"
        uploadRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        uploadRequest.setValue("public-read", forHTTPHeaderField: "x-amz-acl")
        uploadRequest.setValue("https://0.jws.ai", forHTTPHeaderField: "Origin")  // Must match presigned URL signing
        uploadRequest.httpBody = data

        let (s3ResponseData, uploadResponse) = try await URLSession.shared.data(for: uploadRequest)
        guard let uploadHttpResponse = uploadResponse as? HTTPURLResponse,
              (200...299).contains(uploadHttpResponse.statusCode) else {
            let statusCode = (uploadResponse as? HTTPURLResponse)?.statusCode ?? 0
            let s3Body = String(data: s3ResponseData, encoding: .utf8) ?? ""
            throw NSError(domain: "Upload", code: 3, userInfo: [NSLocalizedDescriptionKey: "S3 upload failed (\(statusCode)): \(s3Body)"])
        }

        return presigned.publicUrl
    }
}

// MARK: - Website API

struct WebsiteAPI {
    let baseURL: String
    let masterKey: String
    var dryRun: Bool = false

    func getPage(websiteID: String, pageID: String) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: "\(baseURL)/v2/mainframe/web/page/\(websiteID)/\(pageID)")!)
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "API", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }
        return json
    }

    func listPages(websiteID: String) async throws -> [[String: Any]] {
        var request = URLRequest(url: URL(string: "\(baseURL)/v2/mainframe/web/pages/\(websiteID)")!)
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NSError(domain: "API", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }
        return json
    }

    func updatePage(websiteID: String, pageID: String, pageData: [String: Any]) async throws {
        if dryRun {
            print("[DRY-RUN] Would update page \(pageID)")
            return
        }

        var request = URLRequest(url: URL(string: "\(baseURL)/v2/mainframe/web/page/\(websiteID)/\(pageID)")!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")
        request.httpBody = try JSONSerialization.data(withJSONObject: pageData)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "API", code: 2, userInfo: [NSLocalizedDescriptionKey: "Update failed: \(body)"])
        }
    }
}

// MARK: - URL Replacement in Page Data

func findVideoURLs(in pageData: [String: Any]) -> [String] {
    var urls: [String] = []

    func processContent(_ content: [String: Any]) {
        if let type = content["type"] as? [String: Any], type.keys.contains("video") {
            if let value = content["value"] as? String {
                urls.append(value)
            }
        }
    }

    func processColumn(_ column: [String: Any]) {
        if let contents = column["contents"] as? [[String: Any]] {
            for content in contents {
                processContent(content)
            }
        }
    }

    func processRow(_ row: [String: Any]) {
        if let columns = row["columns"] as? [[String: Any]] {
            for column in columns {
                processColumn(column)
            }
        }
    }

    func processSection(_ section: [String: Any]) {
        if let rows = section["rows"] as? [[String: Any]] {
            for row in rows {
                processRow(row)
            }
        }
    }

    if let sections = pageData["sections"] as? [[String: Any]] {
        for section in sections {
            processSection(section)
        }
    }

    return urls
}

func replaceVideoURL(in pageData: inout [String: Any], oldURL: String, newURL: String) -> Bool {
    var found = false

    func processContent(_ content: inout [String: Any]) {
        if let type = content["type"] as? [String: Any], type.keys.contains("video") {
            if let value = content["value"] as? String, value == oldURL {
                content["value"] = newURL
                found = true
            }
        }
    }

    func processColumn(_ column: inout [String: Any]) {
        if var contents = column["contents"] as? [[String: Any]] {
            for i in 0..<contents.count {
                processContent(&contents[i])
            }
            column["contents"] = contents
        }
    }

    func processRow(_ row: inout [String: Any]) {
        if var columns = row["columns"] as? [[String: Any]] {
            for i in 0..<columns.count {
                processColumn(&columns[i])
            }
            row["columns"] = columns
        }
    }

    func processSection(_ section: inout [String: Any]) {
        if var rows = section["rows"] as? [[String: Any]] {
            for i in 0..<rows.count {
                processRow(&rows[i])
            }
            section["rows"] = rows
        }
    }

    if var sections = pageData["sections"] as? [[String: Any]] {
        for i in 0..<sections.count {
            processSection(&sections[i])
        }
        pageData["sections"] = sections
    }

    return found
}

// MARK: - Main Conversion Flow

func downloadVideo(from urlString: String) async throws -> URL {
    guard let url = URL(string: urlString) else {
        throw HLSConversionEngine.HLSError.downloadFailed("Invalid URL: \(urlString)")
    }

    print("[Download] \(url.lastPathComponent)")

    let (tempURL, response) = try await URLSession.shared.download(from: url)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw HLSConversionEngine.HLSError.downloadFailed("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
    }

    let destURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("mp4")

    try FileManager.default.moveItem(at: tempURL, to: destURL)

    let attrs = try FileManager.default.attributesOfItem(atPath: destURL.path)
    let sizeMB = (attrs[.size] as? Int64 ?? 0) / 1024 / 1024
    print("[Download] Complete: \(sizeMB) MB")

    return destURL
}

func convertAndUpload(source: String, dryRun: Bool) async throws -> String {
    print("\n" + String(repeating: "═", count: 70))
    print("CONVERTING: \(source)")
    print(String(repeating: "═", count: 70))

    // 1. Download
    let localURL: URL
    if source.hasPrefix("http") {
        localURL = try await downloadVideo(from: source)
    } else {
        localURL = URL(fileURLWithPath: source)
    }

    // 2. Convert to HLS
    let timestamp = Int(Date().timeIntervalSince1970)
    let outputDir = FileManager.default.temporaryDirectory.appendingPathComponent("hls_\(timestamp)")

    let engine = HLSConversionEngine()
    let config = HLSConversionEngine.Configuration(
        inputFileURL: localURL,
        outputDirectoryURL: outputDir
    )

    let playlistURL = try await engine.convertToHLS(using: config)

    // 3. Collect segment files
    var hlsFiles: [URL] = []
    if let enumerator = FileManager.default.enumerator(at: outputDir, includingPropertiesForKeys: nil) {
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension != "m3u8" {
                hlsFiles.append(fileURL)
            }
        }
    }

    print("[Upload] \(hlsFiles.count) segments to upload")

    // 4. Upload segments
    let uploader = MediaUploader(baseURL: apiBaseURL, dryRun: dryRun)
    var filenameToURL: [String: String] = [:]

    for (index, fileURL) in hlsFiles.enumerated() {
        let data = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let ext = fileURL.pathExtension.lowercased()

        let contentType = ext == "mp4" ? "video/mp4" : "video/iso.segment"
        let mediaType = ext == "mp4" ? "video" : "m4s"  // JWS/JBS mediaType values

        print("[Upload] \(index + 1)/\(hlsFiles.count): \(filename) (\(data.count / 1024) KB)")

        let cdnURL = try await uploader.upload(
            data: data,
            filename: UUID().uuidString + "." + ext,
            contentType: contentType,
            mediaType: mediaType
        )
        filenameToURL[filename] = cdnURL
    }

    // 5. Update playlist with CDN URLs
    var playlistContent = try String(contentsOf: playlistURL, encoding: .utf8)
    for (original, cdn) in filenameToURL {
        playlistContent = playlistContent.replacingOccurrences(of: original, with: cdn)
    }

    // 6. Upload playlist
    let playlistData = playlistContent.data(using: .utf8)!
    let finalURL = try await uploader.upload(
        data: playlistData,
        filename: UUID().uuidString + ".m3u8",
        contentType: "application/x-mpegURL",
        mediaType: "hls"  // JWS/JBS mediaType value
    )

    // 7. Cleanup
    try? FileManager.default.removeItem(at: outputDir)
    if source.hasPrefix("http") {
        try? FileManager.default.removeItem(at: localURL)
    }

    print("[DONE] HLS URL: \(finalURL)")
    return finalURL
}

func convertAllAndUpdateWebsite(
    websiteHost: String,
    mp4URLs: [String],
    dryRun: Bool
) async {
    guard let websiteID = websiteIDs[websiteHost] else {
        print("Unknown website: \(websiteHost)")
        return
    }

    var api = WebsiteAPI(baseURL: apiBaseURL, masterKey: masterKey)
    api.dryRun = dryRun
    var urlMapping: [String: String] = [:] // old -> new

    // PHASE 0: Create backup FIRST
    print("\n" + String(repeating: "▓", count: 70))
    print("PHASE 0: CREATING BACKUP")
    print(String(repeating: "▓", count: 70))

    var pagesToBackup: [(id: String, title: String, data: [String: Any])] = []

    do {
        let pages = try await api.listPages(websiteID: websiteID)

        for pageMeta in pages {
            guard let pageID = pageMeta["id"] as? String else { continue }
            let pageTitle = pageMeta["title"] as? String ?? "Unknown"

            let pageData = try await api.getPage(websiteID: websiteID, pageID: pageID)
            let videoURLs = findVideoURLs(in: pageData)

            // Only backup pages that have videos we're converting
            let hasTargetVideos = videoURLs.contains { url in
                mp4URLs.contains(url)
            }

            if hasTargetVideos {
                pagesToBackup.append((id: pageID, title: pageTitle, data: pageData))
                print("[Backup] \(pageTitle) - \(videoURLs.count) videos")
            }
        }

        if !pagesToBackup.isEmpty {
            let backupURL = try createBackup(websiteHost: websiteHost, pages: pagesToBackup)
            print("\n[BACKUP CREATED] \(backupURL.path)")
            print("[REVERT COMMAND] swift convert-to-hls.swift --revert \(backupURL.lastPathComponent)")
        } else {
            print("[INFO] No pages with target videos found - no backup needed")
        }
    } catch {
        print("[ERROR] Failed to create backup: \(error.localizedDescription)")
        print("[ABORT] Cannot proceed without backup")
        return
    }

    // PHASE 1: Convert all videos
    print("\n" + String(repeating: "▓", count: 70))
    print("PHASE 1: CONVERTING \(mp4URLs.count) VIDEOS")
    print(String(repeating: "▓", count: 70))

    for mp4URL in mp4URLs {
        do {
            let hlsURL = try await convertAndUpload(source: mp4URL, dryRun: dryRun)
            urlMapping[mp4URL] = hlsURL
        } catch {
            print("[ERROR] \(mp4URL): \(error.localizedDescription)")
        }
    }

    // PHASE 2: Update website pages
    print("\n" + String(repeating: "▓", count: 70))
    print("PHASE 2: UPDATING WEBSITE PAGES")
    print(String(repeating: "▓", count: 70))

    do {
        let pages = try await api.listPages(websiteID: websiteID)

        for pageMeta in pages {
            guard let pageID = pageMeta["id"] as? String else { continue }
            let pageTitle = pageMeta["title"] as? String ?? "Unknown"

            var pageData = try await api.getPage(websiteID: websiteID, pageID: pageID)
            var pageUpdated = false

            for (oldURL, newURL) in urlMapping {
                if replaceVideoURL(in: &pageData, oldURL: oldURL, newURL: newURL) {
                    print("[Page] \(pageTitle): Replacing \(oldURL.suffix(30))... → HLS")
                    pageUpdated = true
                }
            }

            if pageUpdated {
                try await api.updatePage(websiteID: websiteID, pageID: pageID, pageData: pageData)
                print("[Page] \(pageTitle): Saved ✓")
            }
        }
    } catch {
        print("[ERROR] Failed to update pages: \(error.localizedDescription)")
    }

    // PHASE 3: Summary
    print("\n" + String(repeating: "═", count: 70))
    print(dryRun ? "DRY RUN COMPLETE" : "CONVERSION COMPLETE")
    print(String(repeating: "═", count: 70))
    print("Converted \(urlMapping.count) videos to HLS")
    print("")
    for (old, new) in urlMapping {
        let shortOld = old.count > 50 ? "..." + old.suffix(47) : old
        print("  \(shortOld)")
        print("    → \(new)")
    }

    if !dryRun {
        print("\n[IMPORTANT] If anything went wrong, revert with:")
        print("  swift convert-to-hls.swift --backups  # List available backups")
        print("  swift convert-to-hls.swift --revert <backup-file>")
    }
}

// MARK: - CLI Entry Point

func printUsage() {
    print("""
    Convert to HLS - JWS Skills

    End-to-end: Download MP4 → Convert (AVFoundation) → Upload CDN → Update Website

    Usage:
      swift convert-to-hls.swift <mp4-url>                 # Convert single video
      swift convert-to-hls.swift --all                     # Convert all means.ai MP4s
      swift convert-to-hls.swift --dry-run --all           # Test without changes
      swift convert-to-hls.swift --list                    # List MP4s needing conversion
      swift convert-to-hls.swift --backups                 # List available backups
      swift convert-to-hls.swift --revert <backup-file>    # Revert to backup

    Options:
      --bearer TOKEN    Custom bearer token (default: guest token)
      --dry-run         Test without uploading or updating website

    Examples:
      swift convert-to-hls.swift --dry-run --all           # Safe test run
      swift convert-to-hls.swift --all                     # Real conversion
      swift convert-to-hls.swift --revert backup-means.ai-2024-01-22T10:30:00Z.json
    """)
}

let args = Array(CommandLine.arguments.dropFirst())

guard !args.isEmpty else {
    printUsage()
    exit(1)
}

var sources: [String] = []
var convertAll = false
var listOnly = false
var dryRun = false
var showBackups = false
var revertFile: String?

var i = 0
while i < args.count {
    switch args[i] {
    case "--all":
        convertAll = true
    case "--list":
        listOnly = true
    case "--dry-run":
        dryRun = true
    case "--backups":
        showBackups = true
    case "--revert":
        i += 1
        if i < args.count { revertFile = args[i] }
    case "--help", "-h":
        printUsage()
        exit(0)
    default:
        sources.append(args[i])
    }
    i += 1
}

if listOnly {
    print("MP4 videos on means.ai needing HLS conversion:\n")
    for (i, url) in meansAIMp4s.enumerated() {
        print("  \(i + 1). \(url)")
    }
    print("\nRun with --all to convert all videos")
    print("Run with --dry-run --all to test without changes")
    exit(0)
}

if showBackups {
    listBackups()
    exit(0)
}

let runLoop = RunLoop.current
var finished = false

Task {
    if let revertFile = revertFile {
        // Handle revert
        let backupURL: URL
        if revertFile.hasPrefix("/") {
            backupURL = URL(fileURLWithPath: revertFile)
        } else {
            backupURL = backupDirectory.appendingPathComponent(revertFile)
        }

        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            print("Backup file not found: \(backupURL.path)")
            print("Use --backups to list available backups")
            exit(1)
        }

        do {
            try await revertFromBackup(backupURL: backupURL)
        } catch {
            print("[ERROR] Revert failed: \(error.localizedDescription)")
            exit(1)
        }
    } else if convertAll {
        if dryRun {
            print("\n" + String(repeating: "⚠", count: 35))
            print("DRY RUN MODE - No changes will be made")
            print(String(repeating: "⚠", count: 35))
        }
        await convertAllAndUpdateWebsite(
            websiteHost: "means.ai",
            mp4URLs: meansAIMp4s,
            dryRun: dryRun
        )
    } else if !sources.isEmpty {
        for source in sources {
            do {
                _ = try await convertAndUpload(source: source, dryRun: dryRun)
            } catch {
                print("[ERROR] \(error.localizedDescription)")
            }
        }
    } else {
        printUsage()
    }
    finished = true
}

while !finished {
    runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
}
