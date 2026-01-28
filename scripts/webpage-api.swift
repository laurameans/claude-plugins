#!/usr/bin/env swift
//
//  webpage-api.swift
//  JWS Skills
//
//  WebPage API operations via api.voosey.com
//  Supports GET, POST, PUT, DELETE operations with native JBS types
//
//  Usage:
//    swift webpage-api.swift get <website-id> <page-id>
//    swift webpage-api.swift post <website-id> <json-file>
//    swift webpage-api.swift put <website-id> <page-id> <json-file>
//    swift webpage-api.swift delete <website-id> <page-id>
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Configuration

let apiBaseURL = "https://api.voosey.com"
let masterKey = "2571123FD179EA45A21B5563D4B1D"

// MARK: - Native Types (matching JBS/JBSWeb exactly)

enum WebTaxonomy: String, Codable, CaseIterable {
    case article
    case devlog
    case documentation
    case `internal`
    case onboarding
    case publication  // Added for vince-lee books
}

enum Visibility: String, Codable, CaseIterable {
    case published
    case draft
    case userAuthenticated
    case `internal`
    case confidential
    case restricted
}

struct WebPageMicro: Codable {
    var id: UUID?
    var title: String
    var slug: String
    var createdDate: Date?
    var updatedDate: Date?
    var visibility: Visibility
    var taxonomy: WebTaxonomy?
    var isTaxonomyBase: Bool?
    var featuredImageURL: String?
    var metaDescription: String?
    var keywords: String?
}

enum ModuleType: Codable, CaseIterable {
    case text
    case image
    case button
    case video
    case portfolio

    enum CodingKeys: String, CodingKey {
        case text, image, button, video, portfolio
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text: try container.encode([String: String](), forKey: .text)
        case .image: try container.encode([String: String](), forKey: .image)
        case .button: try container.encode([String: String](), forKey: .button)
        case .video: try container.encode([String: String](), forKey: .video)
        case .portfolio: try container.encode([String: String](), forKey: .portfolio)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.text) { self = .text }
        else if container.contains(.image) { self = .image }
        else if container.contains(.button) { self = .button }
        else if container.contains(.video) { self = .video }
        else if container.contains(.portfolio) { self = .portfolio }
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown ModuleType"
            ))
        }
    }
}

struct WebContent: Codable {
    var id: UUID
    var type: ModuleType
    var value: String
    var link: String?
    var enabled: Bool
    var rawHTML: String?
    var doubleWidth: Bool?
    var style: String?
    var darkModeValue: String?
    var altText: String?

    init(id: UUID = UUID(), type: ModuleType, value: String, link: String? = nil, enabled: Bool = true, rawHTML: String? = nil, doubleWidth: Bool? = nil, style: String? = nil, darkModeValue: String? = nil, altText: String? = nil) {
        self.id = id
        self.type = type
        self.value = value
        self.link = link
        self.enabled = enabled
        self.rawHTML = rawHTML
        self.doubleWidth = doubleWidth
        self.style = style
        self.darkModeValue = darkModeValue
        self.altText = altText
    }
}

struct WebColumn: Codable {
    var id: UUID
    var contents: [WebContent]

    init(id: UUID = UUID(), contents: [WebContent]) {
        self.id = id
        self.contents = contents
    }
}

struct WebRow: Codable {
    var id: UUID
    var columns: [WebColumn]
    var enabled: Bool

    init(id: UUID = UUID(), columns: [WebColumn], enabled: Bool = true) {
        self.id = id
        self.columns = columns
        self.enabled = enabled
    }
}

enum SectionType: Codable, CaseIterable {
    case standard
    case fullWidth
    case fullWidthAndHeight

    enum CodingKeys: String, CodingKey {
        case standard, fullWidth, fullWidthAndHeight
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .standard: try container.encode([String: String](), forKey: .standard)
        case .fullWidth: try container.encode([String: String](), forKey: .fullWidth)
        case .fullWidthAndHeight: try container.encode([String: String](), forKey: .fullWidthAndHeight)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.standard) { self = .standard }
        else if container.contains(.fullWidth) { self = .fullWidth }
        else if container.contains(.fullWidthAndHeight) { self = .fullWidthAndHeight }
        else { self = .standard }
    }
}

struct WebSection: Codable {
    var id: UUID
    var rows: [WebRow]
    var enabled: Bool
    var type: SectionType?

    init(id: UUID = UUID(), rows: [WebRow], enabled: Bool = true, type: SectionType? = .standard) {
        self.id = id
        self.rows = rows
        self.enabled = enabled
        self.type = type
    }
}

struct WebPageGlobal: Codable {
    var micro: WebPageMicro
    var sections: [WebSection]
}

// MARK: - API Client

