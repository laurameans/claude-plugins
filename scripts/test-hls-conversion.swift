#!/usr/bin/env swift
//
//  test-hls-conversion.swift
//  JWS Skills - Pre-flight Tests
//
//  Validates the HLS conversion pipeline before running on production
//  Run this BEFORE running convert-to-hls.swift --all
//

import Foundation

// MARK: - Configuration

// means.ai is on the outtakes.com server, NOT api.voosey.com
let apiBaseURL = "https://outtakes.com"
let masterKey = "2571123FD179EA45A21B5563D4B1D"
let websiteID = "1CF4F6AF-A577-4875-BF1E-7BA14C1985B4" // means.ai

// Known MP4s we expect to convert
let expectedMP4s = [
    "https://cdn.outtakes.com/company/media/9_Q29tcCAzOF8x_1.mp4",
    "https://cdn.outtakes.com/company/media/Sequence%2001_3.mp4",
    "https://cdn.voosey.com/media/083125-2.mp4",
    "https://cdn.neuraform.com/company/marketing/Comp%204.MP4",
    "https://ghf.nyc3.digitaloceanspaces.com/Website%202021_1.mp4",
    "https://cdn.revolusun.app/assets/videos/Commercial-V2-30-secs.mp4",
    "https://c.jws.ai/JWSpoweredby.mp4",
    "https://c.jws.ai/uc1.mp4"
]

// MARK: - Test Utilities

var testsPassed = 0
var testsFailed = 0

func test(_ name: String, _ condition: Bool, detail: String = "") {
    if condition {
        print("  ✅ \(name)")
        testsPassed += 1
    } else {
        print("  ❌ \(name)\(detail.isEmpty ? "" : " - \(detail)")")
        testsFailed += 1
    }
}

func testAsync(_ name: String, _ block: () async throws -> Bool) async {
    do {
        let result = try await block()
        test(name, result)
    } catch {
        test(name, false, detail: error.localizedDescription)
    }
}

// MARK: - Helper Functions

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
            for content in contents { processContent(content) }
        }
    }

    func processRow(_ row: [String: Any]) {
        if let columns = row["columns"] as? [[String: Any]] {
            for column in columns { processColumn(column) }
        }
    }

    func processSection(_ section: [String: Any]) {
        if let rows = section["rows"] as? [[String: Any]] {
            for row in rows { processRow(row) }
        }
    }

    if let sections = pageData["sections"] as? [[String: Any]] {
        for section in sections { processSection(section) }
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
            for i in 0..<contents.count { processContent(&contents[i]) }
            column["contents"] = contents
        }
    }

    func processRow(_ row: inout [String: Any]) {
        if var columns = row["columns"] as? [[String: Any]] {
            for i in 0..<columns.count { processColumn(&columns[i]) }
            row["columns"] = columns
        }
    }

    func processSection(_ section: inout [String: Any]) {
        if var rows = section["rows"] as? [[String: Any]] {
            for i in 0..<rows.count { processRow(&rows[i]) }
            section["rows"] = rows
        }
    }

    if var sections = pageData["sections"] as? [[String: Any]] {
        for i in 0..<sections.count { processSection(&sections[i]) }
        pageData["sections"] = sections
    }

    return found
}

func makeTestPageData(withVideoURL url: String) -> [String: Any] {
    return [
        "micro": ["id": UUID().uuidString, "title": "Test", "slug": "test"],
        "sections": [[
            "id": UUID().uuidString,
            "enabled": true,
            "rows": [[
                "id": UUID().uuidString,
                "enabled": true,
                "columns": [[
                    "id": UUID().uuidString,
                    "contents": [[
                        "id": UUID().uuidString,
                        "type": ["video": [:]],
                        "value": url,
                        "enabled": true
                    ]]
                ]]
            ]]
        ]]
    ]
}

// MARK: - API Functions

func listPages() async throws -> [[String: Any]] {
    var request = URLRequest(url: URL(string: "\(apiBaseURL)/v2/mainframe/web/pages/\(websiteID)")!)
    request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
}

