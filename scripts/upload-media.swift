#!/usr/bin/env swift
//
//  upload-media.swift
//  JWS Skills
//
//  Uploads media to the JWS CDN via api.voosey.com
//  Returns the CDN URL on success
//
//  Usage: swift upload-media.swift <source-url-or-path> [--bearer TOKEN]
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Configuration

let apiBaseURL = "https://api.voosey.com"
let defaultBearerToken = "hfmf6c3viXF/D/aGZ8eIwg=="

// MARK: - Native Types (matching JBS/JBSMedia)

enum MediaType: String, Codable {
    case imageUpload
    case videoUpload
    case audioUpload
    case documentUpload
    case hlsUpload
}

struct MediaUploadData: Codable {
    var bucketID: String?
    var filename: String
    var totalBytes: Int?
    var mediaType: MediaType
}

struct MediaGlobal: Codable {
    var id: UUID
    var filename: String
    var mediaURL: String
    var totalBytes: Int?
    var mediaType: MediaType
}

struct MediaPersonal: Codable {
    var putUploadRequestURL: String?
    var global: MediaGlobal
}

// MARK: - Utilities

func printError(_ message: String) {
    fputs("✗ \(message)\n", stderr)
}

func printProgress(_ message: String) {
    fputs("  \(message)\n", stderr)
}

func getFullResolutionURL(_ url: String) -> String {
    var cleanURL = url
    // Remove WordPress size suffixes to get full resolution
    let patterns = ["-thumb", "-\\d+x\\d+", "-scaled", "-150x150", "-300x300", "-1024x1024"]
    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(cleanURL.startIndex..., in: cleanURL)
            cleanURL = regex.stringByReplacingMatches(in: cleanURL, options: [], range: range, withTemplate: "")
        }
    }
    return cleanURL
}

func detectMediaType(from filename: String) -> MediaType {
    let ext = (filename as NSString).pathExtension.lowercased()
    switch ext {
    case "jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "svg":
        return .imageUpload
    case "mp4", "mov", "m4v", "webm", "avi":
        return .videoUpload
    case "mp3", "m4a", "wav", "aac", "flac":
        return .audioUpload
    case "m3u8":
        return .hlsUpload
    default:
        return .documentUpload
    }
}

// MARK: - Main Upload Function

