//
//  DCDirectoryWatcher.swift
//  DCDirectoryWatcherExample
//
//  Created by David Chavez on 2/11/15.
//  Copyright (c) 2015 David Chavez. All rights reserved.
//

import UIKit

public class DCDirectoryWatcher {
    public typealias CompletionClosure = () -> ()
    
    public var watchedPath: String!
    
    internal var source: dispatch_source_t!
    internal var queue: dispatch_queue_t = dispatch_queue_create("net.dchavez.dcdirectorywatcher", nil)
    internal var retriesLeft: Int!
    internal var directoryChanging: Bool = false
    internal var closure: CompletionClosure!
    
    // MARK: - Initializers
    
    init(path: String) {
        watchedPath = path
    }
    
    // MARK: - Class Methods
    
    class func watchDirectory(path: String, autoStart: Bool, completionClosure: CompletionClosure) -> DCDirectoryWatcher? {
        let directoryWatcher = DCDirectoryWatcher(path: path)
        directoryWatcher.closure = completionClosure
        
        if (autoStart) {
            if (!directoryWatcher.startWatching()) {
                // An error happened, return nil
                return nil
            }
        }
        
        return directoryWatcher
    }
    
    class func watchDirectory(path: String, completionClosure: CompletionClosure) -> DCDirectoryWatcher? {
        return DCDirectoryWatcher.watchDirectory(path, autoStart: true, completionClosure: completionClosure)
    }
    
    // MARK: - Public Methods
    
    public func stopWatching() -> Bool {
        if (source != nil) {
            dispatch_source_cancel(source)
            source = nil
            return true
        }
        
        return false
    }
    
    public func startWatching() -> Bool {
        if (source != nil) {
            return false
        }
        
        let fd = open(watchedPath.fileSystemRepresentation(), O_EVTONLY)
        
        if (fd < 0) {
            return false
        }
        
        func cleanup() -> Void {
            close(fd)
        }
        
        // Get a low priority queue
        var queueX = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
        
        // Monitor the directory for writes
        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, // Monitors a file descriptor
            UInt(fd), // our file descriptor
            DISPATCH_VNODE_WRITE, // The file-system object data changed.
            queueX) // the queue to dispatch on
        
        if (source == nil) {
            cleanup()
            return false
        }
        
        // Call directoryDidChange on event callback
        dispatch_source_set_event_handler(source, {
            self.directoryDidChange()
        })
        
        // Dispatch source destructor
        dispatch_source_set_cancel_handler(source, cleanup);
        
        // Sources are create in suspended state, so resume it
        dispatch_resume(source);
        
        // Everything was OK
        return true
    }
    
    // MARK: - Private Methods
    
    private func directoryMetadata() -> Array<String> {
        let fileManager = NSFileManager()
        let contents = fileManager.contentsOfDirectoryAtPath(watchedPath, error: nil)!
        
        var dm = Array<String>()
        
        for file in contents {
            autoreleasepool({
                let filePath = self.watchedPath.stringByAppendingPathComponent(file as String)
                let fileAttributes = NSFileManager.defaultManager().attributesOfItemAtPath(filePath, error: nil)
                
                let fileSize: Int = fileAttributes![NSFileSize] as Int
                let fileHash = String("\(file as String)\(fileSize)")
                
                dm.append(fileHash)
            })
        }
        
        return dm
    }
    
    private func pollDirectoryForChanges(odm: Array<String>) {
        let ndm = directoryMetadata()
        
        // Check if metadata has changed
        directoryChanging = !(ndm == odm)
        
        // Reset tries if it's still changing
        retriesLeft = (directoryChanging) ? 5 : retriesLeft
        
        if (directoryChanging || 0 < retriesLeft!--) {
            // Directory is changing or we should try again
            checkChangesAfterDelay(0.2)
        } else {
            // Changes seem to be done, post notification
            dispatch_async(dispatch_get_main_queue(), {
                self.closure()
            })
        }
    }
    
    private func checkChangesAfterDelay(delay: Double) {
        let dm = directoryMetadata()
        
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, queue, {
            self.pollDirectoryForChanges(dm)
        })
    }
    
    private func directoryDidChange() {
        if (!directoryChanging) {
            directoryChanging = true
            retriesLeft = 5
            
            checkChangesAfterDelay(0.2)
        }
    }
}