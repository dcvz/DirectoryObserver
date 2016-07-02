//
//  NSURL+Observer.swift
//  DirectoryObserver
//
//  Created by David Chavez on 07/01/2016.
//  Copyright (c) 2016 David Chavez. All rights reserved.
//

import Foundation

public extension NSURL {

    /// Returns `DirectoryObserver` object
    public func setupObserver(callback: () -> Void) -> DirectoryObserver {
        return DirectoryObserver(pathToWatch: self, callback: callback)
    }
}
