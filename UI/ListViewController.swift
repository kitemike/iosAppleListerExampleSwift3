//
//  ListViewController.swift
//  ListerEssence
//
//  Created by Mike LeRoy on 10/5/16.
//  Copyright © 2016 www.BetterAtLifeForum.com. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController, UITextFieldDelegate, ListColorCellDelegate, ListDocumentDelegate, ListPresenterDelegate {

    struct MainStoryboard {
        struct TableViewCellIdentifiers {
            // Used for normal items and the add item cell.
            static let listItemCell = "listItemCell"
            
            // Used in edit mode to allow the user to change colors.
            static let listColorCell = "listColorCell"
        }
    }
    
    // MARK: Properties
    
    var listsController: ListsController!
    
    /// Set in `textFieldDidBeginEditing(_:)`. `nil` otherwise.
    weak var activeTextField: UITextField?
    
    /// Set in `configureWithListInfo(_:)`. `nil` otherwise.
    var listInfo: ListInfo?
    
    var document: ListDocument! {
        didSet {
            if document == nil { return }
            
            document.delegate = self
            
            listPresenter.undoManager = document.undoManager
            
            listPresenter.delegate = self
        }
    }
    
    // Provide the document's undoManager property as the default NSUndoManager for this UIViewController.
    override var undoManager: UndoManager? {
        return document?.undoManager
    }
    
    var listPresenter: AllListItemsPresenter! {
        return document.listPresenter as? AllListItemsPresenter
    }
    
    var documentURL: URL {
        return document.fileURL
    }
    
    // Return the toolbar items since they are used in edit mode.
    var listToolbarItems: [UIBarButtonItem] {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let title = NSLocalizedString("Delete List", comment: "The title of the button to delete the current list.")
        let deleteList = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(ListViewController.deleteList(_:)))
        deleteList.tintColor = UIColor.red
        
//        if documentURL.lastPathComponent == AppConfiguration.localizedTodayDocumentNameAndExtension {
//            deleteList.isEnabled = false
//        }
        
        return [flexibleSpace, deleteList, flexibleSpace]
    }
    
    var textAttributes = [String: AnyObject]() {
        didSet {
            if isViewLoaded {
                updateInterfaceWithTextAttributes()
            }
        }
    }
    
    func triggerSave() {
        
        // The document infrastructure needs to be updated to capture the list's color when it changes.
        if let userActivity = self.document.userActivity {
            self.document.updateUserActivityState(userActivity)
        } else {
            
            self.document.updateChangeCount(UIDocumentChangeKind.done)
        }
    }

    // MARK: ListColorCellDelegate
    
    func listColorCellDidChangeSelectedColor(listColorCell: ListColorCell) {
        listPresenter.color = listColorCell.selectedColor
    }

    // MARK: IBActions
    
    @IBAction func deleteList(_: UIBarButtonItem) {
        listsController.removeListInfo(listInfo: listInfo!)
        
        hideViewControllerAfterListWasDeleted()
    }
    
    @IBAction func checkBoxTapped(sender: CheckBox) {
        let indexPath = indexPathForView(view: sender)!
        
        // Check to see if the tapped row is within the list item rows.
        if 1...listPresenter.count ~= indexPath.row {
            let listItem = listPresenter.presentedListItems[indexPath.row - 1]
            
            listPresenter.toggleListItem(listItem: listItem)
        }
    }
    
    // MARK: ListDocumentDelegate
    
    func listDocumentWasDeleted(listDocument: ListDocument) {
        hideViewControllerAfterListWasDeleted()
    }
    
    // Return `true` to indicate that we want to handle undo events through the responder chain.
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 44.0
        
        updateInterfaceWithTextAttributes()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        document.open { success in
            if !success {
                // In your app, handle this gracefully.
                print("Couldn't open document: \(self.documentURL).")
                
                abort()
            }
            
            self.textAttributes = [
                NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline),
                NSForegroundColorAttributeName: self.listPresenter.color.colorValue
            ]
            
            /*
             When the document is opened, make sure that the document stores its extra metadata in the `userInfo`
             dictionary. See `ListDocument`'s `updateUserActivityState(_:)` method for more information.
             */
            if let userActivity = self.document.userActivity {
                self.document.updateUserActivityState(userActivity)
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        
//        func handleDocumentStateChangedNotification(notification: NSNotification) {
        NotificationCenter.default.addObserver(self, selector: #selector(ListViewController.handleDocumentStateChangedNotification(notification:)), name: NSNotification.Name.UIDocumentStateChanged, object: document)
    }
    
    // Become first responder after the view appears so that we can respond to undo events.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _ = becomeFirstResponder()
        
        // If available, obtain a reference to the 'newItemCell` and make its `textField` the first responder.
        let newItemIndexPath = IndexPath(row: 0, section: 0)
        guard let newItemCell = tableView.cellForRow(at: newItemIndexPath) as? ListItemCell else { return }
        
        newItemCell.textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Resign as first responder after its view disappears to stop handling undo events.
        resignFirstResponder()
        
        document.delegate = nil
        document.close(completionHandler: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDocumentStateChanged, object: document)
        
        // Hide the toolbar so the list can't be edited.
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    

}
///
extension ListViewController { // ListPresenterDelegate
    