func getPage(pageID: String) async throws -> [String: Any] {
    var request = URLRequest(url: URL(string: "\(apiBaseURL)/v2/mainframe/web/page/\(websiteID)/\(pageID)")!)
    request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

func checkVideoAccessibility(url: String) async -> Bool {
    guard let videoURL = URL(string: url) else { return false }
    var request = URLRequest(url: videoURL)
    request.httpMethod = "HEAD"
    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    } catch {
        return false
    }
}

// MARK: - Test Suites

func runURLDetectionTests() {
    print("\n📋 URL Detection Tests")
    print(String(repeating: "-", count: 50))

    // Test 1: Find video URL
    let pageData1 = makeTestPageData(withVideoURL: "https://test.com/video.mp4")
    let found1 = findVideoURLs(in: pageData1)
    test("Finds video URL in page data", found1.count == 1 && found1.first == "https://test.com/video.mp4")

    // Test 2: Empty page
    let pageData2: [String: Any] = ["micro": [:], "sections": []]
    let found2 = findVideoURLs(in: pageData2)
    test("Returns empty for page without videos", found2.isEmpty)

    // Test 3: HLS detection (supports .m3u8 suffix OR /hls/ in path)
    test("Detects .m3u8 as HLS", "https://test.com/video.m3u8".hasSuffix(".m3u8"))
    test("Detects /hls/ path as HLS", "https://cdn.means.ai/user/123/hls/abc".contains("/hls/"))
    test("Does not detect .mp4 as HLS", !("https://test.com/video.mp4".hasSuffix(".m3u8") || "https://test.com/video.mp4".contains("/hls/")))
}

func runURLReplacementTests() {
    print("\n🔄 URL Replacement Tests")
    print(String(repeating: "-", count: 50))

    // Test 1: Basic replacement
    var pageData1 = makeTestPageData(withVideoURL: "https://old.com/video.mp4")
    let replaced1 = replaceVideoURL(in: &pageData1, oldURL: "https://old.com/video.mp4", newURL: "https://new.com/video.m3u8")
    let newURLs1 = findVideoURLs(in: pageData1)
    test("Replaces video URL", replaced1 && newURLs1.first == "https://new.com/video.m3u8")

    // Test 2: Non-matching URL
    var pageData2 = makeTestPageData(withVideoURL: "https://keep.com/video.mp4")
    let replaced2 = replaceVideoURL(in: &pageData2, oldURL: "https://different.com/video.mp4", newURL: "https://new.com/video.m3u8")
    let newURLs2 = findVideoURLs(in: pageData2)
    test("Does not replace non-matching URL", !replaced2 && newURLs2.first == "https://keep.com/video.mp4")

    // Test 3: URL-encoded URL
    let encodedURL = "https://cdn.outtakes.com/company/media/Sequence%2001_3.mp4"
    var pageData3 = makeTestPageData(withVideoURL: encodedURL)
    let replaced3 = replaceVideoURL(in: &pageData3, oldURL: encodedURL, newURL: "https://new.com/video.m3u8")
    test("Handles URL-encoded URLs", replaced3)
}

func runAPITests() async {
    print("\n🌐 API Connectivity Tests")
    print(String(repeating: "-", count: 50))

    // Test 1: List pages
    await testAsync("Can list pages from means.ai") {
        let pages = try await listPages()
        return pages.count > 0
    }

    // Test 2: Fetch single page
    await testAsync("Can fetch a single page") {
        let pages = try await listPages()
        guard let pageID = pages.first?["id"] as? String else { return false }
        let pageData = try await getPage(pageID: pageID)
        return pageData["micro"] != nil && pageData["sections"] != nil
    }
}

