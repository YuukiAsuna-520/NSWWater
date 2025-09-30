//
//  FavoritesStore.swift
//  NSWWater
//
//  Created by 黑白熊 on 1/10/2025.
//

import Foundation
import Combine
import OrderedCollections

final class FavoritesStore: ObservableObject {
    @Published private(set) var ids = OrderedSet<String>()
    private let key = "favorite_dam_ids"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([String].self, from: data) {
            ids = OrderedSet(saved)
        }
    }

    private func save() {
        let arr = Array(ids)
        if let data = try? JSONEncoder().encode(arr) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func toggle(_ id: String) {
        if let i = ids.firstIndex(of: id) {
            ids.remove(at: i)
        } else {
            ids.append(id)
        }
        save()
    }

    func isFav(_ id: String) -> Bool { ids.contains(id) }

    /// Map ordered ids -> actual Dam objects (skip missing)
    func all(in dams: [Dam]) -> [Dam] {
        let index = Dictionary(uniqueKeysWithValues: dams.map { ($0.id, $0) })
        return ids.compactMap { index[$0] }
    }

    func clear() {
        ids.removeAll()
        save()
    }
}
