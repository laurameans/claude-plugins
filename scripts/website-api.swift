#!/usr/bin/env swift
//
//  website-api.swift
//  JWS Skills
//
//  Website API operations via api.voosey.com
//  Supports GET and PUT operations for Website model including stylesheets
//
//  Usage:
//    swift website-api.swift list                           # List all websites
//    swift website-api.swift get <website-id>               # Get single website
//    swift website-api.swift get-css <website-id>           # Get stylesheet content only
//    swift website-api.swift put-css <website-id> <css>     # Update stylesheet (inline)
//    swift website-api.swift put-css-file <website-id> <file>  # Update stylesheet from file
//    swift website-api.swift purge <website-id>             # Purge Cloudflare cache for all pages
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Configuration

// JWS server deployments
let servers: [String: String] = [
    "voosey": "https://api.voosey.com",       // voosey.com, dajh.com, sixpacmanco.com
    "means": "https://outtakes.com",          // means.ai, outtakes.com, flow.outtakes.com
    "mainframe": "https://api.mainframe.jws.ai"  // jws.ai
]
let masterKey = "2571123FD179EA45A21B5563D4B1D"

// Cloudflare API tokens (hardcoded to avoid env var hassle)
let cloudflareTokens: [String: String] = [
    "means": "LB3inFp9HIifTXrLlpAMz-36m3-FoTCXLaL0kmfB",  // outtakes.com, means.ai, jws.ai, etc.
    // "voosey": "YOUR_VOOSEY_TOKEN_HERE"  // voosey.com, dajh.com, etc.
]

// Mainframe API for writing (OAuth)
let mainframeAPI = "https://api.mainframe.jws.ai"
let mainframeToken = "3Jg8YUGkgRPR82VDplkGqw=="

// App IDs for Mainframe API
let appIDs: [String: String] = [
    "voosey": "7132f749-ea5a-4cc1-8d3f-091774e5b522",
    "means": "7132f749-ea5a-4cc1-8d3f-091774e5b524"  // outtakes app hosts means.ai etc
]

// Auto-detect server based on hostname
func serverForHost(_ host: String) -> String {
    let mainframeHosts = ["jws.ai"]
    let meansHosts = ["means.ai", "outtakes.com", "flow.outtakes.com", "dave.means.ai", "justinmeans1.com", "untoldculture.com"]
    if mainframeHosts.contains(where: { host.contains($0) }) {
        return servers["mainframe"]!
    }
    return meansHosts.contains(where: { host.contains($0) }) ? servers["means"]! : servers["voosey"]!
}

// Get Cloudflare token for host
func cloudflareTokenForHost(_ host: String) -> String? {
    let meansHosts = ["means.ai", "outtakes.com", "jws.ai", "flow.outtakes.com", "dave.means.ai", "justinmeans1.com", "untoldculture.com"]
    if meansHosts.contains(where: { host.contains($0) }) {
        return cloudflareTokens["means"]
    }
    return cloudflareTokens["voosey"]
}

func appIDForHost(_ host: String) -> String {
    let meansHosts = ["means.ai", "outtakes.com", "jws.ai", "flow.outtakes.com", "dave.means.ai", "justinmeans1.com", "untoldculture.com"]
    return meansHosts.contains(where: { host.contains($0) }) ? appIDs["means"]! : appIDs["voosey"]!
}

// MARK: - Types

struct WebMenu: Codable {
    var elements: [WebMenuElement]?
    var lightLogoImageURL: String?
    var darkLogoImageURL: String?
}

struct WebMenuElement: Codable {
    var id: UUID
    var title: String
    var link: String
}

struct Website: Codable {
    var id: UUID
    var host: String
    var title: String
    var slogan: String?
    var faviconURL: String?
    var headerMenu: WebMenu?
    var footerMenu: WebMenu?
    var stylesheetURL: String?
    var stylesheetContent: String?
    var cloudflareZoneIDs: [String: String]?
    var printfulStoreId: Int?
}

struct WebPageMicro: Codable {
    var id: UUID?
    var title: String
    var slug: String
}

// MARK: - API Client

struct WebsiteAPI {
    let masterKey: String

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    private var decoder: JSONDecoder {
        JSONDecoder()
    }

    func listWebsites(server: String? = nil) async throws -> [Website] {
        if let server = server {
            return try await fetchWebsites(from: server)
        }

        // Fetch from all servers
        var allWebsites: [Website] = []
        for (_, baseURL) in servers {
            do {
                let sites = try await fetchWebsites(from: baseURL)
                allWebsites.append(contentsOf: sites)
            } catch {
                // Continue if one server fails
            }
        }
        return allWebsites
    }

    private func fetchWebsites(from baseURL: String) async throws -> [Website] {
        let url = URL(string: "\(baseURL)/v2/mainframe/web/sites")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "WebsiteAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "GET failed: \(body)"])
        }