func runVideoDiscoveryTests() async {
    print("\n🎬 Video Discovery Tests")
    print(String(repeating: "-", count: 50))

    var allVideoURLs: [String] = []
    var pagesWithVideos: [(title: String, videos: [String])] = []

    do {
        let pages = try await listPages()

        for pageMeta in pages {
            guard let pageID = pageMeta["id"] as? String else { continue }
            let pageTitle = pageMeta["title"] as? String ?? "Unknown"
            let pageData = try await getPage(pageID: pageID)
            let videoURLs = findVideoURLs(in: pageData)

            if !videoURLs.isEmpty {
                pagesWithVideos.append((title: pageTitle, videos: videoURLs))
                allVideoURLs.append(contentsOf: videoURLs)
            }
        }

        test("Found pages with videos", !pagesWithVideos.isEmpty, detail: "Found \(pagesWithVideos.count) pages with videos")

        let mp4URLs = allVideoURLs.filter { $0.lowercased().hasSuffix(".mp4") }
        let hlsURLs = allVideoURLs.filter { $0.hasSuffix(".m3u8") || $0.contains("/hls/") }

        test("Found MP4 videos to convert", mp4URLs.count > 0, detail: "\(mp4URLs.count) MP4s found")
        test("Some HLS videos already exist", hlsURLs.count > 0, detail: "\(hlsURLs.count) HLS already")

        print("\n  📄 Pages with videos:")
        for page in pagesWithVideos {
            print("    • \(page.title): \(page.videos.count) video(s)")
        }

    } catch {
        test("Video discovery completed", false, detail: error.localizedDescription)
    }
}

func runVideoAccessibilityTests() async {
    print("\n📡 Video Accessibility Tests")
    print(String(repeating: "-", count: 50))

    print("  Checking if source videos are accessible...")

    var accessible = 0
    var inaccessible = 0

    for url in expectedMP4s {
        let isAccessible = await checkVideoAccessibility(url: url)
        let shortURL = url.count > 50 ? "..." + url.suffix(47) : url
        if isAccessible {
            print("    ✅ \(shortURL)")
            accessible += 1
        } else {
            print("    ⚠️  \(shortURL) (may be slow or restricted)")
            inaccessible += 1
        }
    }

    test("All source videos accessible", inaccessible == 0, detail: "\(accessible)/\(expectedMP4s.count) accessible")
}

func runBackupSystemTests() {
    print("\n💾 Backup System Tests")
    print(String(repeating: "-", count: 50))

    let backupDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".jws-hls-backups")

    // Test backup directory creation
    do {
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        test("Can create backup directory", true)
    } catch {
        test("Can create backup directory", false, detail: error.localizedDescription)
    }

    // Test backup file writing
    let testBackupURL = backupDir.appendingPathComponent("test-backup.json")
    do {
        let testData = ["test": "data"]
        let jsonData = try JSONSerialization.data(withJSONObject: testData)
        try jsonData.write(to: testBackupURL)
        test("Can write backup files", true)

        // Cleanup
        try FileManager.default.removeItem(at: testBackupURL)
    } catch {
        test("Can write backup files", false, detail: error.localizedDescription)
    }
}

// MARK: - Main

print("""
╔══════════════════════════════════════════════════════════════════════╗
║          HLS CONVERSION PRE-FLIGHT TEST SUITE                        ║
║          Testing before production deployment                        ║
╚══════════════════════════════════════════════════════════════════════╝
""")

let runLoop = RunLoop.current
var finished = false

Task {
    // Run all test suites
    runURLDetectionTests()
    runURLReplacementTests()
    runBackupSystemTests()
    await runAPITests()
    await runVideoDiscoveryTests()
    await runVideoAccessibilityTests()

    // Summary
    print("\n" + String(repeating: "═", count: 60))
    print("TEST SUMMARY")
    print(String(repeating: "═", count: 60))
    print("  Passed: \(testsPassed)")
    print("  Failed: \(testsFailed)")
    print("")

    if testsFailed == 0 {
        print("✅ ALL TESTS PASSED - Safe to proceed with conversion")
        print("")
        print("To convert all videos, run:")
        print("  swift convert-to-hls.swift --dry-run --all  # Test run first")
        print("  swift convert-to-hls.swift --all            # Real conversion")
    } else {
        print("❌ SOME TESTS FAILED - Review issues before proceeding")
        print("")
        print("Fix the issues above before running the conversion.")
    }

    finished = true
}

while !finished {
    runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
}