func uploadMedia(source: String, bearerToken: String) async throws -> String {
    let semaphore = DispatchSemaphore(value: 0)

    // Determine if source is URL or local path
    let isURL = source.hasPrefix("http://") || source.hasPrefix("https://")
    let sourceURL: URL
    var imageData: Data
    var filename: String

    if isURL {
        let fullResURL = getFullResolutionURL(source)
        guard let url = URL(string: fullResURL) else {
            throw NSError(domain: "UploadMedia", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(source)"])
        }
        sourceURL = url
        filename = url.deletingPathExtension().lastPathComponent

        // Download from URL
        printProgress("Downloading from \(url.lastPathComponent)...")
        let (data, response) = try await URLSession.shared.data(from: sourceURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "UploadMedia", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to download: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)"])
        }
        imageData = data
    } else {
        // Local file
        let fileURL = URL(fileURLWithPath: source)
        filename = fileURL.deletingPathExtension().lastPathComponent
        imageData = try Data(contentsOf: fileURL)
    }

    // Determine content type and process image if needed
    let mediaType = detectMediaType(from: filename + ".jpg")
    var contentType = "application/octet-stream"

    if mediaType == .imageUpload {
        contentType = "image/jpeg"
        filename = filename + ".jpg"

        // Convert to JPEG with compression
        #if canImport(AppKit)
        if let image = NSImage(data: imageData),
           let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            if let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) {
                imageData = jpegData
            }
        }
        #endif
    }

    printProgress("Requesting signed upload URL...")

    // Step 1: Request signed URL from API
    let uploadRequest = MediaUploadData(
        bucketID: nil,
        filename: filename,
        totalBytes: imageData.count,
        mediaType: mediaType
    )

    var request = URLRequest(url: URL(string: "\(apiBaseURL)/media")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONEncoder().encode(uploadRequest)

    let (responseData, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        let body = String(data: responseData, encoding: .utf8) ?? "Unknown error"
        throw NSError(domain: "UploadMedia", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get signed URL: \(body)"])
    }

    let media = try JSONDecoder().decode(MediaPersonal.self, from: responseData)
    guard let signedURL = media.putUploadRequestURL else {
        throw NSError(domain: "UploadMedia", code: 4, userInfo: [NSLocalizedDescriptionKey: "No signed URL in response"])
    }

    printProgress("Uploading \(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))...")

    // Step 2: Upload to signed URL
    var uploadRequest2 = URLRequest(url: URL(string: signedURL)!)
    uploadRequest2.httpMethod = "PUT"
    uploadRequest2.setValue(contentType, forHTTPHeaderField: "Content-Type")
    uploadRequest2.setValue("public-read", forHTTPHeaderField: "x-amz-acl")
    uploadRequest2.httpBody = imageData

    let (_, uploadResponse) = try await URLSession.shared.data(for: uploadRequest2)
    guard let httpUploadResponse = uploadResponse as? HTTPURLResponse, httpUploadResponse.statusCode == 200 else {
        throw NSError(domain: "UploadMedia", code: 5, userInfo: [NSLocalizedDescriptionKey: "Upload failed: HTTP \((uploadResponse as? HTTPURLResponse)?.statusCode ?? 0)"])
    }

    return media.global.mediaURL
}

// MARK: - Batch Upload Function (Parallel)

func uploadMediaBatch(sources: [String], bearerToken: String, maxConcurrent: Int = 4) async -> [(source: String, result: Result<String, Error>)] {
    await withTaskGroup(of: (String, Result<String, Error>).self) { group in
        var results: [(String, Result<String, Error>)] = []
        var pending = sources[...]
        var inFlight = 0

        // Start initial batch
        while inFlight < maxConcurrent, let source = pending.popFirst() {
            inFlight += 1
            group.addTask {
                do {
                    let cdnURL = try await uploadMedia(source: source, bearerToken: bearerToken)
                    return (source, .success(cdnURL))
                } catch {
                    return (source, .failure(error))
                }
            }
        }

        // Process results and add more tasks
        for await result in group {
            results.append(result)
            inFlight -= 1

            if let source = pending.popFirst() {
                inFlight += 1
                group.addTask {
                    do {
                        let cdnURL = try await uploadMedia(source: source, bearerToken: bearerToken)
                        return (source, .success(cdnURL))
                    } catch {
                        return (source, .failure(error))
                    }
                }
            }
        }

        return results
    }
}

// MARK: - CLI Entry Point

let args = CommandLine.arguments
guard args.count >= 2 else {
    print("Usage: swift upload-media.swift <source-url-or-path> [--bearer TOKEN]")
    print("       swift upload-media.swift --batch <url1> <url2> ... [--bearer TOKEN]")
    print("")
    print("Examples:")
    print("  swift upload-media.swift https://example.com/image.jpg")
    print("  swift upload-media.swift /path/to/local/image.png")
    print("  swift upload-media.swift --batch url1.jpg url2.jpg url3.jpg")
    exit(1)
}

var bearerToken = defaultBearerToken
var sources: [String] = []
var isBatch = false

var i = 1
while i < args.count {
    let arg = args[i]
    if arg == "--bearer" && i + 1 < args.count {
        bearerToken = args[i + 1]
        i += 2
    } else if arg == "--batch" {
        isBatch = true
        i += 1
    } else {
        sources.append(arg)
        i += 1
    }
}

guard !sources.isEmpty else {
    printError("No source provided")
    exit(1)
}

// Run async
let runLoop = RunLoop.current
var finished = false

Task {
    do {
        if isBatch || sources.count > 1 {
            // Parallel batch upload
            let results = await uploadMediaBatch(sources: sources, bearerToken: bearerToken)
            for (source, result) in results {
                switch result {
                case .success(let cdnURL):
                    print("\(URL(string: source)?.lastPathComponent ?? source): \(cdnURL)")
                case .failure(let error):
                    printError("\(URL(string: source)?.lastPathComponent ?? source): \(error.localizedDescription)")
                }
            }
        } else {
            // Single upload
            let cdnURL = try await uploadMedia(source: sources[0], bearerToken: bearerToken)
            print(cdnURL)
        }
        finished = true
    } catch {
        printError(error.localizedDescription)
        exit(1)
    }
}

while !finished {
    runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
}