    // MARK: ListPresenterDelegate
    
    func listPresenterDidRefreshCompleteLayout(listPresenter _: ListPresenterType) {
        
        // called by AllListItemsPresenter.setList()
        
        // Updating `textAttributes` will updated the color for the items in the interface.
        textAttributes = [
            NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline),
            NSForegroundColorAttributeName: listPresenter.color.colorValue
        ]
        
        tableView.reloadData()
    }
    
    func listPresenterWillChangeListLayout(listPresenter _: ListPresenterType, isInitialLayout: Bool) {
        
        // called by textFieldDidEndEditing()

        tableView.beginUpdates()
    }
    
//    func listPresenter(listPresenter: ListPresenterType, didInsertListItem listItem: ListItem, atIndex index: Int)
    func listPresenter(listPresenter _: ListPresenterType, didInsertListItem listItem: ListItem, atIndex index: Int) {
        
        // called by textFieldDidEndEditing() to add a row

        let indexPathsForInsertion = [IndexPath(row: index + 1, section: 0)]
        
        tableView.insertRows(at: indexPathsForInsertion, with: .fade)
        
        // Reload the ListItemCell to be configured for the row to create a new list item.
        if index == 0 {
            let indexPathsForReloading = [IndexPath(row: 0, section: 0)]
            
            tableView.reloadRows(at: indexPathsForReloading, with: .automatic)
        }
    }
    
    func listPresenter(listPresenter _: ListPresenterType, didRemoveListItem listItem: ListItem, atIndex index: Int) {
        
        // called by tableView.commit()

        let indexPaths = [IndexPath(row: index + 1, section: 0)]
        
        tableView.deleteRows(at: indexPaths, with: .automatic)
    }
    
    func listPresenter(listPresenter _: ListPresenterType, didUpdateListItem listItem: ListItem, atIndex index: Int) {
        
        // called by textFieldDidEndEditing() to modify text

        tableView.endUpdates()
        
        tableView.beginUpdates()
        
        let indexPath = IndexPath(row: index + 1, section: 0)
        
        if let listItemCell = tableView.cellForRow(at: indexPath) as? ListItemCell {
            configureListItemCell(listItemCell: listItemCell, forRow: index + 1)
        }
    }
    
    func listPresenter(listPresenter _: ListPresenterType, didMoveListItem listItem: ListItem, fromIndex: Int, toIndex: Int) {
        
        // called by moveRowAt()

        let fromIndexPath = IndexPath(row: fromIndex + 1, section: 0)
        
        let toIndexPath = IndexPath(row: toIndex + 1, section: 0)
        
        tableView.moveRow(at: fromIndexPath, to: toIndexPath)
    }
    
    func listPresenter(listPresenter _: ListPresenterType, didUpdateListColorWithColor color: List.Color) {
        
        // Updating `textAttributes` will updated the color for the items in the interface.
        textAttributes = [
            NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline),
            NSForegroundColorAttributeName: color.colorValue
        ]
        
        triggerSave()
    }
    
    func listPresenterDidChangeListLayout(listPresenter _: ListPresenterType, isInitialLayout: Bool) {
        
        
        tableView.endUpdates()
    }
    
}
///
extension ListViewController {
    
    // MARK: Convenience
    
    func updateInterfaceWithTextAttributes() {
        let controller = navigationController?.navigationController ?? navigationController!
        
        controller.navigationBar.titleTextAttributes = textAttributes
        controller.navigationBar.tintColor = textAttributes[NSForegroundColorAttributeName] as! UIColor
        controller.toolbar?.tintColor = textAttributes[NSForegroundColorAttributeName] as! UIColor
        
        tableView.tintColor = textAttributes[NSForegroundColorAttributeName] as! UIColor
    }
    
