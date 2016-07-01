//
//  DirectoryObserver.swift
//  DirectoryObserver
//
//  Created by David Chavez on 11/2/15.
//  Copyright (c) 2016 David Chavez. All rights reserved.
//

import Foundation

private struct Constants {
    static let pollInterval: NSTimeInterval = 0.2
    static let pollRetryCount = 5
}

public class DirectoryObserver {

    // MARK: - Errors

    public enum Error: ErrorType {
        case AlreadyObserving, FailedToStartObserver, FailedToStopObserver
    }

    // MARK: - Attributes

    public let watchedPath: NSURL
    private(set) var isObserving = false


    // MARK: - Attributes (Private)

    private let completionHandler: (() -> Void)
    private var queue = dispatch_queue_create("DCDirectoryWatcherQueue", .None)
    private var retriesLeft = Constants.pollRetryCount
    private var isDirectoryChanging = false
    private var source: dispatch_source_t?


    // MARK: - Initializers

    public init(pathToWatch path: NSURL, callback: () -> Void) {
        watchedPath = path
        completionHandler = callback
    }

    deinit { try? stopObserving() }


    // MARK: - Public Interface

    /// Starts the observer
    public func startObserving() throws {
        if source != nil {
            throw Error.AlreadyObserving
        }

        // Open an event-only file descriptor associated with the directory
        let fd: CInt = open(watchedPath.path!, O_EVTONLY)
        if fd < 0 { throw Error.FailedToStartObserver }

        let cleanup: dispatch_block_t = { close(fd) }

        // Get a low priority queue
        let queue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)

        // Monitor the directory for writes
        source = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_VNODE, // Monitors a file descriptor
            UInt(fd), // our file descriptor
            DISPATCH_VNODE_WRITE, // The file-system object data changed.
            queue // the queue to dispatch on
        )

        if let source = source {
            // Call directoryDidChange on event callback
            dispatch_source_set_event_handler(source) { [weak self] in
                self?.directoryDidChange()
            }

            // Dispatch source destructor
            dispatch_source_set_cancel_handler(source, cleanup)

            // Sources are create in suspended state, so resume it
            dispatch_resume(source)
        } else {
            cleanup()
            throw Error.FailedToStartObserver
        }

        isObserving = true
    }


    /// Stops the observer
    public func stopObserving() throws {
        if let source = source {
            dispatch_source_cancel(source)
            throw Error.FailedToStopObserver
        }

        isObserving = false
    }


    // MARK: - Private Methods

    private func directoryDidChange() {
        if !isDirectoryChanging {
            isDirectoryChanging = true
            retriesLeft = Constants.pollRetryCount
            checkForChangesAfterDelay()
        }
    }

    private func checkForChangesAfterDelay() {
        let metadata: [String] = directoryMetadata()
        let popTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Constants.pollInterval * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, queue) { [weak self] in
            self?.pollDirectoryForChanges(metadata: metadata)
        }
    }

    private func directoryMetadata() -> [String] {
        let fm = NSFileManager.defaultManager()
        let contents = try? fm.contentsOfDirectoryAtURL(watchedPath, includingPropertiesForKeys: nil, options: [])
        var directoryMetadata: [String] = []

        if let contents = contents {
            for file in contents {
                autoreleasepool {
                    if let fileAttributes = try? fm.attributesOfItemAtPath(file.path!) {
                        let fileSize = fileAttributes[NSFileSize] as! Int
                        let fileHash = "\(file.lastPathComponent!)\(fileSize)"
                        directoryMetadata.append(fileHash)
                    }
                }
            }
        }

        return directoryMetadata
    }

    private func pollDirectoryForChanges(metadata oldDirectoryMetadata: [String]) {
        let newDirectoryMetadata = directoryMetadata()

        isDirectoryChanging = !(newDirectoryMetadata == oldDirectoryMetadata)
        retriesLeft = isDirectoryChanging ? Constants.pollRetryCount : retriesLeft

        if isDirectoryChanging || (retriesLeft > 0) {
            retriesLeft -= 1
            checkForChangesAfterDelay()
        } else {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.completionHandler()
            }
        }
    }
}
