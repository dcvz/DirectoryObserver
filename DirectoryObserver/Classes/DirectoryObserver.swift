//
//  DirectoryObserver.swift
//  DirectoryObserver
//
//  Created by David Chavez on 11/2/15.
//  Copyright (c) 2016 David Chavez. All rights reserved.
//

import Foundation

private struct Constants {
    static let pollInterval = 0.2
    static let pollRetryCount = 5
}

public class DirectoryObserver {

    // MARK: - Errors

    public enum Error: ErrorProtocol {
        case AlreadyObserving, FailedToStartObserver, FailedToStopObserver, InvalidPath
    }

    // MARK: - Attributes

    public let watchedPath: URL
    private(set) var isObserving = false


    // MARK: - Attributes (Private)

    private let completionHandler: (() -> Void)
    private var queue = DispatchQueue(label: "directory_observer_queue")
    private var retriesLeft = Constants.pollRetryCount
    private var isDirectoryChanging = false
    private var source: DispatchSourceFileSystemObject?


    // MARK: - Initializers

    public init(pathToWatch path: URL, callback: () -> Void) {
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

        guard let path = watchedPath.path else {
            throw Error.InvalidPath
        }

        // Open an event-only file descriptor associated with the directory
        let fd: CInt = open(watchedPath.path!, O_EVTONLY)
        if fd < 0 { throw Error.FailedToStartObserver }

        let cleanup: () -> Void = { close(fd) }

        // Get a low priority queue
        let queue = DispatchQueue.global(attributes: [.priorityLow])

        // Monitor the directory for writes
        source = DispatchSource.fileSystemObject(fileDescriptor: fd, eventMask: .write, queue: queue)

        // Call directoryDidChange on event callback
        source!.setEventHandler() { [weak self] in
            self?.directoryDidChange()
        }

        // Dispatch source destructor
        source!.setCancelHandler(handler: cleanup)

        // Sources are create in suspended state, so resume it
        source!.resume()
        isObserving = true
    }


    /// Stops the observer
    public func stopObserving() {
        if source != nil {
            source!.cancel()
            source = nil
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
        queue.after(when: DispatchTime.now() + Constants.pollInterval) { [weak self] in
            self?.pollDirectoryForChanges(metadata: metadata)
        }
    }

    private func directoryMetadata() -> [String] {
        let fm = FileManager.default()
        let contents = try? fm.contentsOfDirectory(at: watchedPath, includingPropertiesForKeys: nil, options: [])
        var directoryMetadata: [String] = []

        if let contents = contents {
            for file in contents {
                autoreleasepool {
                    if let fileAttributes = try? fm.attributesOfItem(atPath: file.path!) {
                        let fileSize = fileAttributes[FileAttributeKey.size.rawValue] as! Int
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
            DispatchQueue.main.async() { [weak self] in
                self?.completionHandler()
            }
        }
    }
}
