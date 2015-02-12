[![Build Status](https://travis-ci.org/dchavezlive/DCDirectoryWatcher.svg)](https://travis-ci.org/dchavezlive/DCDirectoryWatcher)

# DCDirectoryWatcher
```DCDirectoryWatcher``` is a lightweight class the uses GCD to monitor directory changes. Once changes occur ```DCDirectoryWatcher``` will post a notification only after the changes have been completed.

### Installation
Copy ```DCDirectoryWatcher.swift``` into your project

### How to use
Fet an instance of ```DCDirectoryWatcher``` by using one of the class methods provided.
* ```DCDirectoryWatcher.watchDirectory(path: String, completionClosure: {})```
* ```DCDirectoryWatcher.watchDirectory(path: String, autoStart: Bool, completionClosure: {})```

The completion closure will be called once changes have been completed.

```Swift
self.directoryWatcher = DCDirectoryWatcher.watchDirectory(documentPath, completionClosure: {
    println("Directory changed!")
})
```

You may use ```stopWatching()``` or ```startWatching()``` to stop/start/resume 

===========
```DCDirectoryWatcher``` is a Swift port of ```MHWDirectoryWatcher```
