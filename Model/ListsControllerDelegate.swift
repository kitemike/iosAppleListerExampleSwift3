import Foundation

/**
 The `ListsControllerDelegate` protocol enables a `ListsController` object to notify other objects of changes
 to available `ListInfo` objects. This includes "will change content" events, "did change content"
 events, inserts, removes, updates, and errors. Note that the `ListsController` can call these methods
 on an aribitrary queue. If the implementation in these methods require UI manipulations, you should
 respond to the changes on the main queue.
 */
@objc  protocol ListsControllerDelegate {
    /**
     Notifies the receiver of this method that the lists controller will change it's contents in
     some form. This method is *always* called before any insert, remove, or update is received.
     In this method, you should prepare your UI for making any changes related to the changes
     that you will need to reflect once they are received. For example, if you have a table view
     in your UI that needs to respond to changes to a newly inserted `ListInfo` object, you would
     want to call your table view's `beginUpdates()` method. Once all of the updates are performed,
     your `listsControllerDidChangeContent(_:)` method will be called. This is where you would to call
     your table view's `endUpdates()` method.
     
     - parameter listsController: The `ListsController` instance that will change its content.
     */
    @objc optional func listsControllerWillChangeContent(listsController: ListsController)
    
    /**
     Notifies the receiver of this method that the lists controller is tracking a new `ListInfo`
     object. Receivers of this method should update their UI accordingly.
     
     - parameter listsController: The `ListsController` instance that inserted the new `ListInfo`.
     - parameter listInfo: The new `ListInfo` object that has been inserted at `index`.
     - parameter index: The index that `listInfo` was inserted at.
     */
    @objc optional func listsController(listsController: ListsController, didInsertListInfo listInfo: ListInfo, atIndex index: Int)
    
    /**
     Notifies the receiver of this method that the lists controller received a message that `listInfo`
     has updated its content. Receivers of this method should update their UI accordingly.
     
     - parameter listsController: The `ListsController` instance that was notified that `listInfo` has been updated.
     - parameter listInfo: The `ListInfo` object that has been updated.
     - parameter index: The index of `listInfo`, the updated `ListInfo`.
     */
    @objc optional func listsController(listsController: ListsController, didRemoveListInfo listInfo: ListInfo, atIndex index: Int)
    
    /**
     Notifies the receiver of this method that the lists controller is no longer tracking `listInfo`.
     Receivers of this method should update their UI accordingly.
     
     - parameter listsController: The `ListsController` instance that removed `listInfo`.
     - parameter listInfo: The removed `ListInfo` object.
     - parameter index: The index that `listInfo` was removed at.
     */
    @objc optional func listsController(listsController: ListsController, didUpdateListInfo listInfo: ListInfo, atIndex index: Int)
    
    /**
     Notifies the receiver of this method that the lists controller did change it's contents in
     some form. This method is *always* called after any insert, remove, or update is received.
     In this method, you should finish off changes to your UI that were related to any insert, remove,
     or update. For an example of how you might handle a "did change" contents call, see
     the discussion for `listsControllerWillChangeContent(_:)`.
     
     - parameter listsController: The `ListsController` instance that did change its content.
     */
    @objc optional func listsControllerDidChangeContent(listsController: ListsController)
    
    /**
     Notifies the receiver of this method that an error occured when creating a new `ListInfo` object.
     In implementing this method, you should present the error to the user. Do not rely on the
     `ListInfo` instance to be valid since an error occured in creating the object.
     
     - parameter listsController: The `ListsController` that is notifying that a failure occured.
     - parameter listInfo: The `ListInfo` that represents the list that couldn't be created.
     - parameter error: The error that occured.
     */
    @objc optional func listsController(listsController: ListsController, didFailCreatingListInfo listInfo: ListInfo, withError error: Error)
    
    /**
     Notifies the receiver of this method that an error occured when removing an existing `ListInfo`
     object. In implementing this method, you should present the error to the user.
     
     - parameter listsController: The `ListsController` that is notifying that a failure occured.
     - parameter listInfo: The `ListInfo` that represents the list that couldn't be removed.
     - parameter error: The error that occured.
     */
    @objc optional func listsController(listsController: ListsController, didFailRemovingListInfo listInfo: ListInfo, withError error: Error)
}