    func hideViewControllerAfterListWasDeleted() {
        if splitViewController != nil && splitViewController!.isCollapsed {
            let controller = navigationController?.navigationController ?? navigationController!
            controller.popViewController(animated: true)
        }
        else {
            let emptyViewController = storyboard?.instantiateViewController(withIdentifier: AppDelegate.MainStoryboard.Identifiers.emptyViewController) as! UINavigationController
            emptyViewController.topViewController?.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            
            let masterViewController = splitViewController?.viewControllers.first! as! UINavigationController
            splitViewController?.viewControllers = [masterViewController, emptyViewController]
        }
    }
    
    func configureListItemCell(listItemCell: ListItemCell, forRow row: Int) {
//        listItemCell.checkBox.isChecked = false
//        listItemCell.checkBox.isHidden = false
        
        listItemCell.textField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        listItemCell.textField.delegate = self
        listItemCell.textField.textColor = UIColor.darkText
        listItemCell.textField.isEnabled = true
        
        if row == 0 {
            // Configure an "Add Item" list item cell.
            listItemCell.textField.placeholder = NSLocalizedString("Add Item", comment: "")
            listItemCell.textField.text = ""
//            listItemCell.checkBox.isHidden = true
        }
        else {
            let listItem = listPresenter.presentedListItems[row - 1]
            
            listItemCell.isComplete = listItem.isComplete
            listItemCell.textField.text = listItem.text
        }
    }
    
//    func triggerNewDataForWidget() {
//        if document.localizedName == AppConfiguration.localizedTodayDocumentName {
//            NCWidgetController.widgetController().setHasContent(true, forWidgetWithBundleIdentifier: AppConfiguration.Extensions.widgetBundleIdentifier)
//        }
//    }
    
    func resolveConflicts() {
        
        assertionFailure()
        /*
         Any automatic merging logic or presentation of conflict resolution UI should go here.
         For Lister we'll pick the current version and mark the conflict versions as resolved.
         */
//        do {
//            try NSFileVersion.removeOtherVersionsOfItemAtURL(documentURL)
//            
//            let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItemAtURL(documentURL)!
//            
//            for fileVersion in conflictVersions {
//                fileVersion.resolved = true
//            }
//        }
//            // Any encountered errors are swallowed, handle this appropriately in your own apps.
//        catch {}
    }
    
    func indexPathForView(view: UIView) -> IndexPath? {
        let viewOrigin = view.bounds.origin
        
        let viewLocation = tableView.convert(viewOrigin, from: view)
        
        return tableView.indexPathForRow(at: viewLocation)
    }

}
/// 
extension ListViewController {
    
    // MARK: View Life Cycle
    
     // MARK: Setup
    
    func configureWithListInfo(aListInfo: ListInfo) {
        listInfo = aListInfo
        
        let listPresenter = AllListItemsPresenter()
        document = ListDocument(fileURL: aListInfo.url, listPresenter: listPresenter)
        
        navigationItem.title = aListInfo.name
        
        textAttributes = [
            NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline),
            NSForegroundColorAttributeName: aListInfo.color?.colorValue ?? List.Color.Gray.colorValue
        ]
    }
    
    // MARK: Notifications
    
    func handleDocumentStateChangedNotification(notification: NSNotification) {
        if document.documentState.contains(.inConflict) {
            resolveConflicts()
        }
        
        // In order to update the UI, dispatch back to the main queue as there are no promises about the queue this will be called on.
//        dispatch_async(dispatch_get_main_queue(), tableView.reloadData)
        DispatchQueue.main.async {
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: UIViewController Overrides
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // Prevent navigating back in edit mode.
        navigationItem.setHidesBackButton(editing, animated: animated)
        
        // Make sure to resign first responder on the active text field if needed.
        activeTextField?.endEditing(false)
        
        // Reload the first row to switch from "Add Item" to "Change Color".
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        // If moving out of edit mode, notify observers about the list color and trigger a save.
        if !editing {
            // If the list info doesn't already exist (but it should), then create a new one.
            listInfo = listInfo ?? ListInfo(url: documentURL)
            
            listInfo!.color = listPresenter.color
            
            listsController!.setListInfoHasNewContents(listInfo: listInfo!)
            
//            triggerNewDataForWidget()
            
//            triggerSave()
        }
        
        navigationController?.setToolbarHidden(!editing, animated: animated)
        navigationController?.toolbar?.setItems(listToolbarItems, animated: animated)
    }
}
///
extension ListViewController {

