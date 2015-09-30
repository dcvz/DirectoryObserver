//
//  ViewController.swift
//  DCDirectoryWatcherExample
//
//  Created by David Chavez on 2/11/15.
//  Copyright (c) 2015 David Chavez. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let directory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let directoryWatcher = DCDirectoryWatcher.watchDirectory(directory, completionClosure: {
            println("Directory changed!")
        })
        println("Watching '\(directory)'.")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

