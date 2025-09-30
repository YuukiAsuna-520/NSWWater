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
            
            let regionText = dam.region ?? ""  // If dam.region is nil，replaced by ""
            let regionMatch = regionText.localizedCaseInsensitiveContains(searchText)
            
            return nameMatch || regionMatch     // Either nameMatch or regionMatch
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
            let dtos: [DamDTO] = try await GET("dams") // => GET https://api.onegov.nsw.gov.au/waternsw-waterinsights/v1/dams
            let items = dtos.compactMap { $0.toModel() }
            if !items.isEmpty { self.dams = items }
        } catch {
            print("Fetch dams failed:", (error as? LocalizedError)?.errorDescription ?? "\(error)")
        }
    }
}

// MARK: - DTO

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

// Dam DTO with tolerant keys.
private struct DamDTO: Decodable {
    let id: String?, name: String?, latitude: Double?, longitude: Double?, region: String?
    enum CodingKeys: String, CodingKey { case id, name, latitude, longitude, region, dam_id, dam_name, lat, lon }
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        id        = try c.decodeIfPresent(String.self,  forKeys: [.id, .dam_id])
        name      = try c.decodeIfPresent(String.self,  forKeys: [.name, .dam_name])
        latitude  = try c.decodeIfPresent(Double.self,  forKeys: [.latitude, .lat])
        longitude = try c.decodeIfPresent(Double.self,  forKeys: [.longitude, .lon])
        region    = try c.decodeIfPresent(String.self,  forKeys: [.region])
    }
}
private extension KeyedDecodingContainer {
    func decodeIfPresent(_ t: String.Type, forKeys ks: [K]) throws -> String? {
        for k in ks { if let v = try decodeIfPresent(t, forKey: k) { return v } }
        return nil
    }
    func decodeIfPresent(_ t: Double.Type, forKeys ks: [K]) throws -> Double? {
        for k in ks {
            if let v = try decodeIfPresent(Double.self, forKey: k) { return v }
            if let s = try decodeIfPresent(String.self, forKey: k), let v = Double(s) { return v }
        }
        return nil
    }
}
private extension DamDTO {
    func toModel() -> Dam? {
        guard let id, let name, let latitude, let longitude else { return nil }
        return Dam(id: id, name: name, latitude: latitude, longitude: longitude, region: region, storagePercent: nil)
    }
}
