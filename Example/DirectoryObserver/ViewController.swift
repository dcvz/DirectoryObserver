//
//  ViewController.swift
//  DirectoryObserver
//
//  Created by David Chavez on 07/01/2016.
//  Copyright (c) 2016 David Chavez. All rights reserved.
//

import UIKit
import DirectoryObserver

class ViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var statusLabel: UILabel!


    // MARK: - Attributes

    private(set) var directoryWatcher: DirectoryObserver!


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let fileManager = NSFileManager.defaultManager()
        let directory = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!

        directoryWatcher = DirectoryObserver(pathToWatch: directory) {
            print("Directory contents have changed")
        }

        /*
        // added method on `NSURL` directly -- equivalent to example above
        directoryWatcher = directory.setupObserver() {
            print("Directory contents have changed")
        }
        */
    }


    // MARK: - IBOutlets

    @IBAction func startWatching(sender: AnyObject) {
        do {
            try directoryWatcher.startObserving()
            statusLabel.text = "Observing"
        } catch {
            print(error)
        }
    }

    @IBAction func stopWatching(sender: AnyObject) {
        do {
            try directoryWatcher.stopObserving()
            statusLabel.text = ""
        } catch {
            print(error)
        }
    }
}
