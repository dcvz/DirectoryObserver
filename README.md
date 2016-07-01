 [![Build Status](https://travis-ci.org/dchavezlive/DCDirectoryWatcher.svg)](https://travis-ci.org/dchavezlive/DCDirectoryWatcher)

# DirectoryObserver
```DirectoryObserver``` is a microlibrary for monitoring directory changes using GCD.

### Installation
=======
#### Cocoapods
1. Add the pod DirectoryObserver to your Podfile.
    ```ruby
    pod 'DirectoryObserver'
    ```
2. Run `pod install` from Terminal, then open your app's `.xcworkspace` file to launch Xcode.

#### Manually
1. Download the source files in the [DirectoryObserver subdirectory](https://github.com/dcvz/DirectoryObserver/tree/master/DirectoryObserver/Classes).
2. Add the source files to your Xcode project.

### How to use
Get an instance of `DirectoryObserver` by either instantiation or using the extension method on `NSURL`:
* `DirectoryObserver(pathToWatch: NSURL, completion: () -> Void) -> DirectoryObserver`
* `NSURL.setupObserver() -> DirectoryObserver`

The completion closure will be called when changes are detected and have completed.

```swift
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
```

You may then use the `startObserving()` or `stopObserving()` methods to stop/start/resume observing.

===========
`DirectoryObserver` is a Swift port of `MHWDirectoryWatcher`
