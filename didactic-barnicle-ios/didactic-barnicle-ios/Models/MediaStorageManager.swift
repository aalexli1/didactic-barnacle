import Foundation
import UIKit
import Photos
import ARKit

class MediaStorageManager {
    static let shared = MediaStorageManager()
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 500 * 1024 * 1024
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        createDirectoriesIfNeeded()
        startCacheCleanupTimer()
    }
    
    private func createDirectoriesIfNeeded() {
        let directories = [
            documentsDirectory.appendingPathComponent("treasures"),
            documentsDirectory.appendingPathComponent("discoveries"),
            documentsDirectory.appendingPathComponent("ar_assets"),
            cacheDirectory.appendingPathComponent("thumbnails"),
            cacheDirectory.appendingPathComponent("temp_uploads")
        ]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }
    
    private func startCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task {
                await self.cleanupCache()
            }
        }
    }
    
    func saveImage(_ image: UIImage, for treasureId: UUID, type: MediaType) async -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let directory = type == .treasure ? "treasures" : "discoveries"
        let fileName = "\(treasureId.uuidString)_\(Date().timeIntervalSince1970).jpg"
        let fileURL = documentsDirectory
            .appendingPathComponent(directory)
            .appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            
            await createThumbnail(from: image, for: treasureId)
            
            return fileURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func saveVideo(from url: URL, for treasureId: UUID) async -> URL? {
        let fileName = "\(treasureId.uuidString)_\(Date().timeIntervalSince1970).mp4"
        let destination = documentsDirectory
            .appendingPathComponent("treasures")
            .appendingPathComponent(fileName)
        
        do {
            try fileManager.copyItem(at: url, to: destination)
            return destination
        } catch {
            print("Error saving video: \(error)")
            return nil
        }
    }
    
    func saveARAsset(_ data: Data, name: String) async -> URL? {
        let fileURL = documentsDirectory
            .appendingPathComponent("ar_assets")
            .appendingPathComponent(name)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving AR asset: \(error)")
            return nil
        }
    }
    
    func loadImage(from url: URL) async -> UIImage? {
        if let cachedImage = loadFromCache(url: url) {
            return cachedImage
        }
        
        do {
            let data = try Data(contentsOf: url)
            let image = UIImage(data: data)
            
            if let image = image {
                await saveToCache(image: image, for: url)
            }
            
            return image
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
    
    func deleteMedia(at url: URL) async {
        do {
            try fileManager.removeItem(at: url)
            
            let thumbnailURL = getThumbnailURL(for: url)
            if fileManager.fileExists(atPath: thumbnailURL.path) {
                try fileManager.removeItem(at: thumbnailURL)
            }
        } catch {
            print("Error deleting media: \(error)")
        }
    }
    
    private func createThumbnail(from image: UIImage, for id: UUID) async {
        let size = CGSize(width: 150, height: 150)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let thumbnail = thumbnail,
           let data = thumbnail.jpegData(compressionQuality: 0.6) {
            let url = cacheDirectory
                .appendingPathComponent("thumbnails")
                .appendingPathComponent("\(id.uuidString)_thumb.jpg")
            try? data.write(to: url)
        }
    }
    
    private func getThumbnailURL(for originalURL: URL) -> URL {
        let filename = originalURL.lastPathComponent
        let thumbName = filename.replacingOccurrences(of: ".", with: "_thumb.")
        return cacheDirectory
            .appendingPathComponent("thumbnails")
            .appendingPathComponent(thumbName)
    }
    
    private func loadFromCache(url: URL) -> UIImage? {
        let cacheKey = url.lastPathComponent
        let cacheURL = cacheDirectory.appendingPathComponent(cacheKey)
        
        if fileManager.fileExists(atPath: cacheURL.path),
           let data = try? Data(contentsOf: cacheURL) {
            return UIImage(data: data)
        }
        return nil
    }
    
    private func saveToCache(image: UIImage, for url: URL) async {
        let cacheKey = url.lastPathComponent
        let cacheURL = cacheDirectory.appendingPathComponent(cacheKey)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: cacheURL)
        }
    }
    
    private func cleanupCache() async {
        let cutoffDate = Date().addingTimeInterval(-maxCacheAge)
        
        do {
            let cacheContents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
            )
            
            var totalSize: Int64 = 0
            var filesToDelete: [URL] = []
            
            for fileURL in cacheContents {
                let attributes = try fileURL.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                
                if let creationDate = attributes.creationDate,
                   creationDate < cutoffDate {
                    filesToDelete.append(fileURL)
                } else if let fileSize = attributes.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
            
            if totalSize > maxCacheSize {
                let sortedFiles = cacheContents.sorted { url1, url2 in
                    let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date()
                    let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date()
                    return date1! < date2!
                }
                
                for fileURL in sortedFiles {
                    if totalSize <= maxCacheSize { break }
                    
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize -= Int64(fileSize)
                        filesToDelete.append(fileURL)
                    }
                }
            }
            
            for fileURL in filesToDelete {
                try? fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error cleaning up cache: \(error)")
        }
    }
    
    func calculateStorageUsage() async -> (documents: Int64, cache: Int64) {
        var documentsSize: Int64 = 0
        var cacheSize: Int64 = 0
        
        func calculateDirectorySize(at url: URL) -> Int64 {
            var size: Int64 = 0
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        size += Int64(fileSize)
                    }
                }
            }
            return size
        }
        
        documentsSize = calculateDirectorySize(at: documentsDirectory)
        cacheSize = calculateDirectorySize(at: cacheDirectory)
        
        return (documentsSize, cacheSize)
    }
    
    func clearAllCache() async {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
            createDirectoriesIfNeeded()
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
}

enum MediaType {
    case treasure
    case discovery
    case profile
}