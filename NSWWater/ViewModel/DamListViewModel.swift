//
//  DamListViewModel.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import Foundation
import Combine

final class DamListViewModel: ObservableObject {

    @Published var dams: [Dam] = StubLoader.loadDams()
    // Source data for the list, loaded from a local JSON stub for now.

    @Published var searchText: String = ""
    // Two-way binding for the search bar.

    var filtered: [Dam] {
        // Filtered list that returns the list after applying the search filter.
        
        // Return all dams if searchText is empty.
        guard !searchText.isEmpty else { return dams }
        
        // Else
        return dams.filter { dam in
            let nameMatch = dam.name.localizedCaseInsensitiveContains(searchText)
            return nameMatch
        }
    }
    
    // MARK: - API
    
    private let API_ROOT = "https://api.onegov.nsw.gov.au/waternsw-waterinsights/v1"

    // OAuth token endpoint (GET)
    private let OAUTH_TOKEN_URL = "https://api.onegov.nsw.gov.au/oauth/client_credential/accesstoken?grant_type=client_credentials"
    
    private let AUTH_BASIC: String = ""

    // Cached OAuth token
    private var oauthToken: String?

    // Build URL: API_ROOT + "/" + path + query
    private func makeURL(_ path: String, query: [URLQueryItem]? = nil) throws -> URL {
        var comps = URLComponents(string: API_ROOT + "/" + path)!
        comps.queryItems = query
        guard let url = comps.url else { throw NetError.badURL }
        return url
    }
    
    // Ensure having OAuth token when AUTH_BASIC is configured.
    private func ensureOAuthToken() async throws {
        guard !AUTH_BASIC.isEmpty, (oauthToken ?? "").isEmpty else { return }
        var req = URLRequest(url: URL(string: OAUTH_TOKEN_URL)!)
        req.httpMethod = "GET"
        req.setValue(AUTH_BASIC, forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetError.http((resp as? HTTPURLResponse)?.statusCode ?? -1, String(data: data, encoding: .utf8))
        }
        let token = try JSONDecoder().decode(AccessTokenResponse.self, from: data).access_token
        self.oauthToken = token
    }

    // GET — ensure Bearer token, set header, decode JSON
    private func GET<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        if !AUTH_BASIC.isEmpty { try await ensureOAuthToken() }

        var req = URLRequest(url: try makeURL(path, query: query))
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = oauthToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetError.http((resp as? HTTPURLResponse)?.statusCode ?? -1, String(data: data, encoding: .utf8))
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // Public entry for next step (do nothing if auth not configured).
    @MainActor
    func loadFromNetworkReplacingStub() async {
        guard !AUTH_BASIC.isEmpty else {
            print("API auth not configured; keep stub dams.")
            return
        }
        do {
            let envelope: DamsEnvelope = try await GET("dams")
            let items = envelope.dams
            if !items.isEmpty { self.dams = items }
        } catch {
            print("Fetch dams failed:", (error as? LocalizedError)?.errorDescription ?? "\(error)")
        }
    }
}

// MARK: - Networking and "DTO"

// Token response for OAuth step.
private struct AccessTokenResponse: Decodable {
    let access_token: String
}

// Light error type.
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
