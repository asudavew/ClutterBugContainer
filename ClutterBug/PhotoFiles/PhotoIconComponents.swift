import SwiftUI

// MARK: - Photo or Icon Component
struct PhotoOrIcon: View {
    let photoIdentifier: String?
    let fallbackIcon: String
    let fallbackColor: Color
    let size: PhotoIconSize
    let cornerRadius: CGFloat
    let borderColor: Color?
    let borderWidth: CGFloat
    
    init(
        photoIdentifier: String?,
        fallbackIcon: String,
        fallbackColor: Color = .blue,
        size: PhotoIconSize = .medium,
        cornerRadius: CGFloat = 8,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1.5
    ) {
        self.photoIdentifier = photoIdentifier
        self.fallbackIcon = fallbackIcon
        self.fallbackColor = fallbackColor
        self.size = size
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        Group {
            if let photoId = photoIdentifier,
               let thumbnail = PhotoManager.shared.loadThumbnail(identifier: photoId, size: size.thumbnailSize) {
                // Show photo thumbnail
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.dimension, height: size.dimension)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor ?? fallbackColor, lineWidth: borderWidth)
                    )
            } else {
                // Show fallback icon
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fallbackColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(borderColor ?? fallbackColor, lineWidth: borderWidth)
                        )
                        .frame(width: size.dimension, height: size.dimension)
                    
                    Image(systemName: fallbackIcon)
                        .font(.system(size: size.iconSize, weight: .medium))
                        .foregroundColor(fallbackColor)
                }
            }
        }
    }
}

// MARK: - Photo Icon Sizes
enum PhotoIconSize: String, CaseIterable {
    case small = "small"      // 32x32 - for compact lists
    case medium = "medium"    // 40x40 - for normal lists
    case large = "large"      // 60x60 - for cards
    case xlarge = "xlarge"    // 80x80 - for headers
    
    var dimension: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 40
        case .large: return 60
        case .xlarge: return 80
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 24
        case .xlarge: return 32
        }
    }
    
    var thumbnailSize: PhotoManager.ThumbnailSize {
        switch self {
        case .small, .medium: return .small
        case .large: return .medium
        case .xlarge: return .large
        }
    }
}

// MARK: - Container Icon Component
struct ContainerIcon: View {
    let container: Container
    @EnvironmentObject var hierarchyManager: HierarchyManager
    let size: PhotoIconSize
    let showBorder: Bool
    
    init(container: Container, size: PhotoIconSize = .medium, showBorder: Bool = true) {
        self.container = container
        self.size = size
        self.showBorder = showBorder
    }
    
    var body: some View {
        PhotoOrIcon(
            photoIdentifier: container.photoIdentifier,
            fallbackIcon: container.safeDynamicType(using: hierarchyManager).icon,
            fallbackColor: container.colorTypeEnum?.color ?? .blue,
            size: size,
            borderColor: showBorder ? container.colorTypeEnum?.color ?? .blue : nil,
            borderWidth: showBorder ? 1.5 : 0
        )
    }
}

// MARK: - Item Icon Component
struct ItemIcon: View {
    let item: Item
    let size: PhotoIconSize
    let showBorder: Bool
    
    init(item: Item, size: PhotoIconSize = .medium, showBorder: Bool = true) {
        self.item = item
        self.size = size
        self.showBorder = showBorder
    }
    
    var body: some View {
        PhotoOrIcon(
            photoIdentifier: item.photoIdentifier,
            fallbackIcon: "cube.box.fill",
            fallbackColor: .gray,
            size: size,
            borderColor: showBorder ? .gray : nil,
            borderWidth: showBorder ? 1.5 : 0
        )
    }
}

// MARK: - Enhanced Photo Display Component
struct PhotoDisplay: View {
    let photoIdentifier: String?
    let fallbackIcon: String?
    let fallbackColor: Color
    let maxHeight: CGFloat
    let cornerRadius: CGFloat
    let showPlaceholder: Bool
    
    init(
        photoIdentifier: String?,
        fallbackIcon: String? = nil,
        fallbackColor: Color = .gray,
        maxHeight: CGFloat = 200,
        cornerRadius: CGFloat = 12,
        showPlaceholder: Bool = true
    ) {
        self.photoIdentifier = photoIdentifier
        self.fallbackIcon = fallbackIcon
        self.fallbackColor = fallbackColor
        self.maxHeight = maxHeight
        self.cornerRadius = cornerRadius
        self.showPlaceholder = showPlaceholder
    }
    
    var body: some View {
        Group {
            if let photoId = photoIdentifier,
               let image = PhotoManager.shared.loadImage(identifier: photoId) {
                // Show full-size photo
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: maxHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else if showPlaceholder {
                // Show placeholder
                VStack(spacing: 12) {
                    if let icon = fallbackIcon {
                        Image(systemName: icon)
                            .font(.system(size: 40))
                            .foregroundColor(fallbackColor)
                    }
                    
                    Text("No Photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: maxHeight)
                .background(fallbackColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }
}
