//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-14.
//

import Foundation

extension JSONEncoder {
    static var prettyPrinting: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }
}

public final class Cacher {
    private let dataLoader: DataLoader
    private let dataSaver: DataSaver
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let _numberOfSavedEntries: () -> Int
    init(
        dataLoader: DataLoader,
        dataSaver: DataSaver,
        jsonEncoder: JSONEncoder = .prettyPrinting,
        jsonDecoder: JSONDecoder = .init(),
        getNumberOfSavedEntries: @escaping () -> Int
    ) {
        self.dataLoader = dataLoader
        self.dataSaver = dataSaver
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
        self._numberOfSavedEntries = getNumberOfSavedEntries
    }
}

public extension Cacher {
    convenience init(onDisc: OnDiscDataManager) {
        self.init(
            dataLoader: onDisc,
            dataSaver: onDisc,
            getNumberOfSavedEntries: { onDisc.numberOfSavedEntries }
        )
    }
}

enum CacheLoadError: Swift.Error {
    case failedToLoad(DataLoadError)
    case failedToDecode(DecodingError)
}

enum CacheSaveError: Swift.Error {
    case failedToEncode(EncodingError)
    case failedToSave(DataSaveError)
}

// MARK: Save
public extension Cacher {
    func save<Model>(model: Model, fileName baseFileName: String) throws where Model: Codable {
        let fileName = baseFileName + typeName(of: Model.self)
        let data: Data
        do {
            data = try jsonEncoder.encode(model)
        } catch let encodingError as EncodingError {
            throw CacheSaveError.failedToEncode(encodingError)
        } catch { unexpectedlyCaughtError(error) }

        try save(data: data, fileName: fileName)
    }
}

// MARK: DataSaver
extension Cacher: DataSaver {}
public extension Cacher {
    func save(data: Data, fileName: String) throws {
        do {
            try dataSaver.save(data: data, fileName: fileName)
        } catch let dataSaveError as DataSaveError {
            throw CacheSaveError.failedToSave(dataSaveError)
        } catch { unexpectedlyCaughtError(error) }
    }
}

// MARK: Load
public extension Cacher {
    func load<Model>(modelType _: Model.Type, fileName baseFileName: String) throws -> Model where Model: Codable {
        let fileName = baseFileName + typeName(of: Model.self)
        let data = try loadData(fileName: fileName)
        do {
            return try jsonDecoder.decode(Model.self, from: data)
        } catch let decodingError as DecodingError {
            throw CacheLoadError.failedToDecode(decodingError)
        } catch { unexpectedlyCaughtError(error) }
    }

    func load<Model>(fileName: String) throws -> Model where Model: Codable {
        try load(modelType: Model.self, fileName: fileName)
    }
}

// MARK: DataLoader
extension Cacher: DataLoader {}
public extension Cacher {

    func loadData(fileName: String) throws -> Data {
        do {
            return try dataLoader.loadData(fileName: fileName)
        } catch let dataLoadError as DataLoadError {
            throw CacheLoadError.failedToLoad(dataLoadError)
        } catch { unexpectedlyCaughtError(error) }
    }

}

public extension Cacher {
    var numberOfSavedEntries: Int {
        _numberOfSavedEntries()
    }
}
