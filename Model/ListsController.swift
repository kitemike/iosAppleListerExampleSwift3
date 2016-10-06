/*
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListsController` and `ListsControllerDelegate` infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to `ListInfo` objects. In addition, it also provides a way for parts of the application to present errors that occured when creating or removing lists.
*/

import Foundation

/**
    The `ListsController` class is responsible for tracking `ListInfo` objects that are found through
    lists controller's `ListCoordinator` object. `ListCoordinator` objects are responsible for notifying
    the lists controller of inserts, removes, updates, and errors when interacting with a list's URL.
    Since the work of searching, removing, inserting, and updating `ListInfo` objects is done by the list
    controller's coordinator, the lists controller serves as a way to avoid the need to interact with a single
    `ListCoordinator` directly throughout the application. It also allows the rest of the application
    to deal with `ListInfo` objects rather than dealing with their `URL` instances directly. In essence,
    the work of a lists controller is to "front" its current coordinator. All changes that the coordinator
    relays to the `ListsController` object will be relayed to the lists controller's delegate. This ability to
    front another object is particularly useful when the underlying coordinator changes. As an example,
    this could happen when the user changes their storage option from using local documents to using
    cloud documents. If the coordinator property of the lists controller changes, other objects throughout
    the application are unaffected since the lists controller will notify them of the appropriate
    changes (removes, inserts, etc.).
*/
final  class ListsController: NSObject, ListCoordinatorDelegate {
    // MARK: Properties

    /// The `ListsController`'s delegate who is responsible for responding to `ListsController` updates.
     weak var delegate: ListsControllerDelegate?
    
    /// - returns:  The number of tracked `ListInfo` objects.
     var count: Int {
        var listInfosCount: Int!

        listInfoQueue.sync {
            listInfosCount = self.listInfos.count
        }

        return listInfosCount
    }

    /// The current `ListCoordinator` that the lists controller manages.
     var listCoordinator: ListCoordinator {
        didSet(oldListCoordinator) {
            oldListCoordinator.stopQuery()
            
            // Map the listInfo objects protected by listInfoQueue.
            var allURLs: [URL]!
            listInfoQueue.sync {
                allURLs = self.listInfos.map { $0.url }
            }
            self.processContentChanges(insertedURLs: [], removedURLs: allURLs, updatedURLs: [])
            
            self.listCoordinator.delegate = self
            oldListCoordinator.delegate = nil
            
            self.listCoordinator.startQuery()
        }
    }
    
    /// A URL for the directory containing documents within the application's container.
     var documentsDirectory: URL {
        return listCoordinator.documentsDirectory
    }

    /**
        The `ListInfo` objects that are cached by the `ListsController` to allow for users of the
        `ListsController` class to easily subscript the controller.
    */
    private var listInfos = [ListInfo]()
    
    /**
        - returns: A private, local queue to the `ListsController` that is used to perform updates on
                 `listInfos`.
    */
//    private let listInfoQueue = dispatch_queue_create("com.example.apple-samplecode.lister.listscontroller", DISPATCH_QUEUE_SERIAL)
    private let listInfoQueue = DispatchQueue(label: "com.example.apple-samplecode.lister.listscontroller")
    
    /**
        The sort predicate that's set in initialization. The sort predicate ensures a strict sort ordering
        of the `listInfos` array. If `sortPredicate` is nil, the sort order is ignored.
    */
    private let sortPredicate: ((_ lhs: ListInfo, _ rhs: ListInfo) -> Bool)?
    
    /// The queue on which the `ListsController` object invokes delegate messages.
    private var delegateQueue: OperationQueue

    // MARK: Initializers
    
    /**
        Initializes a `ListsController` instance with an initial `ListCoordinator` object and a sort
        predicate (if any). If no sort predicate is provided, the controller ignores sort order.

        - parameter listCoordinator: The `ListsController`'s initial `ListCoordinator`.
        - parameter delegateQueue: The queue on which the `ListsController` object invokes delegate messages.
        - parameter sortPredicate: The predicate that determines the strict sort ordering of the `listInfos` array.
    */
     init(listCoordinator: ListCoordinator, delegateQueue: OperationQueue, sortPredicate: ((_ lhs: ListInfo, _ rhs: ListInfo) -> Bool)? = nil) {
        self.listCoordinator = listCoordinator
        self.delegateQueue = delegateQueue
        self.sortPredicate = sortPredicate

        super.init()

        self.listCoordinator.delegate = self
    }
    
    // MARK: Subscripts
    
    /**
        - returns:  The `ListInfo` instance at a specific index. This method traps if the index is out
                  of bounds.
    */
     subscript(idx: Int) -> ListInfo {
        // Fetch the appropriate list info protected by `listInfoQueue`.
        var listInfo: ListInfo!

        listInfoQueue.sync {
            listInfo = self.listInfos[idx]
        }

        return listInfo
    }
    
    // MARK: Convenience
    
