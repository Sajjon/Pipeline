//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-14.
//

import Foundation

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
    private let directory: URL
    private init(
        fileManager: FileManager = .default,
        directory: URL
    ) {
        self.fileManager = fileManager
        self.directory = directory
    }
}


public extension OnDiscDataManager {
    static func temporary(fileManager: FileManager = .default) -> OnDiscDataManager {
        let programFolder = OnDiscDataManager.rootTempDir(fileManager: fileManager)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateTimeString = dateFormatter.string(from: Date())
        let temporaryDirectory = programFolder.appendingPathComponent(dateTimeString, isDirectory: true)

        return createTemporaryDirectory(at: temporaryDirectory, fileManager: fileManager)
    }
}

public extension OnDiscDataManager {
    func loadData(fileName: String) throws -> Data {
        let fileURL = try baseURL(fileName: fileName)
        return try loadData(fileURL: fileURL)
    }

    func save(data: Data, fileName: String) throws {
        let fileURL = try baseURL(fileName: fileName)
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

extension FileManager {
    func createDirectory(at url: URL) {
        do {
            try createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            incorrectImplementationShouldAlwaysBeAble(to: "Delete file at path: \(url)", error: error)
        }
    }

    func removeDirectory(at url: URL) {
        do {
            try removeItem(at: url)
        } catch {
            incorrectImplementationShouldAlwaysBeAble(to: "Delete file at path: \(url)", error: error)
        }
    }
}

// MARK: Private
private extension OnDiscDataManager {

    func baseURL(fileName: String) throws -> URL {
        let fileURL = directory.appendingPathComponent(fileName)
        return fileURL
    }

    static func createTemporaryDirectory(
        at urlToNewDirectory: URL,
        fileManager: FileManager = .default
    ) -> OnDiscDataManager {

        fileManager.createDirectory(at: urlToNewDirectory)

        return OnDiscDataManager(
            fileManager: fileManager,
            directory: urlToNewDirectory
        )
    }

    static let rootTempDirName = "_SafeToDelete_SPM_Project_Pipeline_Tests"
    static func rootTempDir(fileManager: FileManager = .default) -> URL {
        let searchPath: FileManager.SearchPathDirectory = .cachesDirectory

        let directoryURLs = fileManager.urls(
            for: searchPath,
            in: .userDomainMask
        )
        guard let writeableDirectory = directoryURLs.first else {
            incorrectImplementationShouldAlwaysBeAble(
                to: "Reference a writeable directory for \(searchPath)"
            )
        }

        let programFolder = writeableDirectory.appendingPathComponent(OnDiscDataManager.rootTempDirName, isDirectory: true)
        return programFolder
    }

    var rootTempDir: URL {
        OnDiscDataManager.rootTempDir(fileManager: fileManager)
    }
}

extension OnDiscDataManager {

    var numberOfSavedEntries: Int {
        do {
            let urlsToFiles = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: .producesRelativePathURLs
            )

            return urlsToFiles.count
        } catch { unexpectedlyCaughtError(error) }
    }

    func removeTemporaryDirectory() {
        fileManager.removeDirectory(at: directory)
    }

    static func removeTemporaryRootDirectoryIfNeeded() {
        let fileManager = FileManager.default
        let dirToRemove = OnDiscDataManager.rootTempDir(fileManager: fileManager)
        fileManager.removeDirectory(at: dirToRemove)
    }

    func recreateTemporaryDirectoryIfNeeded() {
        fileManager.createDirectory(at: directory)
    }
}