struct WebPageAPI {
    let baseURL: String
    let masterKey: String

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func getPage(websiteID: UUID, pageID: UUID) async throws -> WebPageGlobal {
        let url = URL(string: "\(baseURL)/v2/mainframe/web/page/\(websiteID.uuidString)/\(pageID.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "WebPageAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "GET failed: \(body)"])
        }

        return try decoder.decode(WebPageGlobal.self, from: data)
    }

    func postPage(websiteID: UUID, page: WebPageGlobal) async throws -> WebPageGlobal {
        let url = URL(string: "\(baseURL)/v2/mainframe/web/page/\(websiteID.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")
        request.httpBody = try encoder.encode(page)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "WebPageAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "POST failed: \(body)"])
        }

        return try decoder.decode(WebPageGlobal.self, from: data)
    }

    func putPage(websiteID: UUID, pageID: UUID, page: WebPageGlobal) async throws -> WebPageGlobal {
        let url = URL(string: "\(baseURL)/v2/mainframe/web/page/\(websiteID.uuidString)/\(pageID.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")
        request.httpBody = try encoder.encode(page)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "WebPageAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "PUT failed: \(body)"])
        }

        return try decoder.decode(WebPageGlobal.self, from: data)
    }

    func deletePage(websiteID: UUID, pageID: UUID) async throws -> Bool {
        let url = URL(string: "\(baseURL)/v2/mainframe/web/page/\(websiteID.uuidString)/\(pageID.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return false
        }
        return true
    }
}

// MARK: - Builder Helpers

struct WebPageBuilder {
    static func createPage(
        title: String,
        slug: String,
        visibility: Visibility = .published,
        taxonomy: WebTaxonomy? = .article,
        featuredImageURL: String? = nil,
        metaDescription: String? = nil,
        keywords: String? = nil,
        sections: [WebSection]
    ) -> WebPageGlobal {
        WebPageGlobal(
            micro: WebPageMicro(
                id: nil,
                title: title,
                slug: slug,
                createdDate: Date(),
                updatedDate: Date(),
                visibility: visibility,
                taxonomy: taxonomy,
                isTaxonomyBase: false,
                featuredImageURL: featuredImageURL,
                metaDescription: metaDescription,
                keywords: keywords
            ),
            sections: sections
        )
    }

    static func textContent(_ html: String, style: String? = nil) -> WebContent {
        WebContent(type: .text, value: html, style: style)
    }

    static func imageContent(_ url: String, altText: String? = nil, link: String? = nil) -> WebContent {
        WebContent(type: .image, value: url, link: link, altText: altText)
    }

    static func buttonContent(_ text: String, link: String, style: String? = nil) -> WebContent {
        WebContent(type: .button, value: text, link: link, style: style)
    }

    static func section(contents: [WebContent], type: SectionType = .standard) -> WebSection {
        WebSection(rows: [WebRow(columns: [WebColumn(contents: contents)])], type: type)
    }
}

// MARK: - CLI Entry Point

func printUsage() {
    print("""
    WebPage API - JWS Skills

    Usage:
      swift webpage-api.swift get <website-id> <page-id>
      swift webpage-api.swift post <website-id> <json-file>
      swift webpage-api.swift put <website-id> <page-id> <json-file>
      swift webpage-api.swift delete <website-id> <page-id>

    Examples:
      swift webpage-api.swift get 1cf4f6af-a577-4875-bf1e-7bb23c1985b1 63625f1e-3fd4-478e-979a-c2ee85d11584
      swift webpage-api.swift post 1cf4f6af-a577-4875-bf1e-7bb23c1985b1 page.json
    """)
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    printUsage()
    exit(1)
}

let api = WebPageAPI(baseURL: apiBaseURL, masterKey: masterKey)
let command = args[1]

let runLoop = RunLoop.current
var finished = false

Task {
    do {
        switch command {
        case "get":
            guard args.count >= 4,
                  let websiteID = UUID(uuidString: args[2]),
                  let pageID = UUID(uuidString: args[3]) else {
                print("✗ Invalid arguments for get")
                printUsage()
                exit(1)
            }
            let page = try await api.getPage(websiteID: websiteID, pageID: pageID)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let json = try encoder.encode(page)
            print(String(data: json, encoding: .utf8)!)

        case "post":
            guard args.count >= 4,
                  let websiteID = UUID(uuidString: args[2]) else {
                print("✗ Invalid arguments for post")
                printUsage()
                exit(1)
            }
            let jsonFile = args[3]
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonFile))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let page = try decoder.decode(WebPageGlobal.self, from: jsonData)
            let result = try await api.postPage(websiteID: websiteID, page: page)
            print("✓ Created page: \(result.micro.slug)")
            if let id = result.micro.id {
                print("  ID: \(id.uuidString)")
            }

        case "put":
            guard args.count >= 5,
                  let websiteID = UUID(uuidString: args[2]),
                  let pageID = UUID(uuidString: args[3]) else {
                print("✗ Invalid arguments for put")
                printUsage()
                exit(1)
            }
            let jsonFile = args[4]
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonFile))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var page = try decoder.decode(WebPageGlobal.self, from: jsonData)
            page.micro.id = pageID
            let result = try await api.putPage(websiteID: websiteID, pageID: pageID, page: page)
            print("✓ Updated page: \(result.micro.slug)")

        case "delete":
            guard args.count >= 4,
                  let websiteID = UUID(uuidString: args[2]),
                  let pageID = UUID(uuidString: args[3]) else {
                print("✗ Invalid arguments for delete")
                printUsage()
                exit(1)
            }
            let success = try await api.deletePage(websiteID: websiteID, pageID: pageID)
            if success {
                print("✓ Deleted page")
            } else {
                print("✗ Failed to delete page")
            }

        default:
            print("✗ Unknown command: \(command)")
            printUsage()
            exit(1)
        }
        finished = true
    } catch {
        print("✗ Error: \(error.localizedDescription)")
        exit(1)
    }
}

while !finished {
    runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
}
