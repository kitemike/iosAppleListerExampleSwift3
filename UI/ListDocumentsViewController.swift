//
//  ListDocumentsViewController.swift
//  ListerEssence
//
//  Created by Mike LeRoy on 10/5/16.
//  Copyright © 2016 www.BetterAtLifeForum.com. All rights reserved.
//

import UIKit

//class ListDocumentsViewController: UITableViewController, ListsControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate, WCSessionDelegate, SegueHandlerType {

class ListDocumentsViewController: UITableViewController, ListsControllerDelegate, SegueHandlerType {

    struct MainStoryboard {
        struct ViewControllerIdentifiers {
            static let listViewController = "listViewController"
            static let listViewNavigationController = "listViewNavigationController"
        }
        
        struct TableViewCellIdentifiers {
            static let listDocumentCell = "listDocumentCell"
        }
    }
    
    enum SegueIdentifier: String {
        case ShowNewListDocument
        case ShowListDocument
        case ShowListDocumentFromUserActivity
    }

    var listsController: ListsController! {
        didSet {
            listsController.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UIStoryboardSegue Handling
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueIdentifier = segueIdentifierForSegue(segue: segue)
        
        switch segueIdentifier {
        case .ShowNewListDocument:
            let newListDocumentController = segue.destination as! NewListDocumentController
            
            newListDocumentController.listsController = listsController
            
        case .ShowListDocument, .ShowListDocumentFromUserActivity:
            let listNavigationController = segue.destination as! UINavigationController
            let listViewController = listNavigationController.topViewController as! ListViewController
            listViewController.listsController = listsController
            
            listViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            listViewController.navigationItem.leftItemsSupplementBackButton = true
            
            if segueIdentifier == .ShowListDocument {
                let indexPath = tableView.indexPathForSelectedRow!
                listViewController.configureWithListInfo(aListInfo: listsController[indexPath.row])
            }
            else {
                let userActivityListInfo = sender as! ListInfo
                listViewController.configureWithListInfo(aListInfo: userActivityListInfo)
            }
        }
    }
    

}
///
extension ListDocumentsViewController {
    
    // MARK: ListsControllerDelegate
    
    func listsControllerWillChangeContent(listsController: ListsController) {
        tableView.beginUpdates()
    }
    
    func listsController(listsController: ListsController, didInsertListInfo listInfo: ListInfo, atIndex index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    func listsController(listsController: ListsController, didRemoveListInfo listInfo: ListInfo, atIndex index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    func listsController(listsController: ListsController, didUpdateListInfo listInfo: ListInfo, atIndex index: Int) {
        
        let indexPath = IndexPath(row: index, section: 0)
        
        tableView.reloadRows(at: [indexPath], with: .automatic)

    }
    
    func listsControllerDidChangeContent(listsController: ListsController) {
        tableView.endUpdates()
        
        // This method will handle interactions with the watch connectivity session on behalf of the app.
//        updateWatchConnectivitySessionApplicationContext()
    }
    
//    @objc optional 
//  func listsController(listsController: ListsController, didFailCreatingListInfo listInfo: ListInfo, withError error: Error)
    func listsController(listsController: ListsController, didFailCreatingListInfo listInfo: ListInfo, withError error: Error) {
        
        let title = NSLocalizedString("Failed to Create List", comment: "")
        let message = error.localizedDescription
        let okActionTitle = NSLocalizedString("OK", comment: "")
        
        let errorOutController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: okActionTitle, style: .cancel, handler: nil)
        errorOutController.addAction(action)
        
        present(errorOutController, animated: true, completion: nil)
    }
    
    func listsController(listsController: ListsController, didFailRemovingListInfo listInfo: ListInfo, withError error: Error) {
        let title = NSLocalizedString("Failed to Delete List", comment: "")
        let message = (error as NSError).localizedFailureReason
        let okActionTitle = NSLocalizedString("OK", comment: "")
        
        let errorOutController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: okActionTitle, style: .cancel, handler: nil)
        errorOutController.addAction(action)
        
        present(errorOutController, animated: true, completion: nil)
    }
}
    // MARK: UITableViewDataSource
    ///
extension ListDocumentsViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If the controller is nil, return no rows. Otherwise return the number of total rows.
        return listsController?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: MainStoryboard.TableViewCellIdentifiers.listDocumentCell, for: indexPath) as! ListCell
    }
    
    // MARK: UITableViewDelegate
    
//    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath) {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        switch cell {
        case let listCell as ListCell:
            let listInfo = listsController[indexPath.row]
            
            listCell.label.text = listInfo.name
            listCell.label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
            listCell.listColorView.backgroundColor = UIColor.clear
            
            // Once the list info has been loaded, update the associated cell's properties.
            listInfo.fetchInfoWithCompletionHandler {
                /*
                 The fetchInfoWithCompletionHandler(_:) method calls its completion handler on a background
                 queue, dispatch back to the main queue to make UI updates.
                 */
//                dispatch_async(dispatch_get_main_queue()) {
                DispatchQueue.main.async {
                    // Make sure that the list info is still visible once the color has been fetched.
                    guard let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows else { return }
                    
                    if indexPathsForVisibleRows.contains(indexPath) {
                        listCell.listColorView.backgroundColor = listInfo.color!.colorValue
                    }
                }
            }
        default:
            fatalError("Attempting to configure an unknown or unsupported cell type in ListDocumentViewController.")
        }
    }
    
//    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
//    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: IndexPath) -> Bool {
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }

}