    // MARK: UITableViewDataSource
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Don't show anything if the document hasn't been loaded.
        if document == nil {
            return 0
        }
        
        // Show the items in a list, plus a separate row that lets users enter a new item.
        return listPresenter.count + 1
    }
    
//  override func tableView(_: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier: String
        
        // Show the "color selection" cell if in edit mode.
        if isEditing && indexPath.row == 0 {
            identifier = MainStoryboard.TableViewCellIdentifiers.listColorCell
        }
        else {
            identifier = MainStoryboard.TableViewCellIdentifiers.listItemCell
        }
        
        return tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath as IndexPath)
    }
    
//    override func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        // The initial row is reserved for adding new items so it can't be deleted or edited.
        if indexPath.row == 0 {
            return false
        }
        
        return true
    }
    
//    override func tableView(_: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // The initial row is reserved for adding new items so it can't be moved.
        if indexPath.row == 0 {
            return false
        }
        
        return true
    }
    
//    override func tableView(_: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete {
            return
        }
        
        let listItem = listPresenter.presentedListItems[indexPath.row - 1]
        
        listPresenter.removeListItem(listItem: listItem)
        
        triggerSave()
    }
    
//    override func tableView(_: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let listItem = listPresenter.presentedListItems[sourceIndexPath.row - 1]
        
        // `toIndexPath.row` will never be `0` since we don't allow moving to the zeroth row (it's the color selection row).
//        listPresenter.moveListItem(listItem: listItem, toIndex: toIndexPath.row - 1)
        listPresenter.moveListItem(listItem: listItem, toIndex: destinationIndexPath.row - 1)
        
        triggerSave()
    }
    
    // MARK: UITableViewDelegate
    
//    override func tableView(_: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch cell {
        case let colorCell as ListColorCell:
            colorCell.configure()
            colorCell.selectedColor = listPresenter.color
            colorCell.delegate = self
            
        case let itemCell as ListItemCell:
            configureListItemCell(listItemCell: itemCell, forRow: indexPath.row)
            
        default:
            fatalError("Attempting to configure an unknown or unsupported cell type in `ListViewController`.")
        }
    }
    
//    override func tableView(_: UITableView, willBeginEditingRowAtIndexPath: NSIndexPath) {
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        /*
         When the user swipes to show the delete confirmation, don't enter editing mode.
         `UITableViewController` enters editing mode by default so we override without calling super.
         */
    }
    
//    override func tableView(_: UITableView, didEndEditingRowAtIndexPath: NSIndexPath) {
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        /*
         When the user swipes to hide the delete confirmation, no need to exit edit mode because we didn't
         enter it. `UITableViewController` enters editing mode by default so we override without calling
         super.
         */
    }
    
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
//    override func tableView(_: UITableView, targetIndexPathForMoveFromRowAtIndexPath fromIndexPath: NSIndexPath, toProposedIndexPath proposedIndexPath: NSIndexPath) -> NSIndexPath {
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let listItem = listPresenter.presentedListItems[sourceIndexPath.row - 1]
        
        if proposedDestinationIndexPath.row == 0 {
            return sourceIndexPath
        }
        else if listPresenter.canMoveListItem(listItem: listItem, toIndex: proposedDestinationIndexPath.row - 1) {
            return proposedDestinationIndexPath
        }
        
        return sourceIndexPath
}
}
///
extension ListViewController {
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        defer {
            activeTextField = nil
        }
        
        guard let text = textField.text else { return }
        
        let indexPath = indexPathForView(view: textField)
        
        if indexPath != nil && indexPath!.row > 0 {
            let listItem = listPresenter.presentedListItems[indexPath!.row - 1]
            
            listPresenter.updateListItem(listItem: listItem, withText: text)
        }
        else if !text.isEmpty {
            let listItem = ListItem(text: text)
            
            listPresenter.insertListItem(listItem: listItem)
        }
        
        triggerSave()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let indexPath = indexPathForView(view: textField)!
        
        // The 'add item' row can always dismiss the keyboard.
        if indexPath.row == 0 {
            textField.resignFirstResponder()
            
            return true
        }
        
        // An item must have text to dismiss the keyboard.
        guard let text = textField.text , !text.isEmpty else { return false }
        
        textField.resignFirstResponder()
        
        return true
    }

}













































