//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-14.
//

import Foundation

@testable import Pipeline

enum DataLoadError: Swift.Error, Equatable {
    case failedToOpenFileForReading(NSError)
}

enum DataSaveError: Swift.Error {
    case writeError(NSError)
}

public protocol DataLoader {
    func loadData(fileName: String) throws -> Data
}
public protocol DataSaver {
    func save(data: Data, fileName: String) throws
}

public final class OnDiscDataManager: DataLoader & DataSaver {
    private let fileManager: FileManager
    private let folder: URL
    private init(
        fileManager: FileManager = .default,
        folder: URL
    ) {
        self.fileManager = fileManager
        self.folder = folder
        print("🗂 folder: '\(folder)")
    }
}

public extension OnDiscDataManager {
    static func temporary(fileManager: FileManager = .default) -> OnDiscDataManager {

        let searchPath: FileManager.SearchPathDirectory = .trashDirectory

        let folderURLs = fileManager.urls(
            for: searchPath,
            in: .userDomainMask
        )
        guard let writeableFolder = folderURLs.first else {
            incorrectImplementationShouldAlwaysBeAble(
                to: "Reference a writeable folder for \(searchPath)"
            )
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateTimeString = dateFormatter.string(from: Date())
        let temporaryFolder = writeableFolder.appendingPathComponent(dateTimeString, isDirectory: true)

        do {
            try fileManager.createDirectory(
                at: temporaryFolder,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch { unexpectedlyCaughtError(error) }

        return OnDiscDataManager(
            fileManager: fileManager,
            folder: temporaryFolder
        )
    }
}

public extension OnDiscDataManager {
    func loadData(fileName: String) throws -> Data {
        let fileURL = try baseURL(mode: .load, fileName: fileName)
        return try loadData(fileURL: fileURL)
    }

    func save(data: Data, fileName: String) throws {
        let fileURL = try baseURL(mode: .save, fileName: fileName)
        try save(data: data, fileURL: fileURL)
    }
}

public extension OnDiscDataManager {


    func loadData(fileURL: URL) throws -> Data {
        let file: FileHandle
        do {
            file = try FileHandle(forReadingFrom: fileURL)
        } catch let readNSError as NSError {
            throw DataLoadError.failedToOpenFileForReading(readNSError)
        } catch { unexpectedlyCaughtError(error) }

        let contentsOfFile: Data = file.readDataToEndOfFile()
        return contentsOfFile
    }

    func save(data: Data, fileURL: URL) throws {
        do {
            try data.write(to: fileURL)
        } catch let writeNSError as NSError {
            throw DataSaveError.writeError(writeNSError)
        } catch { unexpectedlyCaughtError(error) }
    }
}

public extension OnDiscDataManager {
    var numberOfSavedEntries: Int {
        do {
            let urlsToFiles = try fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil,
                options: .producesRelativePathURLs
            )

            return urlsToFiles.count
        } catch { unexpectedlyCaughtError(error) }
    }
}

// MARK: Private
private extension OnDiscDataManager {
    enum Mode {
        case save, load
    }

    func baseURL(mode: Mode, fileName: String) throws -> URL {
        //        let searchPath: FileManager.SearchPathDirectory = .demoApplicationDirectory
        //
        //        let folderURLs = fileManager.urls(
        //            for: searchPath,
        //            in: .userDomainMask
        //        )
        //        guard let writeableFolder = folderURLs.first else {
        //            incorrectImplementationShouldAlwaysBeAble(to: "Reference a writeable folder for \(searchPath)")
        //        }

        let fileURL = folder.appendingPathComponent(fileName)
        //        guard        fileManager.isWritableFile(atPath: fileURL.absoluteString)
        return fileURL
    }
}
