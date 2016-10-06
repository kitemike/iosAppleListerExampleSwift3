/*
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListInfo` class is a caching abstraction over a `List` object that contains information about lists (e.g. color and name).
*/

import UIKit

 class ListInfo: NSObject {
    // MARK: Properties
    
    struct Constants {
        
        static let fetchQueueName = "com.example.apple-samplecode.listinfo"
    }

     let url: URL // lower case name to avoid name collisions with swift3
    
     var color: List.Color?

     var name: String {
        let displayName = FileManager.default.displayName(atPath: url.path)

        return (displayName as NSString).deletingPathExtension
    }

//    private let fetchQueue = dispatch_queue_create("com.example.apple-samplecode.listinfo", DISPATCH_QUEUE_SERIAL)
    private let fetchQueue = DispatchQueue(label: Constants.fetchQueueName) // serial by default

    // MARK: Initializers

     init(url: URL) {
        self.url = url
        
    }

    // MARK: Fetch Methods

     func fetchInfoWithCompletionHandler(completionHandler: @escaping (Void) -> Void) { //@escaping added by fix-it
        
//        dispatch_async(fetchQueue) {
        fetchQueue.async {
            // If the color hasn't been set yet, the info hasn't been fetched.
            if self.color != nil {
                completionHandler()
                
                return
            }
            
            ListUtilities.readListAtURL(url: self.url) { list, error in
                self.fetchQueue.async {
                    if let list = list {
                        self.color = list.color
                    }
                    else {
                        self.color = .Gray
                    }
                    
                    completionHandler()
                }
            }
        }
    }
    
    // MARK: NSObject
    
//    override  func isEqual(object: AnyObject?) -> Bool {
      override  func isEqual(_ object: Any?) -> Bool {

        if let listInfo = object as? ListInfo {
            return listInfo.url == url
        }

        return false
        /* Apple doc:
 There are two distinct types of comparison you can make between two objects in Swift. The first, equality (==), compares the contents of the objects. The second, identity (===), determines whether or not the constants or variables refer to the same object instance.
 
 Swift provides default implementations of the == and === operators and adopts the Equatable protocol for objects that derive from the NSObject class. The default implementation of the == operator invokes the isEqual: method, and the default implementation of the === operator checks pointer equality. You should not override the equality or identity operators for types imported from Objective-C.
 
 The base implementation of the isEqual: provided by the NSObject class is equivalent to an identity check by pointer equality. You can override isEqual: in a subclass to have Swift and Objective-C APIs determine equality based on the contents of objects rather than their identities. For more information about implementing comparison logic, see Object comparison in Cocoa Core Competencies.
 */
    }
}