        return try decoder.decode([Website].self, from: data)
    }

    func getWebsite(id: UUID) async throws -> (Website, String) {
        // Try all servers to find the website
        for (_, baseURL) in servers {
            do {
                let websites = try await fetchWebsites(from: baseURL)
                if let website = websites.first(where: { $0.id == id }) {
                    return (website, baseURL)
                }
            } catch {
                // Continue to next server
            }
        }
        throw NSError(domain: "WebsiteAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Website not found: \(id)"])
    }

    func getWebsiteByHost(_ host: String) async throws -> (Website, String) {
        let baseURL = serverForHost(host)
        let websites = try await fetchWebsites(from: baseURL)
        if let website = websites.first(where: { $0.host == host }) {
            return (website, baseURL)
        }
        throw NSError(domain: "WebsiteAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Website not found: \(host)"])
    }

    func putWebsite(_ website: Website, baseURL: String) async throws -> Bool {
        // Use direct endpoint with master key
        let url = URL(string: "\(baseURL)/v2/mainframe/web/site/\(website.id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")
        request.httpBody = try encoder.encode(website)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "WebsiteAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if httpResponse.statusCode == 200 {
            return true
        } else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "WebsiteAPI", code: 4, userInfo: [NSLocalizedDescriptionKey: "PUT failed (\(httpResponse.statusCode)): \(body)"])
        }
    }

    func getPages(websiteID: UUID, baseURL: String) async throws -> [WebPageMicro] {
        let url = URL(string: "\(baseURL)/v2/mainframe/web/pages/\(websiteID.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(masterKey, forHTTPHeaderField: "jws_master_key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "WebsiteAPI", code: 5, userInfo: [NSLocalizedDescriptionKey: "GET pages failed: \(body)"])
        }

        return try decoder.decode([WebPageMicro].self, from: data)
    }

    func purgeCloudflareCache(website: Website, baseURL: String) async throws -> Int {
        // Get all pages for this website
        let pages = try await getPages(websiteID: website.id, baseURL: baseURL)

        // Build list of URLs to purge
        var urlsToPurge: [String] = []

        // Add root URL
        urlsToPurge.append("https://\(website.host)/")

        // Add all page URLs
        for page in pages {
            let slug = page.slug.isEmpty ? "" : "/\(page.slug)"
            urlsToPurge.append("https://\(website.host)\(slug)")
        }

        // Get Cloudflare zone ID
        guard let zoneIDs = website.cloudflareZoneIDs,
              let zoneID = zoneIDs[website.host] ?? zoneIDs.values.first else {
            print("⚠ No Cloudflare zone ID configured for \(website.host)")
            return 0
        }

        // Get API token (hardcoded or from environment)
        guard let apiToken = cloudflareTokenForHost(website.host) ?? ProcessInfo.processInfo.environment["CLOUDFLARE_API_TOKEN"] else {
            print("⚠ No Cloudflare token configured for \(website.host)")
            return 0
        }

        // Purge everything (more reliable than specific URLs)
        let purgeURL = URL(string: "https://api.cloudflare.com/client/v4/zones/\(zoneID)/purge_cache")!
        var request = URLRequest(url: purgeURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["purge_everything": true]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return urlsToPurge.count
        }

        return 0
    }
}

// MARK: - CLI

func printUsage() {
    print("""
    Website API - JWS Skills

    Usage:
      swift website-api.swift list                              List all websites (both servers)
      swift website-api.swift get <id-or-host>                  Get single website JSON
      swift website-api.swift get-css <id-or-host>              Get stylesheet content only
      swift website-api.swift put-css <id-or-host> "<css>"      Update stylesheet (inline)
      swift website-api.swift put-css-file <id-or-host> <file>  Update stylesheet from file
      swift website-api.swift purge <id-or-host>                Purge Cloudflare cache

    Servers:
      Voosey (api.voosey.com):  voosey.com, dajh.com, sixpacmanco.com, globalhousing.net
      Means (outtakes.com):     means.ai, outtakes.com, jws.ai, flow.outtakes.com

    Website IDs (Means Server):
      means.ai:           1CF4F6AF-A577-4875-BF1E-7BA14C1985B4
      outtakes.com:       1CF4F6AF-A577-4875-BF1E-7BA14C1985B5
      jws.ai:             1CF4F6AF-A577-4875-BF1E-7BA14C1985B7
      flow.outtakes.com:  1CF4F6AF-A577-4875-BF1E-7BA14C1985B6

    Website IDs (Voosey Server):
      voosey.com:         1CF4F6AF-A577-4875-BF1E-7BA14C1985B4
      dajh.com:           1CF4F6AF-A577-4875-BF1E-7BB14C1985B6
      sixpacmanco.com:    1CF4F6AF-A577-4875-BF1E-7BB23C1985B1

    Environment:
      CLOUDFLARE_API_TOKEN  Required for cache purge operations

    Examples:
      swift website-api.swift list
      swift website-api.swift get-css means.ai
      swift website-api.swift put-css means.ai ".custom { color: red; }"
      swift website-api.swift put-css-file outtakes.com styles.css

    Notes:
      - Cache purging happens automatically after CSS updates
      - Use /jws-style slash command for browser verification loop
    """)
}

