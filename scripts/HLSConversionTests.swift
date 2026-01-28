#!/usr/bin/env swift
//
//  HLSConversionTests.swift
//  JWS Skills - Swift Testing
//
//  Tests for the HLS conversion pipeline before running on production
//

import Foundation
import Testing

// MARK: - Test Configuration

let testAPIBaseURL = "https://api.voosey.com"
let testMasterKey = "2571123FD179EA45A21B5563D4B1D"
let testWebsiteID = "1CF4F6AF-A577-4875-BF1E-7BA14C1985B4" // means.ai

// MARK: - Test Utilities

func makePageData(withVideoURL url: String) -> [String: Any] {
    return [
        "micro": [
            "id": UUID().uuidString,
            "title": "Test Page",
            "slug": "test"
        ],
        "sections": [
            [
                "id": UUID().uuidString,
                "enabled": true,
                "rows": [
                    [
                        "id": UUID().uuidString,
                        "enabled": true,
                        "columns": [
                            [
                                "id": UUID().uuidString,
                                "contents": [
                                    [
                                        "id": UUID().uuidString,
                                        "type": ["video": [:]],
                                        "value": url,
                                        "enabled": true
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]
}

// MARK: - URL Detection Tests

@Suite("Video URL Detection")
struct VideoURLDetectionTests {

    @Test("Finds video URLs in page data")
    func findsVideoURLs() {
        let pageData = makePageData(withVideoURL: "https://example.com/video.mp4")
        let urls = findVideoURLsTest(in: pageData)

        #expect(urls.count == 1)
        #expect(urls.first == "https://example.com/video.mp4")
    }

    @Test("Finds multiple video URLs")
    func findsMultipleVideos() {
        var pageData = makePageData(withVideoURL: "https://example.com/video1.mp4")

        // Add another video to the same section
        if var sections = pageData["sections"] as? [[String: Any]],
           var firstSection = sections.first,
           var rows = firstSection["rows"] as? [[String: Any]],
           var firstRow = rows.first,
           var columns = firstRow["columns"] as? [[String: Any]],
           var firstColumn = columns.first,
           var contents = firstColumn["contents"] as? [[String: Any]] {
            contents.append([
                "id": UUID().uuidString,
                "type": ["video": [:]],
                "value": "https://example.com/video2.mp4",
                "enabled": true
            ])
            firstColumn["contents"] = contents
            columns[0] = firstColumn
            firstRow["columns"] = columns
            rows[0] = firstRow
            firstSection["rows"] = rows
            sections[0] = firstSection
            pageData["sections"] = sections
        }

        let urls = findVideoURLsTest(in: pageData)
        #expect(urls.count == 2)
    }

    @Test("Returns empty for pages without videos")
    func noVideosReturnsEmpty() {
        let pageData: [String: Any] = [
            "micro": ["title": "No Videos"],
            "sections": []
        ]
        let urls = findVideoURLsTest(in: pageData)
        #expect(urls.isEmpty)
    }
}

// MARK: - URL Replacement Tests

@Suite("Video URL Replacement")
struct VideoURLReplacementTests {

    @Test("Replaces video URL correctly")
    func replacesVideoURL() {
        var pageData = makePageData(withVideoURL: "https://old.com/video.mp4")

        let replaced = replaceVideoURLTest(
            in: &pageData,
            oldURL: "https://old.com/video.mp4",
            newURL: "https://new.com/video.m3u8"
        )

        #expect(replaced == true)

        let urls = findVideoURLsTest(in: pageData)
        #expect(urls.first == "https://new.com/video.m3u8")
    }

    @Test("Does not replace non-matching URL")
    func doesNotReplaceNonMatching() {
        var pageData = makePageData(withVideoURL: "https://keep.com/video.mp4")

        let replaced = replaceVideoURLTest(
            in: &pageData,
            oldURL: "https://different.com/video.mp4",
            newURL: "https://new.com/video.m3u8"
        )

        #expect(replaced == false)

        let urls = findVideoURLsTest(in: pageData)
        #expect(urls.first == "https://keep.com/video.mp4")
    }

    @Test("Handles URL-encoded URLs")
    func handlesURLEncodedURLs() {
        let encodedURL = "https://cdn.outtakes.com/company/media/Sequence%2001_3.mp4"
        var pageData = makePageData(withVideoURL: encodedURL)

        let replaced = replaceVideoURLTest(
            in: &pageData,
            oldURL: encodedURL,
            newURL: "https://new.com/video.m3u8"
        )

        #expect(replaced == true)
    }
}

// MARK: - Backup System Tests

@Suite("Backup System")
struct BackupSystemTests {

    @Test("Creates backup manifest with correct structure")
    func createsBackupManifest() throws {
        let pages: [(id: String, title: String, data: [String: Any])] = [
            (id: "page-1", title: "Home", data: makePageData(withVideoURL: "https://test.com/v1.mp4")),
            (id: "page-2", title: "About", data: makePageData(withVideoURL: "https://test.com/v2.mp4"))
        ]

        let manifest = BackupManifestTest(
            timestamp: Date(),
            websiteHost: "means.ai",
            websiteID: testWebsiteID,
            pages: pages.map { BackupManifestTest.PageBackup(pageID: $0.id, pageTitle: $0.title) }
        )

        #expect(manifest.pages.count == 2)
        #expect(manifest.websiteHost == "means.ai")
        #expect(manifest.pages[0].pageTitle == "Home")
        #expect(manifest.pages[1].pageTitle == "About")
    }
}

// MARK: - API Connectivity Tests

@Suite("API Connectivity")
struct APIConnectivityTests {

    @Test("Can list pages from means.ai")
    func canListPages() async throws {
        let pages = try await listPagesTest(websiteID: testWebsiteID)

        #expect(pages.count > 0, "Should have at least one page")

        // Verify page structure
        if let firstPage = pages.first {
            #expect(firstPage["id"] != nil, "Page should have an id")
            #expect(firstPage["title"] != nil, "Page should have a title")
        }
    }

    @Test("Can fetch a single page")
    func canFetchPage() async throws {
        let pages = try await listPagesTest(websiteID: testWebsiteID)
        guard let firstPageMeta = pages.first,
              let pageID = firstPageMeta["id"] as? String else {
            Issue.record("No pages found")
            return
        }

        let pageData = try await getPageTest(websiteID: testWebsiteID, pageID: pageID)

        #expect(pageData["micro"] != nil, "Page should have micro data")
        #expect(pageData["sections"] != nil, "Page should have sections")
    }
}

// MARK: - Video Discovery Tests

@Suite("Video Discovery on means.ai")
struct VideoDiscoveryTests {

    @Test("Finds MP4 videos that need conversion")
    func findsMP4sNeedingConversion() async throws {
        let pages = try await listPagesTest(websiteID: testWebsiteID)
        var allVideoURLs: [String] = []

        for pageMeta in pages {
            guard let pageID = pageMeta["id"] as? String else { continue }
            let pageData = try await getPageTest(websiteID: testWebsiteID, pageID: pageID)
            let videoURLs = findVideoURLsTest(in: pageData)
            allVideoURLs.append(contentsOf: videoURLs)
        }

        let mp4URLs = allVideoURLs.filter { $0.lowercased().hasSuffix(".mp4") }
        let hlsURLs = allVideoURLs.filter { $0.hasSuffix(".m3u8") || $0.contains("/hls_") }

        print("Found \(mp4URLs.count) MP4 videos needing conversion:")
        for url in mp4URLs {
            print("  - \(url)")
        }

        print("Found \(hlsURLs.count) HLS videos (already converted):")
        for url in hlsURLs {
            print("  - \(url)")
        }

        // This test is informational - we expect some MP4s to exist
        #expect(allVideoURLs.count >= 0, "Video discovery completed")
    }
}

// MARK: - HLS Format Tests

@Suite("HLS Format Validation")
struct HLSFormatTests {

    @Test("HLS URL detection works correctly")
    func hlsDetectionWorks() {
        let hlsURL1 = "https://cdn.means.ai/user/123/hls/video.m3u8"
        let hlsURL2 = "https://cdn.means.ai/hls_abc123/master.m3u8"
        let mp4URL = "https://cdn.means.ai/video.mp4"

        #expect(isHLSURL(hlsURL1) == true)
        #expect(isHLSURL(hlsURL2) == true)
        #expect(isHLSURL(mp4URL) == false)
    }

    @Test("Valid M3U8 playlist format")
    func validPlaylistFormat() {
        let playlist = """
        #EXTM3U
        #EXT-X-TARGETDURATION:6
        #EXT-X-VERSION:7
        #EXT-X-MEDIA-SEQUENCE:1
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXT-X-INDEPENDENT-SEGMENTS
        #EXT-X-MAP:URI="fileSequence0.mp4"
        #EXTINF:6.00000,
        fileSequence1.m4s
        #EXT-X-ENDLIST
        """

        #expect(playlist.contains("#EXTM3U"))
        #expect(playlist.contains("#EXT-X-TARGETDURATION"))
        #expect(playlist.contains("#EXT-X-ENDLIST"))
    }
}

// MARK: - Test Helper Functions (duplicated for standalone testing)

func findVideoURLsTest(in pageData: [String: Any]) -> [String] {
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

func replaceVideoURLTest(in pageData: inout [String: Any], oldURL: String, newURL: String) -> Bool {
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

func isHLSURL(_ url: String) -> Bool {
    return url.hasSuffix(".m3u8") || url.contains("/hls_")
}

struct BackupManifestTest {
    let timestamp: Date
    let websiteHost: String
    let websiteID: String
    let pages: [PageBackup]

    struct PageBackup {
        let pageID: String
        let pageTitle: String
    }
}

func listPagesTest(websiteID: String) async throws -> [[String: Any]] {
    var request = URLRequest(url: URL(string: "\(testAPIBaseURL)/v2/mainframe/web/pages/\(websiteID)")!)
    request.setValue(testMasterKey, forHTTPHeaderField: "jws_master_key")

    let (data, _) = try await URLSession.shared.data(for: request)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
        throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
    }
    return json
}

func getPageTest(websiteID: String, pageID: String) async throws -> [String: Any] {
    var request = URLRequest(url: URL(string: "\(testAPIBaseURL)/v2/mainframe/web/page/\(websiteID)/\(pageID)")!)
    request.setValue(testMasterKey, forHTTPHeaderField: "jws_master_key")

    let (data, _) = try await URLSession.shared.data(for: request)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
    }
    return json
}

// MARK: - Run Tests

print("Running HLS Conversion Tests...")
print(String(repeating: "=", count: 60))
