import UIKit
import Foundation

class PhotoManager {
    static let shared = PhotoManager()
    private let fileManager = FileManager.default
    private let photosDirectoryName = "ClutterBugPhotos"
    private let thumbnailsDirectoryName = "ClutterBugThumbnails"
    
    // ✅ FIXED: Cache for loaded images to improve performance - made internal for PhotoMigrationUtility
    internal var imageCache: [String: UIImage] = [:]
    internal var thumbnailCache: [String: UIImage] = [:]
    internal let cacheQueue = DispatchQueue(label: "photo.cache.queue", attributes: .concurrent)

    private init() {
        createPhotosDirectoryIfNeeded()
        createThumbnailsDirectoryIfNeeded()
    }

    // MARK: - Directory Management - made internal for PhotoMigrationUtility
    
    internal func getPhotosDirectoryURL() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access Documents directory.")
            return nil
        }
        return documentsDirectory.appendingPathComponent(photosDirectoryName)
    }
    
    internal func getThumbnailsDirectoryURL() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access Documents directory.")
            return nil
        }
        return documentsDirectory.appendingPathComponent(thumbnailsDirectoryName)
    }

    internal func createPhotosDirectoryIfNeeded() {
        guard let photosDirectoryURL = getPhotosDirectoryURL() else { return }

        if !fileManager.fileExists(atPath: photosDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: photosDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created photos directory at: \(photosDirectoryURL.path)")
            } catch {
                print("❌ Error creating photos directory: \(error.localizedDescription)")
            }
        }
    }
    
    internal func createThumbnailsDirectoryIfNeeded() {
        guard let thumbnailsDirectoryURL = getThumbnailsDirectoryURL() else { return }

        if !fileManager.fileExists(atPath: thumbnailsDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: thumbnailsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created thumbnails directory at: \(thumbnailsDirectoryURL.path)")
            } catch {
                print("❌ Error creating thumbnails directory: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - URL Generation
    
    private func getPhotoURL(identifier: String) -> URL? {
        return getPhotosDirectoryURL()?.appendingPathComponent(identifier + ".jpg")
    }
    
    private func getThumbnailURL(identifier: String, size: ThumbnailSize) -> URL? {
        return getThumbnailsDirectoryURL()?.appendingPathComponent("\(identifier)_\(size.rawValue).jpg")
    }

    // MARK: - Image Processing
    
    private func compressAndResizeImage(_ data: Data, maxSize: CGSize, compressionQuality: CGFloat) -> Data? {
        guard let originalImage = UIImage(data: data) else { return nil }
        
        // Calculate new size maintaining aspect ratio
        let newSize = calculateNewSize(originalSize: originalImage.size, maxSize: maxSize)
        
        // Resize image
        let resizedImage = resizeImage(originalImage, to: newSize)
        
        // Compress as JPEG
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }
    
    private func calculateNewSize(originalSize: CGSize, maxSize: CGSize) -> CGSize {
        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let ratio = min(widthRatio, heightRatio)
        
        // Don't upscale images
        let finalRatio = min(ratio, 1.0)
        
        return CGSize(
            width: originalSize.width * finalRatio,
            height: originalSize.height * finalRatio
        )
    }
    
    private func resizeImage(_ image: UIImage, to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    // MARK: - Public Interface
    
    enum ThumbnailSize: String, CaseIterable {
        case small = "small"    // 40x40 for list icons
        case medium = "medium"  // 80x80 for cards
        case large = "large"    // 200x200 for detail view
        
        var size: CGSize {
            switch self {
            case .small: return CGSize(width: 40, height: 40)
            case .medium: return CGSize(width: 80, height: 80)
            case .large: return CGSize(width: 200, height: 200)
            }
        }
        
        var compressionQuality: CGFloat {
            switch self {
            case .small: return 0.7
            case .medium: return 0.8
            case .large: return 0.9
            }
        }
    }
    
    // Save original image and generate thumbnails
    func saveImage(data: Data, identifier: String) {
        guard let photoURL = getPhotoURL(identifier: identifier) else {
            print("❌ Could not get photo URL for saving identifier \(identifier)")
            return
        }
        
        // Save compressed original (max 1024px on longest side)
        let originalMaxSize = CGSize(width: 1024, height: 1024)
        guard let compressedData = compressAndResizeImage(data, maxSize: originalMaxSize, compressionQuality: 0.85) else {
            print("❌ Failed to compress original image for \(identifier)")
            return
        }
        
        do {
            try compressedData.write(to: photoURL)
            print("✅ Saved compressed photo: \(identifier)")
            
            // Generate thumbnails
            generateThumbnails(from: compressedData, identifier: identifier)
            
            // Clear cache for this identifier
            clearCacheForIdentifier(identifier)
            
        } catch {
            print("❌ Error saving photo \(identifier): \(error.localizedDescription)")
        }
    }
    
    private func generateThumbnails(from data: Data, identifier: String) {
        for size in ThumbnailSize.allCases {
            guard let thumbnailURL = getThumbnailURL(identifier: identifier, size: size),
                  let thumbnailData = compressAndResizeImage(data, maxSize: size.size, compressionQuality: size.compressionQuality) else {
                continue
            }
            
            do {
                try thumbnailData.write(to: thumbnailURL)
                print("✅ Generated \(size.rawValue) thumbnail for \(identifier)")
            } catch {
                print("❌ Failed to save \(size.rawValue) thumbnail for \(identifier): \(error)")
            }
        }
    }

    // Load original image
    func loadImage(identifier: String) -> UIImage? {
        // Check cache first
        if let cachedImage = cacheQueue.sync(execute: { imageCache[identifier] }) {
            return cachedImage
        }
        
        guard let photoURL = getPhotoURL(identifier: identifier) else { return nil }
        
        guard fileManager.fileExists(atPath: photoURL.path) else { return nil }
        
        do {
            let imageData = try Data(contentsOf: photoURL)
            let image = UIImage(data: imageData)
            
            // Cache the image
            if let image = image {
                cacheQueue.async(flags: .barrier) {
                    self.imageCache[identifier] = image
                }
            }
            
            return image
        } catch {
            print("❌ Error loading image \(identifier): \(error.localizedDescription)")
            return nil
        }
    }
    
    // Load thumbnail - this is what we'll use for icons!
    func loadThumbnail(identifier: String, size: ThumbnailSize = .small) -> UIImage? {
        let cacheKey = "\(identifier)_\(size.rawValue)"
        
        // Check cache first
        if let cachedThumbnail = cacheQueue.sync(execute: { thumbnailCache[cacheKey] }) {
            return cachedThumbnail
        }
        
        guard let thumbnailURL = getThumbnailURL(identifier: identifier, size: size) else { return nil }
        
        guard fileManager.fileExists(atPath: thumbnailURL.path) else {
            // If thumbnail doesn't exist, try to generate it from original
            return generateMissingThumbnail(identifier: identifier, size: size)
        }
        
        do {
            let imageData = try Data(contentsOf: thumbnailURL)
            let image = UIImage(data: imageData)
            
            // Cache the thumbnail
            if let image = image {
                cacheQueue.async(flags: .barrier) {
                    self.thumbnailCache[cacheKey] = image
                }
            }
            
            return image
        } catch {
            print("❌ Error loading thumbnail \(identifier): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func generateMissingThumbnail(identifier: String, size: ThumbnailSize) -> UIImage? {
        guard let originalImage = loadImage(identifier: identifier) else { return nil }
        
        let resized = resizeImage(originalImage, to: size.size)
        
        // Save the thumbnail for future use
        if let thumbnailURL = getThumbnailURL(identifier: identifier, size: size),
           let thumbnailData = resized.jpegData(compressionQuality: size.compressionQuality) {
            try? thumbnailData.write(to: thumbnailURL)
        }
        
        return resized
    }

    // Delete all files for an identifier
    func deleteImage(identifier: String) {
        // Delete original
        if let photoURL = getPhotoURL(identifier: identifier) {
            try? fileManager.removeItem(at: photoURL)
        }
        
        // Delete thumbnails
        for size in ThumbnailSize.allCases {
            if let thumbnailURL = getThumbnailURL(identifier: identifier, size: size) {
                try? fileManager.removeItem(at: thumbnailURL)
            }
        }
        
        // Clear cache
        clearCacheForIdentifier(identifier)
        
        print("✅ Deleted all files for photo: \(identifier)")
    }
    
    private func clearCacheForIdentifier(_ identifier: String) {
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeValue(forKey: identifier)
            for size in ThumbnailSize.allCases {
                let cacheKey = "\(identifier)_\(size.rawValue)"
                self.thumbnailCache.removeValue(forKey: cacheKey)
            }
        }
    }

    // Check if image exists
    func imageExists(identifier: String) -> Bool {
        guard let photoURL = getPhotoURL(identifier: identifier) else { return false }
        return fileManager.fileExists(atPath: photoURL.path)
    }

    // Cleanup orphaned photos
    func cleanupOrphanedPhotos(validIdentifiers: Set<String>) {
        guard let photosDirectory = getPhotosDirectoryURL(),
              let thumbnailsDirectory = getThumbnailsDirectoryURL() else { return }
        
        let directories = [photosDirectory, thumbnailsDirectory]
        
        for directory in directories {
            do {
                let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                
                for file in files {
                    let filename = file.deletingPathExtension().lastPathComponent
                    // Handle thumbnail naming (remove size suffix)
                    let identifier = filename.components(separatedBy: "_").first ?? filename
                    
                    if !validIdentifiers.contains(identifier) {
                        try fileManager.removeItem(at: file)
                        print("🧹 Cleaned up orphaned photo file: \(filename)")
                    }
                }
            } catch {
                print("❌ Error during photo cleanup in \(directory.lastPathComponent): \(error)")
            }
        }
        
        // Clear entire cache since we may have deleted files
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
            self.thumbnailCache.removeAll()
        }
    }

    // Get total storage used by photos
    func getTotalStorageUsed() -> Int64 {
        var totalSize: Int64 = 0
        
        let directories = [getPhotosDirectoryURL(), getThumbnailsDirectoryURL()].compactMap { $0 }
        
        for directory in directories {
            do {
                let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
                
                for file in files {
                    let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                    totalSize += Int64(attributes.fileSize ?? 0)
                }
            } catch {
                print("❌ Error calculating storage for \(directory.lastPathComponent): \(error)")
            }
        }
        
        return totalSize
    }
    
    // ✅ ADDED: Get detailed storage information (for PhotoMigrationUtility)
    func getDetailedStorageInfo() -> PhotoStorageInfo {
        var originalSize: Int64 = 0
        var thumbnailSize: Int64 = 0
        var photoCount = 0
        var thumbnailCount = 0
        
        // Calculate original photos size
        if let photosURL = getPhotosDirectoryURL() {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: photosURL, includingPropertiesForKeys: [.fileSizeKey])
                for file in files {
                    let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                    originalSize += Int64(attributes.fileSize ?? 0)
                    photoCount += 1
                }
            } catch {
                print("Error calculating original photos size: \(error)")
            }
        }
        
        // Calculate thumbnails size
        if let thumbnailsURL = getThumbnailsDirectoryURL() {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: thumbnailsURL, includingPropertiesForKeys: [.fileSizeKey])
                for file in files {
                    let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                    thumbnailSize += Int64(attributes.fileSize ?? 0)
                    thumbnailCount += 1
                }
            } catch {
                print("Error calculating thumbnails size: \(error)")
            }
        }
        
        return PhotoStorageInfo(
            totalSize: originalSize + thumbnailSize,
            originalPhotosSize: originalSize,
            thumbnailsSize: thumbnailSize,
            photoCount: photoCount,
            thumbnailCount: thumbnailCount
        )
    }
    
    // ✅ ADDED: Clean up all photos and thumbnails (for PhotoMigrationUtility)
    func clearAllPhotos() {
        if let photosURL = getPhotosDirectoryURL() {
            try? FileManager.default.removeItem(at: photosURL)
            createPhotosDirectoryIfNeeded()
        }
        
        if let thumbnailsURL = getThumbnailsDirectoryURL() {
            try? FileManager.default.removeItem(at: thumbnailsURL)
            createThumbnailsDirectoryIfNeeded()
        }
        
        // Clear caches
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
            self.thumbnailCache.removeAll()
        }
        
        print("🧹 Cleared all photos and thumbnails")
    }
}

// ✅ ADDED: Photo Storage Info struct (needed by PhotoMigrationUtility)
struct PhotoStorageInfo {
    let totalSize: Int64
    let originalPhotosSize: Int64
    let thumbnailsSize: Int64
    let photoCount: Int
    let thumbnailCount: Int
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: originalPhotosSize, countStyle: .file)
    }
    
    var formattedThumbnailSize: String {
        ByteCountFormatter.string(fromByteCount: thumbnailsSize, countStyle: .file)
    }
    
    var compressionRatio: Double {
        guard originalPhotosSize > 0 else { return 0 }
        return 1.0 - (Double(totalSize) / Double(originalPhotosSize))
    }
    
    var compressionPercentage: String {
        String(format: "%.1f%%", compressionRatio * 100)
    }
}
