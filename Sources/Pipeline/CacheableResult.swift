//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-31.
//

import Foundation

public protocol CacheableResult {
    static func loadCached(from cacher: Cacher, fileName: String) -> Any?
    func cache(in cacher: Cacher, fileName: String) throws
}

// MARK: Codable + Default
extension Encodable where Self: CacheableResult {

    func cache(in cacher: Cacher, fileName: String) throws {
        try cacher.save(model: self, fileName: fileName)
    }
}

extension Decodable where Self: CacheableResult {
    static func loadCached(from cacher: Cacher, fileName: String) -> Any? {
        try? cacher.load(modelType: self, fileName: fileName)
    }
}

// MARK: Global Convenience func

func load<Model>(from cacher: Cacher, fileName: String) -> Model? {
    doLoad(from: cacher, modelType: Model.self, fileName: fileName)
}

func doLoad<Model>(from cacher: Cacher, modelType _: Model.Type, fileName: String) -> Model? {
    guard let cachableType = Model.self as? CacheableResult.Type else { print("☣️ not CacheableResult"); return nil }
    
    //    let maybeCached = try? cacher.load(modelType: Model.self, fileName: fileName)
    let maybeCached = cachableType.loadCached(from: cacher, fileName: fileName)
    guard let foundCached = maybeCached else {
        print("❌ Found no cached data.")
        return nil
    }
    print("💾 found cached data: '\(foundCached)'")
    return castOrKill(foundCached, to: Model.self)
}

func cache<Model>(_ model: Model, in cacher: Cacher, fileName: String) throws {
    //    try cacher.save(model: model, fileName: fileName)
    guard let cachable = model as? CacheableResult else { print("☣️ not CacheableResult"); return }
    try cachable.cache(in: cacher, fileName: fileName)
}

