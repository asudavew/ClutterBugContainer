import SwiftUI
import SwiftData

// MARK: - Shape Editor View
struct ShapeEditorView: View {
    @Bindable var container: Container
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var tempLength: Double
    @State private var tempWidth: Double
    @State private var tempSide3: Double
    @State private var tempSide4: Double
    @State private var tempRotation: Double
    @State private var tempShapeType: PlacedShape.ShapeType
    @State private var tempColorType: PlacedShape.ShapeColor
    
    init(container: Container) {
        self.container = container
        _tempLength = State(initialValue: container.length)
        _tempWidth = State(initialValue: container.width)
        _tempSide3 = State(initialValue: container.side3 ?? 0)
        _tempSide4 = State(initialValue: container.side4 ?? 0)
        _tempRotation = State(initialValue: container.rotation ?? 0)
        _tempShapeType = State(initialValue: container.shapeTypeEnum ?? .rectangle)
        _tempColorType = State(initialValue: container.colorTypeEnum ?? .blue)
    }
    
    var body: some View {
        Form {
            containerInfoSection
            shapePropertiesSection
            dimensionsSection
            
            if tempShapeType.canRotate {
                orientationSection
            }
            
            previewSection
        }
        .navigationTitle("Edit Shape")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveChanges() }
                    .fontWeight(.semibold)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var containerInfoSection: some View {
        Section("Container Info") {
            HStack {
                Image(systemName: container.safeDynamicType(using: hierarchyManager).icon)
                    .foregroundColor(tempColorType.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(container.name)
                        .font(.headline)
                    Text(container.safeDynamicType(using: hierarchyManager).displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Level \(container.levelNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    private var shapePropertiesSection: some View {
        Section("Shape Properties") {
            Picker("Shape Type", selection: $tempShapeType) {
                ForEach(PlacedShape.ShapeType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.icon)
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            
            Picker("Color", selection: $tempColorType) {
                ForEach(PlacedShape.ShapeColor.allCases, id: \.self) { color in
                    HStack {
                        Circle()
                            .fill(color.color)
                            .frame(width: 20, height: 20)
                        Text(color.displayName)
                    }
                    .tag(color)
                }
            }
        }
    }
    
    private var dimensionsSection: some View {
        Section("Dimensions") {
            let unit = hierarchyManager.dimensionUnit(for: container.levelNumber)
            
            switch tempShapeType {
            case .circle:
                HStack {
                    Text("Diameter (\(unit)):")
                    Spacer()
                    TextField("Diameter", value: $tempWidth, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: tempWidth) { _, newValue in
                            tempLength = newValue
                        }
                }
                
            case .rectangle:
                HStack {
                    Text("Length (\(unit)):")
                    Spacer()
                    TextField("Length", value: $tempLength, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                HStack {
                    Text("Width (\(unit)):")
                    Spacer()
                    TextField("Width", value: $tempWidth, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
            case .triangle:
                HStack {
                    Text("Side 1 (\(unit)):")
                    Spacer()
                    TextField("Side 1", value: $tempLength, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                HStack {
                    Text("Side 2 (\(unit)):")
                    Spacer()
                    TextField("Side 2", value: $tempWidth, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                HStack {
                    Text("Side 3 (\(unit)):")
                    Spacer()
                    TextField("Side 3", value: $tempSide3, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
            case .quadrilateral:
                HStack {
                    Text("Top (\(unit)):")
                    Spacer()
                    TextField("Top", value: $tempLength, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                HStack {
                    Text("Right (\(unit)):")
                    Spacer()
                    TextField("Right", value: $tempWidth, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                HStack {
                    Text("Bottom (\(unit)):")
                    Spacer()
                    TextField("Bottom", value: $tempSide3, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                HStack {
                    Text("Left (\(unit)):")
                    Spacer()
                    TextField("Left", value: $tempSide4, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
            case .tee:
                HStack {
                    Text("Total Width (\(unit)):")
                    Spacer()
                    TextField("Total Width", value: $tempLength, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                HStack {
                    Text("Total Height (\(unit)):")
                    Spacer()
                    TextField("Total Height", value: $tempWidth, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                HStack {
                    Text("Stem Width (\(unit)):")
                    Spacer()
                    TextField("Stem Width", value: $tempSide3, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                HStack {
                    Text("Top Height (\(unit)):")
                    Spacer()
                    TextField("Top Height", value: $tempSide4, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
        }
    }
    
    private var orientationSection: some View {
        Section("Orientation") {
            VStack(spacing: 12) {
                HStack {
                    Text("Rotation: \(Int(tempRotation))°")
                        .font(.subheadline)
                    Spacer()
                    Button("Reset") {
                        tempRotation = 0
                    }
                    .font(.caption)
                    .disabled(tempRotation == 0)
                }
                
                Slider(value: $tempRotation, in: 0...360, step: 15) {
                    Text("Rotation")
                }
                .accentColor(tempColorType.color)
            }
        }
    }
    
    private var previewSection: some View {
        Section("Preview") {
            ShapePreviewView(
                shapeType: tempShapeType,
                color: tempColorType,
                rotation: tempRotation,
                length: tempLength,
                width: tempWidth,
                side3: tempSide3,
                side4: tempSide4
            )
            .frame(height: 200)
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveChanges() {
        container.length = tempLength
        container.width = tempWidth
        container.side3 = tempSide3 > 0 ? tempSide3 : nil
        container.side4 = tempSide4 > 0 ? tempSide4 : nil
        container.rotation = tempRotation
        container.shapeType = tempShapeType.rawValue
        container.colorType = tempColorType.rawValue
        
        do {
            try modelContext.save()
            print("✅ Shape updated: \(container.name)")
            dismiss()
        } catch {
            print("❌ Error saving shape changes: \(error)")
        }
    }
}

// MARK: - Shape Preview Component
struct ShapePreviewView: View {
    let shapeType: PlacedShape.ShapeType
    let color: PlacedShape.ShapeColor
    let rotation: Double
    let length: Double
    let width: Double
    let side3: Double
    let side4: Double
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
            
            Canvas { context, size in
                let center = CGPoint(x: size.width/2, y: size.height/2)
                let maxDimension = min(size.width, size.height) * 0.6
                let scaleX = maxDimension / max(length, 1)
                let scaleY = maxDimension / max(width, 1)
                let scale = min(scaleX, scaleY)
                
                let rect = CGRect(
                    x: center.x - (length * scale)/2,
                    y: center.y - (width * scale)/2,
                    width: length * scale,
                    height: width * scale
                )
                
                context.translateBy(x: center.x, y: center.y)
                context.rotate(by: .degrees(rotation))
                context.translateBy(x: -center.x, y: -center.y)
                
                let path = Path(rect)
                context.fill(path, with: .color(color.color.opacity(0.3)))
                context.stroke(path, with: .color(color.color), lineWidth: 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
