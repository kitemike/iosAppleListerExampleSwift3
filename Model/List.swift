/*
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `List` class manages a list of items and the color of the list.
*/

import Foundation

/**
    The `List` class manages the color of a list and each `ListItem` object. `List` objects are copyable and
    archivable. `List` objects are normally associated with an object that conforms to `ListPresenterType`.
    This object manages how the list is presented, archived, and manipulated. To ensure that the `List` class
    is unarchivable from an instance that was archived in the Objective-C version of Lister, the `List` class
    declaration is annotated with @objc(AAPLList). This annotation ensures that the runtime name of the `List`
    class is the same as the `AAPLList` class defined in the Objective-C version of the app. It also allows 
    the Objective-C version of Lister to unarchive a `List` instance that was archived in the Swift version.
*/
@objc(AAPLList)
final  class List: NSObject, NSCoding, NSCopying {
    // MARK: Types
    
    /**
        String constants that are used to archive the stored properties of a `List`. These constants
        are used to help implement `NSCoding`.
    */
    private struct SerializationKeys {
        static let items = "items"
        static let color = "color"
    }
    
    /**
        The possible colors a list can have. Because a list's color is specific to a `List` object,
        it is represented by a nested type. The `Printable` representation of the enumeration is 
        the name of the value. For example, .Gray corresponds to "Gray".

        - Gray (default)
        - Blue
        - Green
        - Yellow
        - Orange
        - Red
    */
     enum Color: Int, CustomStringConvertible {
        case Gray, Blue, Green, Yellow, Orange, Red
        
        // MARK: Properties

         var name: String {
            switch self {
                case .Gray:     return "Gray"
                case .Blue:     return "Blue"
                case .Green:    return "Green"
                case .Orange:   return "Orange"
                case .Yellow:   return "Yellow"
                case .Red:      return "Red"
            }
        }

        // MARK: Printable
        
         var description: String {
            return name
        }
    }
    
    // MARK: Properties
    
    /// The list's color. This property is stored when it is archived and read when it is unarchived.
     var color: Color
    
    /// The list's items.
     var items = [ListItem]()
    
    // MARK: Initializers
    
    /**
        Initializes a `List` instance with the designated color and items. The default color of a `List` is
        gray.
        
        - parameter color: The intended color of the list.
        - parameter items: The items that represent the underlying list. The `List` class copies the items
                      during initialization.
    */
     init(color: Color = .Gray, items: [ListItem] = []) {
        self.color = color
        
        self.items = items.map { $0.copy() as! ListItem }
    }

    // MARK: NSCoding
    
     required init(coder aDecoder: NSCoder) {
        items = aDecoder.decodeObject(forKey: SerializationKeys.items) as! [ListItem]
        color = Color(rawValue: aDecoder.decodeInteger(forKey: SerializationKeys.color))!
    }
    
//     func encodeWithCoder(aCoder: NSCoder) {
     func encode(with aCoder: NSCoder) {
        aCoder.encode(items, forKey: SerializationKeys.items)
        aCoder.encode(color.rawValue, forKey: SerializationKeys.color)
    }
    
    // MARK: NSCopying
    
//     func copyWithZone(zone: NSZone) -> AnyObject  {
     func copy(with zone: NSZone? = nil) -> Any {
        return List(color: color, items: items)
    }

    // MARK: Equality
    
    /**
        Overrides NSObject's isEqual(_:) instance method to return whether the list is equal to 
        another list. A `List` is considered to be equal to another `List` if its color and items
        are equal.
        
        - parameter object: Any object, or nil.
        
        - returns:  `true` if the object is a `List` and it has the same color and items as the receiving
                  instance. `false` otherwise.
    */
//    override  func isEqual(  object: AnyObject?) -> Bool { //swift3 needs _
    override         func isEqual(_ object: Any?) -> Bool {
        
        
        if let list = object as? List {
            if color != list.color {
                return false
            }
            
            return items == list.items
        }
        
        return false
    }

    // MARK: DebugPrintable

     override var debugDescription: String {
        return "{color: \(color), items: \(items)}"
    }
}
