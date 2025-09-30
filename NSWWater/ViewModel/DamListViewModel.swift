//
//  DamListViewModel.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import Foundation
import Combine

final class DamListViewModel: ObservableObject {

    // MARK: - Search

    @Published var dams: [Dam] = StubLoader.loadDams()
    @Published var searchText: String = ""
    // Cache latest resource per dam id.
    @Published var latestByDam: [String: DamResource] = [:]


    var filtered: [Dam] {
        // Search by name or id only
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return dams }
        return dams.filter { dam in
            dam.name.localizedCaseInsensitiveContains(q)
            || dam.id.localizedCaseInsensitiveContains(q)
        }
    }

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var lastError: String?

    private func setLoading(_ v: Bool) { DispatchQueue.main.async { self.isLoading = v } }
    private func setError(_ s: String?) { DispatchQueue.main.async { self.lastError = s } }

    // MARK: - API

    private let API_ROOT = "https://api.onegov.nsw.gov.au/waternsw-waterinsights/v1"
    private let OAUTH_TOKEN_URL = "https://api.onegov.nsw.gov.au/oauth/client_credential/accesstoken?grant_type=client_credentials"

    private let AUTH_BASIC: String = ""
    private let API_KEY_HEADER = "apikey"
    private let API_KEY = ""

    private var oauthToken: String?

    private func makeURL(_ path: String, query: [URLQueryItem]? = nil) throws -> URL {
        var comps = URLComponents(string: API_ROOT + "/" + path)!
        comps.queryItems = query
        guard let url = comps.url else { throw NetError.badURL }
        return url
    }

    private func ensureOAuthToken() async throws {
        guard !AUTH_BASIC.isEmpty, (oauthToken ?? "").isEmpty else { return }
        var req = URLRequest(url: URL(string: OAUTH_TOKEN_URL)!)
        req.httpMethod = "GET"
        req.setValue(AUTH_BASIC, forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NetError.transport(NSError(domain: "HTTP", code: -1))
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetError.http(http.statusCode, String(data: data, encoding: .utf8))
        }
        let token = try JSONDecoder().decode(AccessTokenResponse.self, from: data).access_token
        self.oauthToken = token
    }

    private func GET<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        if !AUTH_BASIC.isEmpty { try await ensureOAuthToken() }

        var req = URLRequest(url: try makeURL(path, query: query))
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if !API_KEY.isEmpty {
            req.setValue(API_KEY, forHTTPHeaderField: API_KEY_HEADER)
        }
        if let token = oauthToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NetError.transport(NSError(domain: "HTTP", code: -1))
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetError.http(http.statusCode, String(data: data, encoding: .utf8))
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Public

    @MainActor
    func loadFromNetworkReplacingStub() async {
        
        guard BuildFlags.useNetwork else {
                print("BuildFlags.useNetwork=false → keep stub dams (\(dams.count))")
                return
            }
        
        let hasAnyAuth = (!AUTH_BASIC.isEmpty) || (!API_KEY.isEmpty)
        guard hasAnyAuth else {
            print("API auth not configured; keep stub dams.")
            return
        }

        setError(nil)
        setLoading(true)
        defer { setLoading(false) }

        do {
            let envelope: DamsEnvelope = try await GET("dams")
            if !envelope.dams.isEmpty {
                self.dams = envelope.dams
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
    
    @MainActor
    func loadLatest(for dam: Dam) async {
        // Respect BuildFlags: if using stub, skip network.
        guard BuildFlags.useNetwork else { return }

        let hasAnyAuth = (!AUTH_BASIC.isEmpty) || (!API_KEY.isEmpty)
        guard hasAnyAuth else { return }

        do {
            // GET /dams/{id}/resources/latest
            let path = "dams/\(dam.id)/resources/latest"
            let res: DamResource = try await GET(path)
            latestByDam[dam.id] = res
        } catch {
            print("loadLatest failed for \(dam.id): \(error)")
        }
    }

}

// MARK: - Networking and "DTO"

private struct AccessTokenResponse: Decodable {
    let access_token: String
}

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

private struct DamsEnvelope: Decodable {
    let dams: [Dam]
}