// Helper to resolve ID or hostname to website
func resolveWebsite(_ idOrHost: String, api: WebsiteAPI) async throws -> (Website, String) {
    // Try as UUID first
    if let uuid = UUID(uuidString: idOrHost) {
        return try await api.getWebsite(id: uuid)
    }
    // Try as hostname
    return try await api.getWebsiteByHost(idOrHost)
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    printUsage()
    exit(1)
}

let api = WebsiteAPI(masterKey: masterKey)
let command = args[1]

let runLoop = RunLoop.current
var finished = false

Task {
    do {
        switch command {
        case "list":
            let websites = try await api.listWebsites()
            print("Found \(websites.count) websites:\n")

            // Group by server
            var meansWebsites: [Website] = []
            var vooseyWebsites: [Website] = []

            for site in websites {
                if serverForHost(site.host) == servers["means"] {
                    meansWebsites.append(site)
                } else {
                    vooseyWebsites.append(site)
                }
            }

            print("═══ MEANS SERVER (outtakes.com) ═══")
            for site in meansWebsites {
                let hasCSS = (site.stylesheetContent != nil && !site.stylesheetContent!.isEmpty) ? "✓" : "✗"
                print("  \(site.host)")
                print("    ID: \(site.id.uuidString)")
                print("    Title: \(site.title)")
                print("    Custom CSS: \(hasCSS)")
                if let css = site.stylesheetContent, !css.isEmpty {
                    print("    CSS Length: \(css.count) chars")
                }
                print("")
            }

            print("═══ VOOSEY SERVER (api.voosey.com) ═══")
            for site in vooseyWebsites {
                let hasCSS = (site.stylesheetContent != nil && !site.stylesheetContent!.isEmpty) ? "✓" : "✗"
                print("  \(site.host)")
                print("    ID: \(site.id.uuidString)")
                print("    Title: \(site.title)")
                print("    Custom CSS: \(hasCSS)")
                if let css = site.stylesheetContent, !css.isEmpty {
                    print("    CSS Length: \(css.count) chars")
                }
                print("")
            }

        case "get":
            guard args.count >= 3 else {
                print("✗ Usage: get <id-or-host>")
                exit(1)
            }
            let (website, _) = try await resolveWebsite(args[2], api: api)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let json = try encoder.encode(website)
            print(String(data: json, encoding: .utf8)!)

        case "get-css":
            guard args.count >= 3 else {
                print("✗ Usage: get-css <id-or-host>")
                exit(1)
            }
            let (website, _) = try await resolveWebsite(args[2], api: api)
            if let css = website.stylesheetContent, !css.isEmpty {
                print(css)
            } else {
                print("/* No custom stylesheet content for \(website.host) */")
            }

        case "put-css":
            guard args.count >= 4 else {
                print("✗ Usage: put-css <id-or-host> \"<css>\"")
                exit(1)
            }
            let css = args[3]
            var (website, baseURL) = try await resolveWebsite(args[2], api: api)
            website.stylesheetContent = css
            let success = try await api.putWebsite(website, baseURL: baseURL)
            if success {
                print("✓ Updated stylesheet for \(website.host)")
                print("  CSS length: \(css.count) chars")

                // Auto-purge cache
                let purged = try await api.purgeCloudflareCache(website: website, baseURL: baseURL)
                if purged > 0 {
                    print("✓ Purged \(purged) URLs from Cloudflare cache")
                }

            }

        case "put-css-file":
            guard args.count >= 4 else {
                print("✗ Usage: put-css-file <id-or-host> <file>")
                exit(1)
            }
            let filePath = args[3]
            let css = try String(contentsOfFile: filePath, encoding: .utf8)
            var (website, baseURL) = try await resolveWebsite(args[2], api: api)
            website.stylesheetContent = css
            let success = try await api.putWebsite(website, baseURL: baseURL)
            if success {
                print("✓ Updated stylesheet for \(website.host) from \(filePath)")
                print("  CSS length: \(css.count) chars")

                // Auto-purge cache
                let purged = try await api.purgeCloudflareCache(website: website, baseURL: baseURL)
                if purged > 0 {
                    print("✓ Purged \(purged) URLs from Cloudflare cache")
                }

            }

        case "purge":
            guard args.count >= 3 else {
                print("✗ Usage: purge <id-or-host>")
                exit(1)
            }
            let (website, baseURL) = try await resolveWebsite(args[2], api: api)
            print("Purging Cloudflare cache for \(website.host)...")
            let purged = try await api.purgeCloudflareCache(website: website, baseURL: baseURL)
            print("✓ Purged \(purged) URLs")

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
