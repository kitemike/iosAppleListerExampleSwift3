/*
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListUtilities` class provides a suite of convenience methods for interacting with `List` objects and their associated files.
*/

import Foundation

/// An internal queue to the `ListUtilities` class that is used for `NSFileCoordinator` callbacks.
//private var listUtilitiesQueue: NSOperationQueue = {
//    let queue = NSOperationQueue()
//    queue.maxConcurrentOperationCount = 1
//    
//    return queue
//}()
private var listUtilitiesQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    
    return queue
}()

 class ListUtilities {
    // MARK: Properties

    struct Constants {
        static let PrivateVarDir = "/private" // Constants.PrivateVarDir
        
    }
    

     class var localDocumentsDirectory: URL  {
//        let documentsURL = sharedApplicationGroupContainer.appendingPathComponent("Documents", isDirectory: true)
//        do {
//            // This will throw if the directory cannot be successfully created, or does not already exist.
//            try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
//            
//            return documentsURL
//        }
//        catch let error  {
//            fatalError("The shared application group documents directory doesn't exist and could not be created. Error: \(error.localizedDescription)")
//        }
        
        if AppConfiguration.isSimulator {
            
            print("===> localDocumentsDirectory using AppConfiguration.isSimulator")
            
            return localDocumentsDirectoryVarRootDir // for simulatore
        } else {
            return localDocumentsDirectoryWithPrivateRootDir //for iPHone
        }
    }
    
    class var localDocumentsDirectoryVarRootDir: URL // for xcode simulator
    {
        let url:URL =  try! FileManager().url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: true)
        
        return url
    }
    
    
    class var localDocumentsDirectoryWithPrivateRootDir: URL // for device
    {
        var url:URL =  try! FileManager().url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: true)
        // this works on iphone, but not simulator
        var dir:String = url.path
        if !dir.hasPrefix(Constants.PrivateVarDir) {
            
            dir = Constants.PrivateVarDir + dir
            url = URL(fileURLWithPath: dir, isDirectory: true)
        }
        
        return url
    }
    

    
    private class var sharedApplicationGroupContainer: URL {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfiguration.ApplicationGroups.primary)

        if containerURL == nil {
            fatalError("The shared application group container is unavailable. Check your entitlements and provisioning profiles for this target. Details on proper setup can be found in the PDFs referenced from the README.")
        }
        
        return containerURL!
    }
    
    // MARK: List Handling Methods
    
     class func copyInitialLists() {
        let defaultListURLs = Bundle.main.urls(forResourcesWithExtension: AppConfiguration.appFileExtension, subdirectory: "")!
        
        for url in defaultListURLs {
            copyURLToDocumentsDirectory(url: url)
        }
    }
    
