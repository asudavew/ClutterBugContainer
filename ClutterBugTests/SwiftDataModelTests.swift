import XCTest
import SwiftData
@testable import ClutterBug

final class SwiftDataModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        // Set up an in-memory ModelContainer for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: Building.self, Room.self, Item.self, configurations: config)
        modelContext = modelContainer.mainContext
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        modelContainer = nil
        modelContext = nil
    }

    func testBuildingCreation() throws {
        // Test creating a Building
        let testBuilding = Building(name: "Test Workshop", width: 20, length: 30)
        modelContext.insert(testBuilding)
        
        try modelContext.save()
        
        // Verify the building was saved
        let fetchDescriptor = FetchDescriptor<Building>()
        let buildings = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(buildings.count, 1, "Should have exactly one building")
        XCTAssertEqual(buildings.first?.name, "Test Workshop", "Building name should match")
        XCTAssertEqual(buildings.first?.width, 20, "Building width should match")
        XCTAssertEqual(buildings.first?.length, 30, "Building length should match")
    }

    func testRoomCreation() throws {
        // Test creating a Room within a Building
        let testBuilding = Building(name: "Test Building", width: 40, length: 50)
        modelContext.insert(testBuilding)
        
        let testRoom = Room.create(type: .rectangle, at: CGPoint(x: 100, y: 100), in: testBuilding)
        testRoom.name = "Test Room"
        testRoom.purpose = "Storage"
        modelContext.insert(testRoom)
        
        try modelContext.save()
        
        // Verify the room was saved and linked to building
        let fetchDescriptor = FetchDescriptor<Room>()
        let rooms = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(rooms.count, 1, "Should have exactly one room")
        XCTAssertEqual(rooms.first?.name, "Test Room", "Room name should match")
        XCTAssertEqual(rooms.first?.parentBuilding?.id, testBuilding.id, "Room should be linked to the building")
    }

    func testItemCreationAndRetrieval() throws {
        // Test creating Items and retrieving them
        
        // First create a building and room
        let currentDefaultBuilding = Building(name: "Default Workshop", width: 30, length: 40)
        modelContext.insert(currentDefaultBuilding)
        
        let defaultRoom = Room.create(type: .rectangle, at: CGPoint(x: 100, y: 100), in: currentDefaultBuilding)
        defaultRoom.name = "Tool Storage"
        defaultRoom.purpose = "Hand tools"
        modelContext.insert(defaultRoom)
        
        // Now create items in the room
        let item1 = Item(name: "Hammer", category: "Tools", quantity: 1, parentRoom: defaultRoom)
        let item2 = Item(name: "Screwdriver", category: "Tools", quantity: 5, parentRoom: defaultRoom)
        
        modelContext.insert(item1)
        modelContext.insert(item2)
        
        try modelContext.save()
        
        // Test fetching all items
        let fetchDescriptor = FetchDescriptor<Item>()
        let fetchedItems = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedItems.count, 2, "Should have exactly two items")
        
        // Test fetching specific item
        let hammerPredicate = #Predicate<Item> { $0.name == "Hammer" }
        let hammerFetchDescriptor = FetchDescriptor<Item>(predicate: hammerPredicate)
        let fetchedItem = try modelContext.fetch(hammerFetchDescriptor).first
        
        XCTAssertNotNil(fetchedItem, "Should find the hammer")
        XCTAssertEqual(fetchedItem?.name, "Hammer", "Fetched item name should match")
        XCTAssertEqual(fetchedItem?.category, "Tools", "Fetched item category should match")
        XCTAssertEqual(fetchedItem?.quantity, 1, "Fetched item quantity should match")
        XCTAssertEqual(fetchedItem?.parentRoom?.id, defaultRoom.id, "Item should be parented to the room")
        XCTAssertEqual(fetchedItem?.ultimateBuilding?.id, currentDefaultBuilding.id, "Item should be linked to the building through room")
    }

    func testItemUpdate() throws {
        // Test updating an Item
        
        // Create building and room
        let currentDefaultBuilding = Building(name: "Default Workshop", width: 30, length: 40)
        modelContext.insert(currentDefaultBuilding)
        
        let defaultRoom = Room.create(type: .rectangle, at: CGPoint(x: 100, y: 100), in: currentDefaultBuilding)
        defaultRoom.name = "Storage Area"
        modelContext.insert(defaultRoom)
        
        let itemToUpdate = Item(name: "Old Paint Can", category: "Supplies", quantity: 1, parentRoom: defaultRoom)
        modelContext.insert(itemToUpdate)
        
        try modelContext.save()
        
        // Update the item
        itemToUpdate.name = "New Paint Can"
        itemToUpdate.quantity = 3
        
        try modelContext.save()
        
        // Verify the update
        let fetchDescriptor = FetchDescriptor<Item>()
        let fetchedItems = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedItems.count, 1, "Should still have exactly one item")
        XCTAssertEqual(fetchedItems.first?.name, "New Paint Can", "Item name should be updated")
        XCTAssertEqual(fetchedItems.first?.quantity, 3, "Item quantity should be updated")
    }

    func testItemDeletion() throws {
        // Test deleting an Item
        
        // Create building and room
        let currentDefaultBuilding = Building(name: "Default Workshop", width: 30, length: 40)
        modelContext.insert(currentDefaultBuilding)
        
        let defaultRoom = Room.create(type: .rectangle, at: CGPoint(x: 100, y: 100), in: currentDefaultBuilding)
        defaultRoom.name = "Temporary Storage"
        modelContext.insert(defaultRoom)
        
        let itemToDelete = Item(name: "Disposable Item", category: "Misc", quantity: 1, parentRoom: defaultRoom)
        modelContext.insert(itemToDelete)
        
        try modelContext.save()
        
        // Verify item exists
        var fetchDescriptor = FetchDescriptor<Item>()
        var fetchedItems = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedItems.count, 1, "Should have one item before deletion")
        
        // Delete the item
        modelContext.delete(itemToDelete)
        try modelContext.save()
        
        // Verify item is deleted
        fetchDescriptor = FetchDescriptor<Item>()
        fetchedItems = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedItems.count, 0, "Should have no items after deletion")
    }

    func testCascadeDelete() throws {
        // Test that deleting a Building also deletes its Rooms and Items
        
        let buildingForCascadeTest = Building(name: "Building To Delete", width: 25, length: 35)
        modelContext.insert(buildingForCascadeTest)
        
        // Create rooms
        let room1 = Room.create(type: .rectangle, at: CGPoint(x: 50, y: 50), in: buildingForCascadeTest)
        room1.name = "Room 1"
        let room2 = Room.create(type: .rectangle, at: CGPoint(x: 150, y: 50), in: buildingForCascadeTest)
        room2.name = "Room 2"
        modelContext.insert(room1)
        modelContext.insert(room2)
        
        // Create items in the rooms
        let item1 = Item(name: "Cascade Item 1", category: "Test", quantity: 1, parentRoom: room1)
        let item2 = Item(name: "Cascade Item 2", category: "Test", quantity: 1, parentRoom: room2)
        
        modelContext.insert(item1)
        modelContext.insert(item2)
        
        try modelContext.save()
        
        // Verify everything exists
        var buildingFetchDescriptor = FetchDescriptor<Building>()
        var roomFetchDescriptor = FetchDescriptor<Room>()
        var itemFetchDescriptor = FetchDescriptor<Item>()
        
        XCTAssertEqual(try modelContext.fetch(buildingFetchDescriptor).count, 1, "Should have one building")
        XCTAssertEqual(try modelContext.fetch(roomFetchDescriptor).count, 2, "Should have two rooms")
        XCTAssertEqual(try modelContext.fetch(itemFetchDescriptor).count, 2, "Should have two items")
        
        // Delete the building
        modelContext.delete(buildingForCascadeTest)
        try modelContext.save()
        
        // Verify cascade delete worked
        buildingFetchDescriptor = FetchDescriptor<Building>()
        roomFetchDescriptor = FetchDescriptor<Room>()
        itemFetchDescriptor = FetchDescriptor<Item>()
        
        XCTAssertEqual(try modelContext.fetch(buildingFetchDescriptor).count, 0, "Should have no buildings")
        XCTAssertEqual(try modelContext.fetch(roomFetchDescriptor).count, 0, "Should have no rooms (cascade deleted)")
        XCTAssertEqual(try modelContext.fetch(itemFetchDescriptor).count, 0, "Should have no items (cascade deleted)")
    }

    func testItemParentBuildingRelationship() throws {
        // Test that Items can access their parent Building through the Room
        
        let testBuilding = Building(name: "Test Building For Relationship", width: 30, length: 40)
        modelContext.insert(testBuilding)
        
        let testRoom = Room.create(type: .rectangle, at: CGPoint(x: 100, y: 100), in: testBuilding)
        testRoom.name = "Test Room"
        modelContext.insert(testRoom)
        
        let testItem = Item(name: "Test Item", category: "Test", quantity: 1, parentRoom: testRoom)
        modelContext.insert(testItem)
        
        try modelContext.save()
        
        // Test the relationship chain
        XCTAssertEqual(testItem.parentRoom?.id, testRoom.id, "Item should be linked to room")
        XCTAssertEqual(testItem.ultimateBuilding?.id, testBuilding.id, "Item should access building through room")
        XCTAssertEqual(testItem.roomName, "Test Room", "Item should show correct room name")
    }

    func testBuildingItemCount() throws {
        // Test that Building correctly counts items across all its rooms
        
        let testBuilding = Building(name: "Multi-Room Building", width: 50, length: 60)
        modelContext.insert(testBuilding)
        
        // Create multiple rooms
        let room1 = Room.create(type: .rectangle, at: CGPoint(x: 50, y: 50), in: testBuilding)
        room1.name = "Room 1"
        let room2 = Room.create(type: .rectangle, at: CGPoint(x: 150, y: 50), in: testBuilding)
        room2.name = "Room 2"
        modelContext.insert(room1)
        modelContext.insert(room2)
        
        // Add items to different rooms
        let item1 = Item(name: "Item in Room 1", category: "Test", quantity: 1, parentRoom: room1)
        let item2 = Item(name: "Item in Room 2", category: "Test", quantity: 1, parentRoom: room2)
        let item3 = Item(name: "Another Item in Room 1", category: "Test", quantity: 1, parentRoom: room1)
        
        modelContext.insert(item1)
        modelContext.insert(item2)
        modelContext.insert(item3)
        
        try modelContext.save()
        
        // Test building's item count
        XCTAssertEqual(testBuilding.totalItemCount, 3, "Building should count all items across rooms")
        XCTAssertEqual(testBuilding.allItems.count, 3, "Building should return all items from all rooms")
    }

    func testQueryByBuildingID() throws {
        // Test querying items by building ID through rooms
        
        let buildingID = UUID()
        let building = Building(id: buildingID, name: "Queryable Building", width: 30, length: 40)
        modelContext.insert(building)
        
        let room = Room.create(type: .rectangle, at: CGPoint(x: 100, y: 100), in: building)
        room.name = "Query Room"
        modelContext.insert(room)
        
        let item = Item(name: "Queryable Item", category: "Query Test", quantity: 1, parentRoom: room)
        modelContext.insert(item)
        
        try modelContext.save()
        
        // Query items by building ID
        let buildingIDValue = buildingID
        let itemsByBuildingPredicate = #Predicate<Item> { itemRecord in
            itemRecord.parentRoom?.parentBuilding?.id == buildingIDValue
        }
        let itemsByBuildingDescriptor = FetchDescriptor<Item>(predicate: itemsByBuildingPredicate)
        let itemsInBuilding = try modelContext.fetch(itemsByBuildingDescriptor)
        
        XCTAssertEqual(itemsInBuilding.count, 1, "Should find one item in the building")
        XCTAssertEqual(itemsInBuilding.first?.name, "Queryable Item", "Should find the correct item")
    }
}
