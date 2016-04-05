//
//  UpdateManager.swift
//  Model Boiler
//
//  Created by Kasper Welner on 26/08/15.
//  Copyright © 2015 Nodes. All rights reserved.
//

import Cocoa
import ZipArchive

public class UpdateManager: NSObject {

    static let sharedInstance = UpdateManager()

    let repoPath     = "repos/nodes-ios/ModelBoiler/"
    let downloadName = "Model.Boiler.app.zip"

    var updateTimer: NSTimer?
    private override init() { }

    public static func start() {
        sharedInstance.start()
    }

    public func start() {
        // Schedule update timer for every hour
        checkForUpdates()
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(3600, target: self, selector: #selector(UpdateManager.autoUpdateTimerFired), userInfo: nil, repeats: true)
    }

    public static func stop() {
        sharedInstance.stop()
    }

    public func stop() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func autoUpdateTimerFired() {
        checkForUpdates(showAlerts: false)
    }

    public func checkForUpdates(showAlerts showAlerts: Bool = true) {
        guard let request = NSMutableURLRequest.requestForGithubWithPath(repoPath + "releases") else {
            return
        }

        let session = NSURLSession.sharedSession()

        // Start the request with completion handler
        session.dataTaskWithRequest(request, completionHandler: {
            data, response, error in

            // If error happened
            if let error = error {
                NSUserNotification.display(title: "Update check failed", andMessage: "\(error)")
                return
            }

            // Guard for data
            guard let data = data else {
                NSUserNotification.display(
                    title: "Update check failed",
                    andMessage: "No version data received.")
                return
            }

            do {
                // Try to parse json
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))

                // Convert to dictionary and compare versions
                if let releases = json as? [[String : AnyObject]], latest = releases.first {
                    self.evaluateReleaseAndDownloadIfNeeded(latest, showAlerts: showAlerts)
                } else {
                    NSUserNotification.display(
                        title: "Update check failed",
                        andMessage: "JSON parsing failed. Unknown error.")
                }
            } catch {
                NSUserNotification.display(
                    title: "Update check failed",
                    andMessage: "JSON parsing failed. \(error)")
            }

        }).resume()
    }

    // MARK: - Private -

    private func evaluateReleaseAndDownloadIfNeeded(release: [String: AnyObject], showAlerts: Bool) {
        let failureAction = {
            NSUserNotification.display(
                title: "Update check failed",
                andMessage: "Couldn't get version numbers.")
        }

        guard let releaseVersion = release["tag_name"] as? String else { failureAction(); return }
        guard let currentVersion = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String else { failureAction(); return }

        // Compare version numbers
        if releaseVersion.isBiggerThanVersion(currentVersion) {
            let url = getReleaseDownloadURL(release)
            guard let releaseURL = url else {
                NSUserNotification.display(
                    title: "Update check failed",
                    andMessage: "Couldn't get new version executable.")
                return
            }

            NSUserNotification.display(
                title: "Update found (version \(releaseVersion))!",
                andMessage: "Download will start shortly.")

            downloadZipFileFromURL(releaseURL)
        } else {
            if showAlerts {
                NSUserNotification.display(
                    title: "Up to date",
                    andMessage: "You are using the latest version.")
            }
        }
    }

    private func getReleaseDownloadURL(release: [String: AnyObject]) -> NSURL? {
        guard let assets = release["assets"] as? [[String: AnyObject]] else { return nil }
        for asset in assets {
            guard let name = asset["name"] as? String else { continue }
            if let URLString = asset["browser_download_url"] as? String where name == downloadName {
                return NSURL(string: URLString)
            }
        }
        return nil
    }

    private func downloadZipFileFromURL(releaseURL: NSURL) {
        let request = NSURLRequest(URL: releaseURL)
        let session = NSURLSession.sharedSession()

        session.downloadTaskWithRequest(request, completionHandler: {
            downloadedFileURL, response, error in

            // If error happened
            if let error = error {
                NSUserNotification.display(
                    title: "Update download failed",
                    andMessage: "\(error)")
                return
            }

            // Check if we have the downloaded file
            guard let fileURL = downloadedFileURL else {
                NSUserNotification.display(
                    title: "Update download failed",
                    andMessage: "File couldn't be downloaded. Unknown error.")
                return
            }

            let destinationDirectory = NSTemporaryDirectory()

            // Unarchive the file
            do {
                try SSZipArchive.unzipFileAtPath(fileURL.path, toDestination: destinationDirectory, overwrite: true, password: nil)
            } catch {
                NSUserNotification.display(
                    title: "Update unzip failed",
                    andMessage: "File could not be unarchived. \(error)")
                return
            }

            // Update with the file at path
            dispatch {
                self.updateWithFileAtPath(destinationDirectory)
            }
        }).resume()
    }

    private func updateWithFileAtPath(path: String) {
        // Get app name, to get executable name
        guard let appName = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String else {
            NSUserNotification.display(
                title: "Update failed",
                andMessage: "Could not get app name.")
            return
        }

        // Find applications dir
        let appDirectoryPaths = NSSearchPathForDirectoriesInDomains(.ApplicationDirectory, .LocalDomainMask, true)
        guard let appDirectory = appDirectoryPaths.first else {
            NSUserNotification.display(
                title: "Update failed",
                andMessage: "Could not find Applications folder.")
            return
        }

        // Get the update file (= source file)
        var sourceURL = NSURL(fileURLWithPath: path, isDirectory: true)
        sourceURL     = sourceURL.URLByAppendingPathComponent("\(appName).app", isDirectory: true)

        // Get the local file (= destination file)
        var destinationURL = NSURL(fileURLWithPath: appDirectory)
        destinationURL = destinationURL.URLByAppendingPathComponent("\(appName).app", isDirectory: true)

        // Show note about updating
        NSUserNotification.display(
            title: "Download finished, updating now",
            andMessage: "The app will now be updated.")

        // Prepare coordinator
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var error:NSError?

        // Start writing
        coordinator.coordinateWritingItemAtURL(destinationURL, options: .ForDeleting, error: &error, byAccessor: { writeURL in
            do {
                var resultURL: NSURL?

                // Replace the file first
                try NSFileManager.defaultManager().replaceItemAtURL(writeURL,
                    withItemAtURL: sourceURL,
                    backupItemName: "\(appName)_old.app",
                    options: .UsingNewMetadataOnly,
                    resultingItemURL: &resultURL)

                // Check for the output file
                guard let finalURL = resultURL else {
                    NSUserNotification.display(
                        title: "Update failed",
                        andMessage: "Could not get the new file after copy.")
                    return
                }

                // Get the binary path
                let binaryURL = finalURL.URLByAppendingPathComponent("Contents/MacOS/\(appName)")
                guard let binaryPath = String(CString: binaryURL.fileSystemRepresentation, encoding: NSUTF8StringEncoding) else {
                    NSUserNotification.display(
                        title: "Update failed",
                        andMessage: "Could not get the binary path.")
                    return
                }

                // Set the proper permissions
                let priviliges = [NSFilePosixPermissions : 493]
                try NSFileManager.defaultManager().setAttributes(priviliges, ofItemAtPath: binaryPath)

                // Show notifications
                NSUserNotification.display(
                    title: "\(appName) updated",
                    andMessage: "The app will restart in 5 seconds.")

                // Restart after delay
                delay(5, closure: {
                    NSApp.restart()
                })

            } catch {
                NSUserNotification.display(
                    title: "Update failed",
                    andMessage: "File writing error. \(error)")
            }
        })

        if let error = error {
            NSUserNotification.display(
                title: "Update failed",
                andMessage: "Error while writing file. \(error.localizedDescription)")
        }
    }
}
