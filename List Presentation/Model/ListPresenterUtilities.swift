/*
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Helper functions to perform common operations in `IncompleteListItemsPresenter` and `AllListItemsPresenter`.
*/

import Foundation

/**
    Removes each list item found in `listItemsToRemove` from the `initialListItems` array. For each removal,
    the function notifies the `listPresenter`'s delegate of the change.
*/
func removeListItemsFromListItemsWithListPresenter(listPresenter: ListPresenterType, initialListItems: inout [ListItem], listItemsToRemove: [ListItem]) {
    let sortedListItemsToRemove = listItemsToRemove.sorted { initialListItems.index(of: $0)! > initialListItems.index(of: $1)! }
    
    for listItemToRemove in sortedListItemsToRemove {
        // Use the index of the list item to remove in the current list's list items.
        let indexOfListItemToRemoveInOldList = initialListItems.index(of: listItemToRemove)!
        
        initialListItems.remove(at: indexOfListItemToRemoveInOldList)
        
        listPresenter.delegate?.listPresenter(listPresenter:listPresenter, didRemoveListItem: listItemToRemove, atIndex: indexOfListItemToRemoveInOldList)
    }
}

/**
    Inserts each list item in `listItemsToInsert` into `initialListItems`. For each insertion, the function
    notifies the `listPresenter`'s delegate of the change.
*/
func insertListItemsIntoListItemsWithListPresenter(listPresenter: ListPresenterType, initialListItems: inout [ListItem], listItemsToInsert: [ListItem]) {
    for (idx, insertedIncompleteListItem) in listItemsToInsert.enumerated() {
        initialListItems.insert(insertedIncompleteListItem, at: idx)
        
        listPresenter.delegate?.listPresenter(listPresenter:listPresenter, didInsertListItem: insertedIncompleteListItem, atIndex: idx)
    }
}

/**
    Replaces the stale list items in `presentedListItems` with the new ones found in `newUpdatedListItems`. For
    each update, the function notifies the `listPresenter`'s delegate of the update.
*/
func updateListItemsWithListItemsForListPresenter(listPresenter: ListPresenterType, presentedListItems: inout [ListItem], newUpdatedListItems: [ListItem]) {
    for newlyUpdatedListItem in newUpdatedListItems {
        let indexOfListItem = presentedListItems.index(of: newlyUpdatedListItem)!
        
        presentedListItems[indexOfListItem] = newlyUpdatedListItem
        
        listPresenter.delegate?.listPresenter(listPresenter:listPresenter, didUpdateListItem: newlyUpdatedListItem, atIndex: indexOfListItem)
    }
}

/**
    Replaces `color` with `newColor` if the colors are different. If the colors are different, the function
    notifies the delegate of the updated color change. If `isForInitialLayout` is not `nil`, the function wraps
    the changes in a call to `listPresenterWillChangeListLayout(_:isInitialLayout:)`
    and a call to `listPresenterDidChangeListLayout(_:isInitialLayout:)` with the value `isForInitialLayout!`.
*/
func updateListColorForListPresenterIfDifferent(listPresenter: ListPresenterType, color: inout List.Color, newColor: List.Color, isForInitialLayout: Bool? = nil) {    
    // Don't trigger any updates if the new color is the same as the current color.
    if color == newColor { return }
    
    if isForInitialLayout != nil {
        listPresenter.delegate?.listPresenterWillChangeListLayout(listPresenter: listPresenter, isInitialLayout: isForInitialLayout!)
    }
    
    color = newColor
    
    listPresenter.delegate?.listPresenter(listPresenter: listPresenter, didUpdateListColorWithColor: newColor)
    
    if isForInitialLayout != nil {
        listPresenter.delegate?.listPresenterDidChangeListLayout(listPresenter: listPresenter, isInitialLayout: isForInitialLayout!)
    }
}
