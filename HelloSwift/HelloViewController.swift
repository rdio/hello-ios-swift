//
//  HelloViewController.swift
//  Hello
//
//  Copyright (c) 2015 Rdio. All rights reserved.
//

import CoreMedia
import UIKit

class HelloViewController: UIViewController, RdioDelegate, RDPlayerDelegate {
    
    @IBOutlet weak var _playButton: UIButton!
    @IBOutlet weak var _loginButton: UIButton!

    @IBOutlet weak var _leftLevelMonitor: UISlider!
    @IBOutlet weak var _rightLevelMonitor: UISlider!

    @IBOutlet weak var _positionSlider: UISlider!
    @IBOutlet weak var _positionLabel: UILabel!
    @IBOutlet weak var _durationLabel: UILabel!
    
    @IBOutlet weak var _currentArtistLabel: UILabel!
    @IBOutlet weak var _currentTrackLabel: UILabel!
    
    var _loggedIn: Bool = false
    var _playing: Bool = false
    var _paused: Bool = false
    var _seeking: Bool = false
    
    var _timeObserver:AnyObject?
    var _levelObserver:AnyObject?
    var _currentTrackDuration:Double = 0
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)        
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override init() {
        super.init()
    }
    
    var appDelegate: HelloAppDelegate {
        get { return UIApplication.sharedApplication().delegate as HelloAppDelegate }
    }
    
    var _player:RDPlayer? = nil
    var player:RDPlayer {
        get {
            if (_player == nil) {
                let sharedRdio = appDelegate.rdioInstance;
                if (sharedRdio.player == nil) {
                    sharedRdio.preparePlayerWithDelegate(self)
                }
                _player = sharedRdio.player
            }
            return _player!
        }
    }

    // MARK: - View Lifecycle
    
    override func loadView() {
        super.loadView()
        appDelegate.rdioInstance.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        player.addObserver(self, forKeyPath: "currentTrack", options: NSKeyValueObservingOptions.New, context: nil)
        player.addObserver(self, forKeyPath: "duration", options: NSKeyValueObservingOptions.New, context: nil)
        startObservers()
    }
    
    override func viewDidDisappear(animated: Bool) {
        player.removeObserver(self, forKeyPath: "currentTrack")
        player.removeObserver(self, forKeyPath: "duration")
        stopObservers()
        
        super.viewDidDisappear(animated)
    }
    
    // MARK: - Screen Rotation
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    // MARK: - Periodic observers
    
    func startObservers() {
        if (_levelObserver == nil) {
            _levelObserver = player.addPeriodicLevelObserverForInterval(CMTimeMake(1, 100), queue: dispatch_get_main_queue(),
                usingBlock: { (left: Float32, right: Float32 ) -> Void in
                    self.setMonitorValuesForLeft(left, andRight: right)
            })
        }
        
        if (_timeObserver == nil) {
            _timeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMake(1, 100), queue: dispatch_get_main_queue(),
                usingBlock: { (time: CMTime) -> Void in
                    let seconds:Float64 = CMTimeGetSeconds(time)
                    if (!isnan(seconds) && !isinf(seconds)) {
                        self.positionUpdated(seconds)
                    }
            })
        }
    }
    
    func stopObservers() {
        if (_levelObserver != nil) {
            player.removeLevelObserver(_levelObserver)
            _levelObserver = nil
        }
        
        if (_timeObserver != nil) {
            player.removeTimeObserver(_timeObserver)
            _timeObserver = nil
        }
    }
    
    // MARK: - Observation handlers
    
    func setMonitorValuesForLeft(left: Float32, andRight right:Float32) {
        var leftLinear = Float(pow(Double(10), Double(0.05 * left)))
        var rightLinear = Float(pow(Double(10), Double(0.05 * right)))
        
        _leftLevelMonitor.value = leftLinear
        _rightLevelMonitor.value = rightLinear
    }
    
    func positionUpdated(seconds: Float64) {
        if (!_seeking) {
            _positionLabel.text = formattedTimeForInterval(seconds)
            _positionSlider.value = Float(seconds / _currentTrackDuration);
        }
    }
    
    func formattedTimeForInterval(interval: NSTimeInterval) -> String {
        var min = NSInteger(interval / 60)
        var sec = NSInteger(interval % 60)
        
        return NSString(format: "%d:%02d", min, sec)
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if (player.isEqual(object)) { // should always be true
            if (keyPath == "currentTrack") {
                let trackKey = change[NSKeyValueChangeNewKey] as? NSString
                if (trackKey != nil) {
                    
                    var trackDelegate = RDAPIRequestDelegate.delegateToTarget(self,
                        loadedAction: "updateCurrentTrackRequest:didLoadData:",
                        failedAction: "updateCurrentTrackRequest:didFail:") as RDAPIRequestDelegateProtocol
                    
                    var parameters:Dictionary<NSObject, AnyObject!> = ["keys": trackKey, "extras": "-*,name,artist"]
                    appDelegate.rdioInstance.callAPIMethod("get", withParameters: parameters, delegate: trackDelegate)
                    
                } else {
                    _currentTrackLabel.text = "";
                    _currentArtistLabel.text = "";
                }
            } else if (keyPath == "duration") {
                var duration = change[NSKeyValueChangeNewKey] as? NSNumber
                _currentTrackDuration = duration!.doubleValue
                _durationLabel.text = formattedTimeForInterval(_currentTrackDuration)
            }
        }
    }
    
    func updateCurrentTrackRequest(request: RDAPIRequest!, didLoadData data:[NSObject : AnyObject]!)
    {
        var trackKey = request!.parameters["keys"] as String
        var metadata = data![trackKey] as NSDictionary
        
        var trackName = metadata["name"] as String
        var artistName = metadata["artist"] as String
        
        _currentTrackLabel.text = trackName
        _currentArtistLabel.text = artistName
    }
    
    func updateCurrentTrackRequest(request: RDAPIRequest!, didFail error:NSError!)
    {
        println("error: \(error.localizedDescription)")
    }
    
    // MARK: - UI event and state handling
    
    @IBAction func playClicked(sender: UIButton!) {
        if (!_playing) {
            var keys: [String] = ["t3176972", "t55901576", "t58720733", "t3655138"]
            player.playSources(keys)
        } else {
            player.togglePause()
        }
    }
    
    @IBAction func loginClicked(sender: UIButton!) {
        if (_loggedIn) {
            appDelegate.rdioInstance.logout()
        } else {
            appDelegate.rdioInstance.authorizeFromController(self)
        }
    }
    
    func setLoggedIn(logged_in: Bool) {
        _loggedIn = logged_in
        if (logged_in) {
            _loginButton.setTitle("Log Out", forState: UIControlState.Normal)
        } else {
            _loginButton.setTitle("Log In", forState: UIControlState.Normal)
        }
    }

    @IBAction func previousClicked(sender: UIButton) {
        player.previous()
    }
    
    @IBAction func nextClicked(sender: UIButton) {
        player.next()
    }
    
    @IBAction func seekStarted(sender: UISlider) {
        if (!_playing) {
            return
        }
        _seeking = true
    }
    
    @IBAction func seekFinished(sender: UISlider) {
        if (!_playing) {
            return
        }
        
        _seeking = false
        
        var position = Double(_positionSlider.value) * _currentTrackDuration
        var queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(queue, {
            self.player.seekToPosition(position)
        })
    }
    
    // MARK: - RdioDelegate
    
    func rdioDidAuthorizeUser(user: [NSObject : AnyObject]!, withAccessToken accessToken: String!) {
        setLoggedIn(true)
    }
    
    func rdioAuthorizationFailed(error: NSError!) {
        println("Rdio authorization failed with error: \(error.localizedDescription)")
        setLoggedIn(false)
    }
    
    func rdioAuthorizationCancelled() {
        println("rdioAuthorizationCancelled")
        setLoggedIn(false)
    }
    
    func rdioDidLogout() {
        setLoggedIn(false)
    }
    
    // MARK: - RDPlayerDelegate
    
    func rdioIsPlayingElsewhere() -> Bool {
        // Let the Rdio framework tell the user
        return false
    }
    
    func rdioPlayerChangedFromState(oldState: RDPlayerState, toState state: RDPlayerState) {
        _playing = (state.value != RDPlayerStateInitializing.value && state.value != RDPlayerStateStopped.value)
        _paused = (state.value == RDPlayerStatePaused.value);
        if (_paused || !_playing) {
            _playButton.setTitle("Play", forState: UIControlState.Normal)
            stopObservers()
        } else {
            _playButton.setTitle("Pause", forState: UIControlState.Normal)
            startObservers()
        }
    }
    
    func rdioPlayerFailedDuringTrack(trackKey: String!, withError error: NSError!) -> Bool {
        println("Rdio failed to play track %@\n%@ \(trackKey, error)")
        return false
    }
    
    func rdioPlayerQueueDidChange() {
        println("Rdio queue changed to %@ \(player.trackKeys)")
    }
}

