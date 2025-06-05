import Foundation
import SwiftData
import UIKit

// MARK: - Photo Migration Utility
struct PhotoMigrationUtility {
    
    // Migrate existing photos to compressed format
    static func migrateExistingPhotos(modelContext: ModelContext) async {
        print("🔄 Starting photo migration to compressed format...")
        
        do {
            // Get all items with photos
            let itemDescriptor = FetchDescriptor<Item>()
            let allItems = try modelContext.fetch(itemDescriptor)
            let itemsWithPhotos = allItems.filter { $0.photoIdentifier != nil }
            
            // Get all containers with photos
            let containerDescriptor = FetchDescriptor<Container>()
            let allContainers = try modelContext.fetch(containerDescriptor)
            let containersWithPhotos = allContainers.filter { $0.photoIdentifier != nil }
            
            var migratedCount = 0
            var failedCount = 0
            
            print("📊 Found \(itemsWithPhotos.count) items and \(containersWithPhotos.count) containers with photos")
            
            // Migrate item photos
            for item in itemsWithPhotos {
                if await migratePhoto(identifier: item.photoIdentifier!) {
                    migratedCount += 1
                } else {
                    failedCount += 1
                }
            }
            
            // Migrate container photos
            for container in containersWithPhotos {
                if await migratePhoto(identifier: container.photoIdentifier!) {
                    migratedCount += 1
                } else {
                    failedCount += 1
                }
            }
            
            print("✅ Photo migration complete: \(migratedCount) migrated, \(failedCount) failed")
            
        } catch {
            print("❌ Error during photo migration: \(error)")
        }
    }
    
    private static func migratePhoto(identifier: String) async -> Bool {
        // Check if we already have thumbnails (indicating compression is done)
        if PhotoManager.shared.loadThumbnail(identifier: identifier, size: .small) != nil {
            return true // Already migrated
        }
        
        // Load original photo
        guard let originalImage = PhotoManager.shared.loadImage(identifier: identifier) else {
            print("⚠️ Could not load original photo: \(identifier)")
            return false
        }
        
        // Convert to data and re-save (this will trigger compression)
        guard let imageData = originalImage.jpegData(compressionQuality: 1.0) else {
            print("⚠️ Could not convert photo to data: \(identifier)")
            return false
        }
        
        // Re-save with compression (this will generate thumbnails)
        PhotoManager.shared.saveImage(data: imageData, identifier: identifier)
        
        print("✅ Migrated photo: \(identifier)")
        return true
    }
    
    // Validate photo integrity
    static func validatePhotoIntegrity(modelContext: ModelContext) async -> PhotoValidationReport {
        var report = PhotoValidationReport()
        
        do {
            // Check items
            let itemDescriptor = FetchDescriptor<Item>()
            let allItems = try modelContext.fetch(itemDescriptor)
            
            for item in allItems {
                if let photoId = item.photoIdentifier {
                    if PhotoManager.shared.imageExists(identifier: photoId) {
                        report.validPhotos.append(photoId)
                    } else {
                        report.missingPhotos.append(MissingPhoto(identifier: photoId, entityName: item.name, entityType: "Item"))
                    }
                }
            }
            
            // Check containers
            let containerDescriptor = FetchDescriptor<Container>()
            let allContainers = try modelContext.fetch(containerDescriptor)
            
            for container in allContainers {
                if let photoId = container.photoIdentifier {
                    if PhotoManager.shared.imageExists(identifier: photoId) {
                        report.validPhotos.append(photoId)
                    } else {
                        report.missingPhotos.append(MissingPhoto(identifier: photoId, entityName: container.name, entityType: "Container"))
                    }
                }
            }
            
            // Find orphaned photos
            let validIdentifiers = Set(report.validPhotos)
            let allPhotoFiles = getAllPhotoFiles()
            report.orphanedPhotos = allPhotoFiles.filter { !validIdentifiers.contains($0) }
            
        } catch {
            print("❌ Error validating photos: \(error)")
        }
        
        return report
    }
    
    private static func getAllPhotoFiles() -> [String] {
        guard let photosURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
                .appendingPathComponent("ClutterBugPhotos") else {
            return []
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: photosURL, includingPropertiesForKeys: nil)
            return files.map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            return []
        }
    }
}

// MARK: - Photo Validation Report
struct PhotoValidationReport {
    var validPhotos: [String] = []
    var missingPhotos: [MissingPhoto] = []
    var orphanedPhotos: [String] = []
    
    var totalPhotos: Int {
        validPhotos.count + missingPhotos.count
    }
    
    var hasIssues: Bool {
        !missingPhotos.isEmpty || !orphanedPhotos.isEmpty
    }
}

struct MissingPhoto {
    let identifier: String
    let entityName: String
    let entityType: String
}