//     class func copyTodayList() {
//        let url = Bundle.main.url(forResource: AppConfiguration.localizedTodayDocumentName, withExtension: AppConfiguration.appFileExtension)!
//        copyURLToDocumentsDirectory(url: url)
//    }

     class func migrateLocalListsToCloud() {
//        let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let defaultQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)

//        dispatch_async(defaultQueue) {
        defaultQueue.async {
            let fileManager = FileManager.default
            
            // Note the call to URLForUbiquityContainerIdentifier(_:) should be on a background queue.
            if let cloudDirectoryURL = fileManager.url(forUbiquityContainerIdentifier: nil) {
                let documentsDirectoryURL = cloudDirectoryURL.appendingPathComponent("Documents")
                
                do {
                    let localDocumentURLs = try fileManager.contentsOfDirectory(at: ListUtilities.localDocumentsDirectory, includingPropertiesForKeys: nil, options: .skipsPackageDescendants)
                
                    for URL in localDocumentURLs {
                        if URL.pathExtension == AppConfiguration.appFileExtension {
                            self.makeItemUbiquitousAtURL(sourceURL: URL, documentsDirectoryURL: documentsDirectoryURL)
                        }
                    }
                }
                catch let error {
                    print("The contents of the local documents directory could not be accessed. Error: \(error.localizedDescription)")
                }
//                // Requiring an additional catch to satisfy exhaustivity is a known issue.
//                catch {}
            }
        }
    }
    
    // MARK: Convenience
    
    private class func makeItemUbiquitousAtURL(sourceURL: URL, documentsDirectoryURL: URL) {
        let destinationFileName = sourceURL.lastPathComponent
        
        let fileManager = FileManager()
        let destinationURL = documentsDirectoryURL.appendingPathComponent(destinationFileName)
        
        if fileManager.isUbiquitousItem(at: destinationURL) ||
            fileManager.fileExists(atPath: destinationURL.path) {
            // If the file already exists in the cloud, remove the local version and return.
            removeListAtURL(url: sourceURL, completionHandler: nil)
            return
        }
        
//        let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let defaultQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        
//        dispatch_async(defaultQueue) {
        defaultQueue.async {
            do {
                try fileManager.setUbiquitous(true, itemAt: sourceURL, destinationURL: destinationURL)
                return
            }
            catch let error  {
                print("Failed to make list ubiquitous. Error: \(error.localizedDescription)")
            }
//            // Requiring an additional catch to satisfy exhaustivity is a known issue.
//            catch {}
        }
    }

     class func readListAtURL(url: URL, completionHandler: @escaping (List?, Error?) -> Void) {
        let fileCoordinator = NSFileCoordinator()
        
        // `url` may be a security scoped resource.
        let successfulSecurityScopedResourceAccess = url.startAccessingSecurityScopedResource()
        
        let readingIntent = NSFileAccessIntent.readingIntent(with: url, options: .withoutChanges)
        fileCoordinator.coordinate(with: [readingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                if successfulSecurityScopedResourceAccess {
                    url.stopAccessingSecurityScopedResource()
                }
                
                completionHandler(nil, accessError)
                
                return
            }
            
            // Local variables that will be used as parameters to `completionHandler`.
            var deserializedList: List?
            var readError: Error?
            
            do {
//                let contents = try Data(contentsOfURL: readingIntent.URL, options: .DataReadingUncached)
                let contents = try Data(contentsOf: readingIntent.url, options: Data.ReadingOptions.uncached)
                deserializedList = NSKeyedUnarchiver.unarchiveObject(with: contents) as? List
                
                assert(deserializedList != nil, "The provided URL must correspond to a `List` object.")
            }
            catch let error  {
                readError = error as Error
            }
//            // Requiring an additional catch to satisfy exhaustivity is a known issue.
//            catch {}

            if successfulSecurityScopedResourceAccess {
                url.stopAccessingSecurityScopedResource()
            }
            
            completionHandler(deserializedList, readError)
        }
    }

     class func createList(list: List, atURL url: URL, completionHandler: ((Error?) -> Void)? = nil) {
        
        let fileCoordinator = NSFileCoordinator()
        
        let writingIntent = NSFileAccessIntent.writingIntent(with: url, options: .forReplacing)
        fileCoordinator.coordinate(with: [writingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                completionHandler?(accessError)
                
                return
            }
            
            var writeError: Error?

            let seralizedListData = NSKeyedArchiver.archivedData(withRootObject: list)
            
            do {
//                try seralizedListData.writeToURL(writingIntent.URL, options: .DataWritingAtomic)
                try seralizedListData.write(to: writingIntent.url, options: Data.WritingOptions.atomic)
            
                let fileAttributes = [FileAttributeKey.extensionHidden: true]
                
                try FileManager.default.setAttributes(fileAttributes, ofItemAtPath: writingIntent.url.path)
            }
            catch let error  {
                writeError = error
            }
//            // Requiring an additional catch to satisfy exhaustivity is a known issue.
//            catch {}
            
            completionHandler?(writeError)
        }
    }
    
    class func removeListAtURL(url: URL, completionHandler: ((Error?) -> Void)? = nil) {
        let fileCoordinator = NSFileCoordinator()
        
        // `url` may be a security scoped resource.
        let successfulSecurityScopedResourceAccess = url.startAccessingSecurityScopedResource()

        let writingIntent = NSFileAccessIntent.writingIntent(with: url, options: .forDeleting)
        fileCoordinator.coordinate(with: [writingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                completionHandler?(accessError)
                
                return
            }
            
            let fileManager = FileManager()
            
            var removeError: Error?
            
            do {
                try fileManager.removeItem(at: writingIntent.url)
            }
            catch let error  {
                removeError = error
            }
//            // Requiring an additional catch to satisfy exhaustivity is a known issue.
//            catch {}
            
            if successfulSecurityScopedResourceAccess {
                url.stopAccessingSecurityScopedResource()
            }

            completionHandler?(removeError)
        }
    }
    
    // MARK: Convenience
    
    private class func copyURLToDocumentsDirectory(url: URL) {
        let toURL = ListUtilities.localDocumentsDirectory.appendingPathComponent(url.lastPathComponent)
        
        print("===> copy file: \(toURL)")
        
        if FileManager().fileExists(atPath: toURL.path) {
            // If the file already exists, don't attempt to copy the version from the bundle.
            return
        }
        
        copyFromURL(fromURL: url, toURL: toURL)
    }
    
     class func copyFromURL(fromURL: URL, toURL: URL) {
        let fileCoordinator = NSFileCoordinator()
        
        // `url` may be a security scoped resource.
        let successfulSecurityScopedResourceAccess = fromURL.startAccessingSecurityScopedResource()
        
        let fileManager = FileManager()
        
        // First copy the source file into a temporary location where the replace can be carried out.
        var tempDirectory: URL?
        var tempURL: URL?
        do {
            tempDirectory = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: toURL, create: true)
            tempURL = tempDirectory!.appendingPathComponent(toURL.lastPathComponent)
            try fileManager.copyItem(at: fromURL, to: tempURL!)
        }
        catch let error  {
            // An error occured when moving `url` to `toURL`. In your app, handle this gracefully.
            print("Couldn't create temp file from: \(fromURL) at: \(tempURL) error: \(error.localizedDescription).")
            print("Error\nCode: \((error as NSError).code)\nDomain: \((error as NSError).domain)\nDescription: \(error.localizedDescription)\nReason: \((error as NSError).localizedFailureReason)\nUser Info: \((error as NSError).userInfo)\n")
            
            return
        }

        // Now perform a coordinated replace to move the file from the temporary location to its final destination.
        let movingIntent = NSFileAccessIntent.writingIntent(with: tempURL!, options: .forMoving)
        let mergingIntent = NSFileAccessIntent.writingIntent(with: toURL, options: .forMerging)
        fileCoordinator.coordinate(with: [movingIntent, mergingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                print("Couldn't move file: \(fromURL.absoluteString) to: \(toURL.absoluteString) error: \(accessError!.localizedDescription).")
                return
            }
            
            do {
//                try Data(contentsOfURL: movingIntent.URL, options: []).writeToURL(mergingIntent.URL, atomically: true)
                try Data(contentsOf: movingIntent.url, options: []).write(to: mergingIntent.url, options: Data.WritingOptions.atomic)
                
                let fileAttributes = [FileAttributeKey.extensionHidden: true]
                
                try fileManager.setAttributes(fileAttributes, ofItemAtPath: mergingIntent.url.path)
            }
            catch let error  {
                // An error occured when moving `url` to `toURL`. In your app, handle this gracefully.
                print("Couldn't move file: \(fromURL) to: \(toURL) error: \(error.localizedDescription).")
                print("Error\nCode: \((error as NSError).code)\nDomain: \((error as NSError).domain)\nDescription: \((error as NSError).localizedDescription)\nReason: \((error as NSError).localizedFailureReason)\nUser Info: \((error as NSError).userInfo)\n")
            }
//            // Requiring an additional catch to satisfy exhaustivity is a known issue.
//            catch {}
            
            if successfulSecurityScopedResourceAccess {
                fromURL.stopAccessingSecurityScopedResource()
            }
            
            // Cleanup
            guard let directoryToRemove = tempDirectory else { return }
            do {
                try fileManager.removeItem(at: directoryToRemove)
            }
            catch {}
        }
    }
}