    /**
        Begin listening for changes to the tracked `ListInfo` objects. This is managed by the `listCoordinator`
        object. Be sure to balance each call to `startSearching()` with a call to `stopSearching()`.
     */
     func startSearching() {
        listCoordinator.startQuery()
    }
    
    /**
        Stop listening for changes to the tracked `ListInfo` objects. This is managed by the `listCoordinator`
        object. Each call to `startSearching()` should be balanced with a call to this method.
     */
     func stopSearching() {
        listCoordinator.stopQuery()
    }
    
    // MARK: Inserting / Removing / Managing / Updating `ListInfo` Objects
    
    /**
        Removes `listInfo` from the tracked `ListInfo` instances. This method forwards the remove
        operation directly to the list coordinator. The operation can be performed asynchronously
        so long as the underlying `ListCoordinator` instance sends the `ListsController` the correct
        delegate messages: either a `listCoordinatorDidUpdateContents(insertedURLs:removedURLs:updatedURLs:)`
        call with the removed `ListInfo` object, or with an error callback.
    
        - parameter listInfo: The `ListInfo` to remove from the list of tracked `ListInfo` instances.
    */
     func removeListInfo(listInfo: ListInfo) {
        listCoordinator.removeListAtURL(URL: listInfo.url)
    }
    
    /**
        Attempts to create `ListInfo` representing `list` with the given name. If the method is succesful,
        the lists controller adds it to the list of tracked `ListInfo` instances. This method forwards
        the create operation directly to the list coordinator. The operation can be performed asynchronously
        so long as the underlying `ListCoordinator` instance sends the `ListsController` the correct
        delegate messages: either a `listCoordinatorDidUpdateContents(insertedURLs:removedURLs:updatedURLs:)`
        call with the newly inserted `ListInfo`, or with an error callback.

        Note: it's important that before calling this method, a call to `canCreateListWithName(_:)`
        is performed to make sure that the name is a valid list name. Doing so will decrease the errors
        that you see when you actually create a list.

        - parameter list: The `List` object that should be used to save the initial list.
        - parameter name: The name of the new list.
    */
     func createListInfoForList(list: List, withName name: String) {
        listCoordinator.createURLForList(list: list, withName: name)
    }
    
    /**
        Determines whether or not a list can be created with a given name. This method delegates to
        `listCoordinator` to actually check to see if the list can be created with the given name. This
        method should be called before `createListInfoForList(_:withName:)` is called to ensure to minimize
        the number of errors that can occur when creating a list.

        - parameter name: The name to check to see if it's valid or not.
        
        - returns:  `true` if the list can be created with the given name, `false` otherwise.
    */
     func canCreateListInfoWithName(name: String) -> Bool {
        return listCoordinator.canCreateListWithName(name: name)
    }
    
    /**
        Attempts to copy a `list` at a given `URL` to the appropriate location in the documents directory.
        This method forwards to `listCoordinator` to actually perform the document copy.
        
        - parameter URL: The `URL` object representing the list to be copied.
        - parameter name: The name of the `list` to be overwritten.
    */
     func copyListFromURL(URL: URL, toListWithName name: String) {
        listCoordinator.copyListFromURL(URL: URL, toListWithName: name)
    }
    
    /**
        Lets the `ListsController` know that `listInfo` has been udpdated. Once the change is reflected
        in `listInfos` array, a didUpdateListInfo message is sent.
        
        - parameter listInfo: The `ListInfo` instance that has new content.
    */
     func setListInfoHasNewContents(listInfo: ListInfo) {
//        dispatch_async(listInfoQueue) {
        listInfoQueue.async {
            // Remove the old list info and replace it with the new one.
            let indexOfListInfo = self.listInfos.index(of: listInfo)!

            self.listInfos[indexOfListInfo] = listInfo

            if let delegate = self.delegate {
                self.delegateQueue.addOperation {
                    delegate.listsControllerWillChangeContent?(listsController: self)
                    delegate.listsController?(listsController: self, didUpdateListInfo: listInfo, atIndex: indexOfListInfo)
                    delegate.listsControllerDidChangeContent?(listsController: self)
                }
            }
        }
    }

    // MARK: ListCoordinatorDelegate
    
    /**
        Receives changes from `listCoordinator` about inserted, removed, and/or updated `ListInfo`
        objects. When any of these changes occurs, these changes are processed and forwarded along
        to the `ListsController` object's delegate. This implementation determines where each of these
        URLs were located so that the controller can forward the new / removed / updated indexes
        as well. For more information about this method, see the method description for this method
        in the `ListCoordinator` class.

        - parameter insertedURLs: The `URL` instances that should be tracekd.
        - parameter removedURLs: The `URL` instances that should be untracked.
        - parameter updatedURLs: The `URL` instances that have had their underlying model updated.
    */
     func listCoordinatorDidUpdateContents(_ insertedURLs: [URL], removedURLs: [URL], updatedURLs: [URL]) {
        processContentChanges(insertedURLs: insertedURLs, removedURLs: removedURLs, updatedURLs: updatedURLs)
    }
    
