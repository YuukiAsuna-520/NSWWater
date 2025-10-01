//
//  DamListViewModel.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import Foundation
import Combine
import Collections

final class DamListViewModel: ObservableObject {

    // MARK: - Search
    @Published var dams: [Dam] = StubLoader.loadDams()
    @Published var searchText: String = ""
    @Published var latestByDam = OrderedDictionary<String, DamResource>()

    var filtered: [Dam] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return dams }
        return dams.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.id.localizedCaseInsensitiveContains(q) }
    }

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var lastError: String?

    private func setLoading(_ v: Bool) { DispatchQueue.main.async { self.isLoading = v } }
    private func setError(_ s: String?) { DispatchQueue.main.async { self.lastError = s } }

    // MARK: - API
    private let API_ROOT = "https://api.onegov.nsw.gov.au/waternsw-waterinsights/v1"
    private let OAUTH_TOKEN_URL = "https://api.onegov.nsw.gov.au/oauth/client_credential/accesstoken?grant_type=client_credentials"

    // OAuth (Basic base64(api_key:api_secret))
    private let AUTH_BASIC = ""

    // Subscription key
    private let API_KEY = ""
    private let API_KEY_HEADERS = ["apikey", "Ocp-Apim-Subscription-Key"]

    private var oauthToken: String?

    private var hasBearerCreds: Bool { !AUTH_BASIC.isEmpty }
    private var hasApiKeyCreds: Bool { !API_KEY.isEmpty }
    private var hasAnyAuth: Bool { hasBearerCreds || hasApiKeyCreds }
    private var shouldUseNetwork: Bool { hasAnyAuth || BuildFlags.useNetwork }

    // JSON decoder
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Throttle / cache
    private let latestTTL: TimeInterval = 5
    private let latestCacheCap = 40
    private var latestFetchedAt: [String: Date] = [:]
    private var latestInFlight = Set<String>()
    private var globalCooldownUntil: Date?

    private func now() -> Date { Date() }

    // MARK: - URL
    private func makeURL(_ path: String, query: [URLQueryItem]? = nil) throws -> URL {
        var comps = URLComponents(string: API_ROOT + "/" + path)!
        comps.queryItems = query
        guard let url = comps.url else { throw NetError.badURL }
        return url
    }

    // MARK: - OAuth
    private func ensureOAuthToken() async throws {
        guard hasBearerCreds, (oauthToken ?? "").isEmpty else { return }

        var req = URLRequest(url: URL(string: OAUTH_TOKEN_URL)!)
        req.httpMethod = "GET"
        req.setValue(AUTH_BASIC, forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw NetError.transport(NSError(domain: "HTTP", code: -1)) }
        guard (200...299).contains(http.statusCode) else {
            throw NetError.http(http.statusCode, String(data: data, encoding: .utf8))
        }

        let token = try decoder.decode(AccessTokenResponse.self, from: data).access_token
        self.oauthToken = token
        print("🔑 TOKEN OK, length=\(token.count)")
    }

    // MARK: - GET (Raw Data)
    private func isCancelledError(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled
    }

    private func GETRaw(
        _ path: String,
        query: [URLQueryItem]? = nil,
        requiresApiKey: Bool = false
    ) async throws -> Data {
        if let until = globalCooldownUntil, now() < until {
            let remain = until.timeIntervalSinceNow
            let ns = UInt64(max(0, remain) * 1_000_000_000)
            print("⏳ global cooldown \(String(format: "%.1fs", remain))…")
            try await Task.sleep(nanoseconds: ns)
        }

        if hasBearerCreds { try await ensureOAuthToken() }

        var req = URLRequest(url: try makeURL(path, query: query))
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = oauthToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if requiresApiKey, hasApiKeyCreds {
            for h in API_KEY_HEADERS { req.setValue(API_KEY, forHTTPHeaderField: h) }
        }

        print("🌐 GET \(req.url!.absoluteString)  apikey=\(requiresApiKey ? "ON" : "OFF")")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw NetError.transport(NSError(domain: "HTTP", code: -1)) }

        // 408（Traffic limit exceeded）、429（Too Many Requests)
        if http.statusCode == 408 || http.statusCode == 429 {
            globalCooldownUntil = Date().addingTimeInterval(5) // 5 sec cooldown
            print("🚦 rate-limited: \(http.statusCode). cooldown 5s")
        }

        guard (200...299).contains(http.statusCode) else {
            print("🌐 GET FAIL status=\(http.statusCode)\n\(String(data: data, encoding: .utf8) ?? "")")
            throw NetError.http(http.statusCode, String(data: data, encoding: .utf8))
        }
        return data
    }

    private func GET<T: Decodable>(
        _ path: String,
        query: [URLQueryItem]? = nil,
        requiresApiKey: Bool = false
    ) async throws -> T {
        let data = try await GETRaw(path, query: query, requiresApiKey: requiresApiKey)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetError.decoding(error)
        }
    }

    // MARK: - Public (list)
    @MainActor
    func loadFromNetworkReplacingStub() async {
        print("⚙️ loadFromNetworkReplacingStub() called, useNetwork=\(BuildFlags.useNetwork), hasAnyAuth=\(hasAnyAuth)")
        guard shouldUseNetwork else {
            print("➡️ keep stub dams (\(dams.count))")
            return
        }

        setError(nil)
        setLoading(true)
        defer { setLoading(false) }

        do {
            let envelope: DamsEnvelope = try await GET("dams", requiresApiKey: true)
            if !envelope.dams.isEmpty {
                self.dams = envelope.dams
                print("✅ loaded \(envelope.dams.count) dams from API")
            } else {
                setError("No dams returned by API.")
            }
        } catch let e as NetError {
            setError(e.errorDescription ?? "Request failed.")
        } catch {
            setError(error.localizedDescription)
        }
    }

    @MainActor
    func refresh() async { await loadFromNetworkReplacingStub() }

    private var hasLoadedOnce = false
    @MainActor
    func ensureLoadedOnce() async {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true
        await loadFromNetworkReplacingStub()
    }

    // MARK: - Latest (detail)
    @MainActor
    func loadLatest(for dam: Dam) async {
        guard shouldUseNetwork else { return }

        // per-dam TTL throttle
        if let t = latestFetchedAt[dam.id], now().timeIntervalSince(t) < latestTTL {
            return
        }
        // de-dup in-flight
        if latestInFlight.contains(dam.id) { return }
        latestInFlight.insert(dam.id)
        defer { latestInFlight.remove(dam.id) }

        do {
            try Task.checkCancellation()

            if let latest = try await fetchLatestResource(damID: dam.id) {
                latestByDam[dam.id] = latest

                // Keep insertion order and trim to most recent 40 entries.
                // Using OrderedDictionary: remove the oldest by first key.
                if latestByDam.count > 40, let firstKey = latestByDam.keys.first {
                    latestByDam.removeValue(forKey: firstKey)
                }

                latestFetchedAt[dam.id] = now()
            }
        } catch {
            // Ignore benign cancellations (view disappeared, task replaced, etc.)
            if isCancelledError(error) || Task.isCancelled { return }
            print("loadLatest failed for \(dam.id): \(error)")
        }
    }

    private func fetchLatestResource(damID: String) async throws -> DamResource? {
        do {
            let data = try await GETRaw("dams/\(damID)/resources/latest", requiresApiKey: true)
            if data.isEmpty { return nil }

            if let r = tryParseLatest(from: data) {
                return r
            }

            // Unknown shape: log once and return nil (no UI error)
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("❌ Unexpected JSON for /resources/latest dam=\(damID): \(body)")
            return nil
        } catch {
            // If the underlying URLSession task was cancelled, treat as non-error.
            if isCancelledError(error) { return nil }
            throw error
        }
    }
    
    // Recursively search any JSON shape and return the first valid DamResource-ish object.
    private func firstResourceInJSON(_ any: Any) -> DamResource? {
        if let dict = any as? [String: Any] {
            // If this dictionary itself looks like a resource, use it.
            if let r = damResourceFromLooseDict(dict) { return r }
            // Otherwise, dive into each value (handles "dams" -> item -> "resources" -> [ {...} ])
            for (_, v) in dict {
                if let nested = firstResourceInJSON(v) { return nested }
            }
        } else if let arr = any as? [Any] {
            // Explore arrays (order matters: first usable object wins)
            for e in arr {
                if let nested = firstResourceInJSON(e) { return nested }
            }
        }
        return nil
    }

    // It keeps your fast-path decodes, then falls back to deep recursive search.
    private func tryParseLatest(from data: Data) -> DamResource? {
        // 1) Try direct DamResource
        if let one = try? decoder.decode(DamResource.self, from: data),
           (one.percentFull != nil || one.volume != nil || one.inflow != nil || one.release != nil) {
            return one
        }

        // 2) Try { "resources": [ ... ] }
        struct ResourcesEnvelope: Decodable { let resources: [DamResource] }
        if let env = try? decoder.decode(ResourcesEnvelope.self, from: data) {
            if let lastGood = env.resources.reversed().first(where: {
                $0.percentFull != nil || $0.volume != nil || $0.inflow != nil || $0.release != nil
            }) {
                return lastGood
            }
        }

        // 3) Try { "resource": {...} } / { "data": {...} }
        struct SingleResourceEnvelope: Decodable { let resource: DamResource?; let data: DamResource? }
        if let env = try? decoder.decode(SingleResourceEnvelope.self, from: data) {
            if let r = env.resource ?? env.data,
               (r.percentFull != nil || r.volume != nil || r.inflow != nil || r.release != nil) {
                return r
            }
        }

        // 4) Fallback: deep recursive scan (handles "dams" -> item -> "resources" -> [ {...} ] and more)
        if let any = try? JSONSerialization.jsonObject(with: data) {
            if let r = firstResourceInJSON(any) { return r }
        }

        return nil
    }

    private func damResourceFromLooseDict(_ d: [String: Any]) -> DamResource? {
        func num(_ keys: [String]) -> Double? {
            for k in keys {
                if let v = d[k] as? Double { return v }
                if let v = d[k] as? NSNumber { return v.doubleValue }
                if let s = d[k] as? String, let v = Double(s) { return v }
            }
            return nil
        }

        let percent = num([
            "percent_full", "percentage_full",
            "accessible_storage_percentage", "accessible_storage_percent"
        ])
        let volume  = num([
            "volume", "storage_volume",
            "accessible_storage", "accessible_volume", "current_storage"
        ])
        let inflow  = num([
            "inflow", "storage_inflow", "inflow_volume"
        ])
        let release = num([
            "release", "storage_release", "release_volume", "outflow"
        ])

        if percent != nil || volume != nil || inflow != nil || release != nil {
            return DamResource(percentFull: percent, volume: volume, inflow: inflow, release: release)
        }
        return nil
    }

    // MARK: - DTOs / Errors
    private struct AccessTokenResponse: Decodable { let access_token: String }

    private enum NetError: LocalizedError {
        case badURL, transport(Error), http(Int, String?), decoding(Error)
        var errorDescription: String? {
            switch self {
            case .badURL: return "Invalid URL"
            case .transport(let e): return e.localizedDescription
            case .http(let c, let b): return "HTTP \(c) \(b ?? "")"
            case .decoding(let e): return "Decoding error: \(e.localizedDescription)"
            }
        }
    }

    private struct DamsEnvelope: Decodable { let dams: [Dam] }
    private struct ResourcesEnvelope: Decodable { let resources: [DamResource] }
}
