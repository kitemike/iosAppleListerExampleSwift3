/*
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Handles application configuration logic and information.
*/

import Foundation

 typealias StorageState = (storageOption: AppConfiguration.Storage, accountDidChange: Bool, cloudAvailable: Bool)

 class AppConfiguration {
    
    /*
     The value of the `LISTER_BUNDLE_PREFIX` user-defined build setting is written to the Info.plist file of
     every target in Swift version of the Lister project. Specifically, the value of `LISTER_BUNDLE_PREFIX`
     is used as the string value for a key of `AAPLListerBundlePrefix`. This value is loaded from the target's
     bundle by the lazily evaluated static variable "prefix" from the nested "Bundle" struct below the first
     time that "Bundle.prefix" is accessed. This avoids the need for developers to edit both `LISTER_BUNDLE_PREFIX`
     and the code below.
     
     The value of `Bundle.prefix` is then used as part of an interpolated string to insert
     the user-defined value of `LISTER_BUNDLE_PREFIX` into several static string constants below.
     */
    private struct AppBundle {
        //        static var prefix = Bundle.main.object(forInfoDictionaryKey: "AAPLListerBundlePrefix") as! String
        static var prefix = "com.visualjudgment.BetterAtLife" // replace with your ID
    }

    enum Storage: Int {
        case NotSet = 0, Local, Cloud
    }
    
    class var sharedConfiguration: AppConfiguration {
        struct Singleton {
            static let sharedAppConfiguration = AppConfiguration()
        }
        
        return Singleton.sharedAppConfiguration
        // Needed by: configureListsController(), didFinishLaunchingWithOptions()
    }

    class var isSimulator: Bool {
        return true // need better fix to resolve file path between iphone and simulator
    }

     class var appFileExtension: String {
        return "list"
    }

    // See ListDocument.updateUserActivityState() for file save. Keys used to store relevant list data in the userInfo dictionary of an NSUserActivity for continuation.
    struct UserActivity {
        // The editing user activity is integrated into the ubiquitous UI/NSDocument architecture.
        static let editing = "com.example.apple-samplecode.Lister.editing"
        
        // The watch user activity is used to continue activities started on the watch on other devices.
        static let watch = "com.example.apple-samplecode.Lister.watch"
        
        // The user info key used for storing the list path for use in transition from glance -> app on the watch.
        static var listURLPathUserInfoKey = "listURLPathUserInfoKey"
        
        // The user info key used for storing the list color for use in transition from glance -> app on the watch.
        static var listColorUserInfoKey = "listColorUserInfoKey"
    }

  
    struct ApplicationGroups {
        static let primary = "group.\(AppBundle.prefix).Lister.Documents"
    }
    
    private var applicationUserDefaults: UserDefaults {
        return UserDefaults(suiteName: ApplicationGroups.primary)!
    }

    private(set) var isFirstLaunch: Bool {
        get {
            registerDefaults()
            
            return applicationUserDefaults.bool(forKey: Defaults.firstLaunchKey)
        }
        set {
            applicationUserDefaults.set(newValue, forKey: Defaults.firstLaunchKey)
        }
    }
    
    private struct Defaults {
        static let firstLaunchKey = "AppConfiguration.Defaults.firstLaunchKey"
        static let storageOptionKey = "AppConfiguration.Defaults.storageOptionKey"
        static let storedUbiquityIdentityToken = "AppConfiguration.Defaults.storedUbiquityIdentityToken"
    }
    
    var storageState: StorageState {
        return (storageOption, hasAccountChanged(), isCloudAvailable)
    }
    
    var storageOption: Storage {
        get {
            let value = applicationUserDefaults.integer(forKey: Defaults.storageOptionKey)
            
            return Storage(rawValue: value)!
        }
        
        set {
            applicationUserDefaults.set(newValue.rawValue, forKey: Defaults.storageOptionKey)
        }
    }

    var isCloudAvailable: Bool {
        
        assertionFailure() // removed for simiplicity
        return false
        return FileManager.default.ubiquityIdentityToken != nil
    }

    func hasAccountChanged() -> Bool {
        let hasChanged = false
        
        assertionFailure() // defer
        
        //        let currentToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? = FileManager.default.ubiquityIdentityToken
        //        let storedToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? = storedUbiquityIdentityToken
        //
        //
        //        let currentTokenNilStoredNonNil = currentToken == nil && storedToken != nil
        //        let storedTokenNilCurrentNonNil = currentToken != nil && storedToken == nil
        //
        //        // Compare the tokens.
        ////        let currentNotEqualStored = currentToken != nil && storedToken != nil && !currentToken!.isEqual(storedToken!)
        //        let currentNotEqualStored = currentToken != nil && storedToken != nil && !currentToken.isEqual(storedToken)
        //
        //        if currentTokenNilStoredNonNil || storedTokenNilCurrentNonNil || currentNotEqualStored {
        //            persistAccount()
        //            
        //            hasChanged = true
        //        }
        
        return hasChanged
    }

    private func registerDefaults() {
        
            //            let defaultOptions: [String: AnyObject] = [
            let defaultOptions: [String: Any] = [
                Defaults.firstLaunchKey: true,
                Defaults.storageOptionKey: Storage.NotSet.rawValue
            ]
        
        applicationUserDefaults.register(defaults: defaultOptions)
    }
    
    /**
     Returns a `ListsController` instance based on the current configuration. For example, if the user has
     chosen local storage, a `ListsController` object will be returned that uses a local list coordinator.
     `pathExtension` is passed down to the list coordinator to filter results.
     */
    func listsControllerForCurrentConfigurationWithPathExtension(pathExtension: String, firstQueryHandler: ((Void) -> Void)? = nil) -> ListsController {
        let listCoordinator = listCoordinatorForCurrentConfigurationWithPathExtension(pathExtension: pathExtension, firstQueryHandler: firstQueryHandler)
        
        return ListsController(listCoordinator: listCoordinator, delegateQueue: OperationQueue.main) { lhs, rhs in
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == ComparisonResult.orderedAscending
        }
    }
    
    /**
     Returns a `ListCoordinator` based on the current configuration that queries based on `pathExtension`.
     For example, if the user has chosen local storage, a local `ListCoordinator` object will be returned.
     */
    func listCoordinatorForCurrentConfigurationWithPathExtension(pathExtension: String, firstQueryHandler: ((Void) -> Void)? = nil) -> ListCoordinator {
        
        let opt = AppConfiguration.sharedConfiguration.storageOption
        if opt == .NotSet || opt == .Local {
            // ok. Cloud not supported.
        } else {
            assertionFailure()
            // This will be called if the storage option is either `.Local` or `.NotSet`.
        }
        return LocalListCoordinator(pathExtension: pathExtension, firstQueryUpdateHandler: firstQueryHandler)
        
        //        else {
        ////            return CloudListCoordinator(pathExtension: pathExtension, firstQueryUpdateHandler: firstQueryHandler)
        //        }
    }
    


    func runHandlerOnFirstLaunch(firstLaunchHandler: (Void) -> Void) {
        if isFirstLaunch {
            isFirstLaunch = false
            
            firstLaunchHandler()
        }
    }

    /*
     // MARK: Types
     

     
    // Keys used to store information in a WCSession context.
     struct ApplicationActivityContext {
         static let currentListsKey = "ListerCurrentLists"
         static let listNameKey = "name"
         static let listColorKey = "color"
    }
    
    // Constants used in assembling and handling the custom lister:// URL scheme.
     struct ListerScheme {
        // The scheme name used for encoding the list when transitioning from today -> app on iOS.
         static var name = "lister"
        // The query key used for encoding the list color when transitioning from today -> app on iOS.
         static var colorQueryKey = "color"
    }
    

    #if os(OSX)
     struct App {
         static let bundleIdentifier = "\(Bundle.prefix).ListerOSX"
    }
    #endif
    
     struct Extensions {
        #if os(iOS)
         static let widgetBundleIdentifier = "\(AppBundle.prefix).Lister.ListerToday"
        #elseif os(OSX)
         static let widgetBundleIdentifier = "\(AppBundle.prefix).Lister.ListerTodayOSX"
        #endif
    }
    
    
     class var listerUTI: String {
        return "com.example.apple-samplecode.Lister"
    }
    
     class var listerFileExtension: String {
        return "list"
    }
    
     class var defaultListerDraftName: String {
        return NSLocalizedString("List", comment: "")
    }
    
     class var localizedTodayDocumentName: String {
        return NSLocalizedString("Today", comment: "The name of the Today list")
    }
    
     class var localizedTodayDocumentNameAndExtension: String {
        return "\(localizedTodayDocumentName).\(listerFileExtension)"
    }
    
    
    
     
    
    #if os(iOS)

    // MARK: Ubiquity Identity Token Handling (Account Change Info)
    
 
    private func persistAccount() {
        let defaults = applicationUserDefaults
        
        if let token = FileManager.default.ubiquityIdentityToken {
            let ubiquityIdentityTokenArchive = NSKeyedArchiver.archivedData(withRootObject: token)
            
            defaults.set(ubiquityIdentityTokenArchive, forKey: Defaults.storedUbiquityIdentityToken)
        }
        else {
            defaults.removeObject(forKey: Defaults.storedUbiquityIdentityToken)
        }
    }
    
    // MARK: Convenience

    private var storedUbiquityIdentityToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? {
        
        assertionFailure() // defer
        return nil
        
//        var storedToken: protocol<NSCoding, NSCopying, NSObjectProtocol>?
//        
//        // Determine if the logged in iCloud account has changed since the user last launched the app.
//        //        let archivedObject: AnyObject? = applicationUserDefaults.object(forKey: Defaults.storedUbiquityIdentityToken)
//        let archivedObject: Any? = applicationUserDefaults.object(forKey: Defaults.storedUbiquityIdentityToken)
//        
//        if let ubiquityIdentityTokenArchive = archivedObject as? Data,
//            let archivedObject = NSKeyedUnarchiver.unarchiveObject(with: ubiquityIdentityTokenArchive) as? protocol<NSCoding, NSCopying, NSObjectProtocol> {
//            storedToken = archivedObject
//        }
//        
//        return storedToken
    }
    
      /**
        Returns a `ListCoordinator` based on the current configuration that queries based on `lastPathComponent`.
        For example, if the user has chosen local storage, a local `ListCoordinator` object will be returned.
    */
     func listCoordinatorForCurrentConfigurationWithLastPathComponent(lastPathComponent: String, firstQueryHandler: ((Void) -> Void)? = nil) -> ListCoordinator {
        if AppConfiguration.sharedConfiguration.storageOption != .Cloud {
            // This will be called if the storage option is either `.Local` or `.NotSet`.
            assertionFailure()
        }
        
        return LocalListCoordinator(lastPathComponent: lastPathComponent, firstQueryUpdateHandler: firstQueryHandler)

//        else {
////            return CloudListCoordinator(lastPathComponent: lastPathComponent, firstQueryUpdateHandler: firstQueryHandler)
//        }
    }
    
  
    /**
        Returns a `ListsController` instance based on the current configuration. For example, if the user has
        chosen local storage, a `ListsController` object will be returned that uses a local list coordinator.
        `lastPathComponent` is passed down to the list coordinator to filter results.
    */
     func listsControllerForCurrentConfigurationWithLastPathComponent(lastPathComponent: String, firstQueryHandler: ((Void) -> Void)? = nil) -> ListsController {
        let listCoordinator = listCoordinatorForCurrentConfigurationWithLastPathComponent(lastPathComponent: lastPathComponent, firstQueryHandler: firstQueryHandler)
        
        return ListsController(listCoordinator: listCoordinator, delegateQueue: OperationQueue.main) { lhs, rhs in
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == ComparisonResult.orderedAscending
        }
    }
    
    #endif
    
    */
 } // end class
