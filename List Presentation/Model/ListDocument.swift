/*
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListDocument` class is a `UIDocument` subclass that represents a list. `ListDocument` manages the serialization / deserialization of the list object in addition to a list presenter.
*/

import UIKit
//import WatchConnectivity

/// Protocol that allows a list document to notify other objects of it being deleted.
@objc  protocol ListDocumentDelegate {
    func listDocumentWasDeleted(listDocument: ListDocument)
}

 class ListDocument: UIDocument {
    // MARK: Properties

     weak var delegate: ListDocumentDelegate?
    
    // Use a default, empty list.
     var listPresenter: ListPresenterType?

    // MARK: Initializers
    
     init(fileURL URL: URL, listPresenter: ListPresenterType? = nil) {
        self.listPresenter = listPresenter

        super.init(fileURL: URL)
    }

    // MARK: Serialization / Deserialization

//    override  func loadFromContents(contents: AnyObject, ofType typeName: String?) throws {
    override  func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let unarchivedList = NSKeyedUnarchiver.unarchiveObject(with: contents as! Data) as? List {
            /*
                This method is called on the queue that the `openWithCompletionHandler(_:)` method was called
                on (typically, the main queue). List presenter operations are main queue only, so explicitly
                call on the main queue.
            */
//            dispatch_async(dispatch_get_main_queue()) {
            DispatchQueue.main.async {
                self.listPresenter?.setList(list: unarchivedList)
                
                return
            }

            return
        }
        
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Could not read file", comment: "Read error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("File was in an invalid format", comment: "Read failure reason")
        ])
    }

//    override  func contentsForType(typeName: String) throws -> AnyObject {
    override  func contents(forType typeName: String) throws -> Any {
        if let archiveableList = listPresenter?.archiveableList {
            return NSKeyedArchiver.archivedData(withRootObject: archiveableList)
        }

        throw NSError(domain: "ListDocumentDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Could not archive list", comment: "Archive error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("No list presenter was available for the document", comment: "Archive failure reason")
        ])
    }
    
    // MARK: Saving
    
    override  func save(to url: URL, for saveOperation: UIDocumentSaveOperation, completionHandler: ((Bool) -> Void)?) {
        super.save(to: url, for: saveOperation) { success in
            // If `WCSession` isn't supported there is nothing else required.
            
//            guard WCSession.isSupported() else {
                completionHandler?(success)
                return
//            }
            
//            let session = WCSession.defaultSession()
//            
//            // Do not proceed if `session` is not currently `.Activated` or the watch app is not installed.
//            guard session.activationState == .Activated && session.watchAppInstalled else {
//                completionHandler?(success)
//                return
//            }
//            
//            // On a successful save, transfer the file to the paired watch if appropriate.
//            if success {
//                let fileCoordinator = NSFileCoordinator()
//                let readingIntent = NSFileAccessIntent.readingIntentWithURL(url, options: [])
//                fileCoordinator.coordinateAccessWithIntents([readingIntent], queue: NSOperationQueue()) { accessError in
//                    if accessError != nil {
//                        return
//                    }
//                    
//                    // Do not proceed if `session` is not currently `.Activated`.
//                    guard session.activationState == .Activated else { return }
//                    
//                    for transfer in session.outstandingFileTransfers {
//                        if transfer.file.fileURL == readingIntent.URL {
//                            transfer.cancel()
//                            break
//                        }
//                    }
//                    
//                    session.transferFile(readingIntent.URL, metadata: nil)
//                }
//            }
//            
//            completionHandler?(success)
        }
    }
    
    // MARK: Deletion

//    override  func accommodatePresentedItemDeletionWithCompletionHandler(completionHandler: Error? -> Void) {
    override  func accommodatePresentedItemDeletion(completionHandler: @escaping (Error?) -> Void) {
        super.accommodatePresentedItemDeletion(completionHandler: completionHandler)
        
        delegate?.listDocumentWasDeleted(listDocument: self)
    }
    
    // MARK: Handoff
    
    override  func updateUserActivityState(_ userActivity: NSUserActivity) {
        
        /*
 Updates the state of the given user activity.
 The default implementation of this method puts the document’s fileURL into the NSUserActivity object’s userInfo dictionary with the NSUserActivityDocumentURLKey. 
         UIDocument automatically sets the needsSave property of the NSUserActivity object to true when the fileURL changes.
 */
        
        super.updateUserActivityState(userActivity)
        
        if let rawColorValue = listPresenter?.color.rawValue {
            userActivity.addUserInfoEntries(from: [
                AppConfiguration.UserActivity.listColorUserInfoKey: rawColorValue
            ])
        }
    }
}