    /**
        Forwards the "create" error from the `ListCoordinator` to the `ListsControllerDelegate`. For more
        information about when this method can be called, see the description for this method in the
        `ListCoordinatorDelegate` protocol description.
        
        - parameter URL: The `URL` instances that was failed to be created.
        - parameter error: The error the describes why the create failed.
    */
     func listCoordinatorDidFailCreatingListAtURL(URL: URL, withError error: Error) {
        let listInfo = ListInfo(url: URL)
        
        delegateQueue.addOperation {
            self.delegate?.listsController?(listsController: self, didFailCreatingListInfo: listInfo, withError: error)
            
            return
        }
    }
    
    /**
        Forwards the "remove" error from the `ListCoordinator` to the `ListsControllerDelegate`. For
        more information about when this method can be called, see the description for this method in
        the `ListCoordinatorDelegate` protocol description.
        
        - parameter URL: The `URL` instance that failed to be removed
        - parameter error: The error that describes why the remove failed.
    */
     func listCoordinatorDidFailRemovingListAtURL(URL: URL, withError error: Error) {
        let listInfo = ListInfo(url: URL)
        
        delegateQueue.addOperation {
            self.delegate?.listsController?(listsController: self, didFailRemovingListInfo: listInfo, withError: error)
            
            return
        }
    }
    
    // MARK: Change Processing
    
    /**
        Processes changes to the `ListsController` object's `ListInfo` collection. This implementation
        performs the updates and determines where each of these URLs were located so that the controller can 
        forward the new / removed / updated indexes as well.
    
        - parameter insertedURLs: The `URL` instances that are newly tracked.
        - parameter removedURLs: The `URL` instances that have just been untracked.
        - parameter updatedURLs: The `URL` instances that have had their underlying model updated.
    */
//    private func processContentChanges(insertedURLs insertedURLs: [URL], removedURLs: [URL], updatedURLs: [URL]) {
        private func processContentChanges(insertedURLs: [URL], removedURLs: [URL], updatedURLs: [URL]) {
        let insertedListInfos = insertedURLs.map { ListInfo(url: $0) }
        let removedListInfos = removedURLs.map { ListInfo(url: $0) }
        let updatedListInfos = updatedURLs.map { ListInfo(url: $0) }
        
        delegateQueue.addOperation {
            // Filter out all lists that are already included in the tracked lists.
            var trackedRemovedListInfos: [ListInfo]!
            var untrackedInsertedListInfos: [ListInfo]!
            
            self.listInfoQueue.sync {
                trackedRemovedListInfos = removedListInfos.filter { self.listInfos.contains($0) }
                untrackedInsertedListInfos = insertedListInfos.filter { !self.listInfos.contains($0) }
            }
            
            if untrackedInsertedListInfos.isEmpty && trackedRemovedListInfos.isEmpty && updatedListInfos.isEmpty {
                return
            }
            
            self.delegate?.listsControllerWillChangeContent?(listsController: self)
            
            // Remove
            for trackedRemovedListInfo in trackedRemovedListInfos {
                var trackedRemovedListInfoIndex: Int!
                
                self.listInfoQueue.sync {
                    trackedRemovedListInfoIndex = self.listInfos.index(of: trackedRemovedListInfo)!
                    
                    self.listInfos.remove(at: trackedRemovedListInfoIndex)
                }
                
                self.delegate?.listsController?(listsController: self, didRemoveListInfo: trackedRemovedListInfo, atIndex: trackedRemovedListInfoIndex)
            }

            // Sort the untracked inserted list infos
            if let sortPredicate = self.sortPredicate {
                untrackedInsertedListInfos.sort(by: sortPredicate)
            }
            
            // Insert
            for untrackedInsertedListInfo in untrackedInsertedListInfos {
                var untrackedInsertedListInfoIndex: Int!
                
                self.listInfoQueue.sync {
                    self.listInfos += [untrackedInsertedListInfo]
                    
                    if let sortPredicate = self.sortPredicate {
                        self.listInfos.sort(by: sortPredicate)
                    }
                    
                    untrackedInsertedListInfoIndex = self.listInfos.index(of: untrackedInsertedListInfo)!
                }
                
                self.delegate?.listsController?(listsController: self, didInsertListInfo: untrackedInsertedListInfo, atIndex: untrackedInsertedListInfoIndex)
            }
            
            // Update
            for updatedListInfo in updatedListInfos {
                var updatedListInfoIndex: Int?
                
                self.listInfoQueue.sync {
                    updatedListInfoIndex = self.listInfos.index(of: updatedListInfo)
                    
                    // Track the new list info instead of the old one.
                    if let updatedListInfoIndex = updatedListInfoIndex {
                        self.listInfos[updatedListInfoIndex] = updatedListInfo
                    }
                }
                
                if let updatedListInfoIndex = updatedListInfoIndex {
                    self.delegate?.listsController?(listsController: self, didUpdateListInfo: updatedListInfo, atIndex: updatedListInfoIndex)
                }
            }
            
            self.delegate?.listsControllerDidChangeContent?(listsController: self)
        }
    }
}
