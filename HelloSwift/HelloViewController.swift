//
//  HelloViewController.swift
//  Hello
//
//  Copyright (c) 2015 Rdio. All rights reserved.
//

import CoreMedia
import UIKit

class HelloViewController: UIViewController, RdioDelegate, RDPlayerDelegate {
    
    var _playButton: UIButton!
    var _loginButton: UIButton!
    
    var _loggedIn: Bool = false
    var _playing: Bool = false
    var _paused: Bool = false
    var _seeking: Bool = false
    
    var _leftLevelMonitor: UISlider!
    var _rightLevelMonitor: UISlider!
    
    var _positionSlider: UISlider!
    var _positionLabel: UILabel!
    var _durationLabel: UILabel!
    
    var _currentTrackLabel: UILabel!
    var _currentArtistLabel: UILabel!
    
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
        
        var appFrame = UIScreen.mainScreen().applicationFrame;
        var view = UIView(frame: appFrame)
        view.backgroundColor = UIColor.whiteColor()
        
        // Play button
        _playButton = UIButton.buttonWithType(UIButtonType.System) as? UIButton
        _playButton.setTitle("Play", forState: UIControlState.Normal)
        _playButton.frame = CGRect(x:20, y:20, width:appFrame.size.width - 40, height:40)
        _playButton.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        _playButton.addTarget(self, action: "playClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(_playButton!)
        
        // Login button
        _loginButton = UIButton.buttonWithType(UIButtonType.System) as? UIButton
        _loginButton.setTitle("Login", forState: UIControlState.Normal)
        _loginButton.frame = CGRect(x:20, y:70, width:appFrame.size.width - 40, height: 40)
        _loginButton.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        _loginButton.addTarget(self, action: "loginClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(_loginButton!)
        
        // Previous track button
        var prevButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        prevButton.setTitle("Prev", forState: UIControlState.Normal)
        var prevFrame = CGRect(x: 20, y: 20, width: 77, height: 40)
        prevButton.frame = prevFrame
        prevButton.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        prevButton.addTarget(self, action: "previousClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(prevButton)
        
        // Powered by Rdio label
        var labelFrame = CGRect(x: 20, y: 110, width: appFrame.size.width - 40, height: 40)
        var rdioLabel = UILabel(frame: labelFrame)
        rdioLabel.text = "Powered by Rdio®"
        rdioLabel.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        rdioLabel.textAlignment = NSTextAlignment.Center
        view.addSubview(rdioLabel)
        
        // Next track button
        var nextButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        nextButton.setTitle("Next", forState: UIControlState.Normal)
        var nextFrame = CGRect(x: 223, y: 20, width: 77, height: 40)
        nextButton.frame = nextFrame
        nextButton.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        nextButton.addTarget(self, action: "nextClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(nextButton)
        
        // Left level label
        var leftLevelLabelFrame = CGRect(x: 20, y: 151, width: 15, height: 21)
        var leftLevelLabel = UILabel(frame: leftLevelLabelFrame)
        leftLevelLabel.text = "L"
        view.addSubview(leftLevelLabel)
        
        // Left level
        var leftSliderFrame = CGRect(x: 65, y: 151, width: 191, height: 28)
        _leftLevelMonitor = UISlider(frame: leftSliderFrame)
        _leftLevelMonitor.setValue(0.0, animated: false)
        view.addSubview(_leftLevelMonitor!)
        
        // Right level label
        var rightLevelLabelFrame = CGRect(x: 20, y: 191, width: 15, height: 21)
        var rightLevelLabel = UILabel(frame: rightLevelLabelFrame)
        rightLevelLabel.text = "R"
        view.addSubview(rightLevelLabel)
        
        // Right level
        var rightSliderFrame = CGRect(x: 65, y: 191, width: 191, height: 28)
        _rightLevelMonitor = UISlider(frame: rightSliderFrame)
        _rightLevelMonitor.setValue(0.0, animated: false)
        view.addSubview(_rightLevelMonitor)
        
        // Current artist label
        var currentArtistFrame = CGRect(x: 20, y: 258, width: 280, height: 25)
        _currentArtistLabel = UILabel(frame: currentArtistFrame)
        view.addSubview(_currentArtistLabel)
        
        // Current track title
        var currentTrackFrame = CGRect(x: 20, y: 316, width: 280, height: 25)
        _currentTrackLabel = UILabel(frame: currentTrackFrame)
        view.addSubview(_currentTrackLabel)
        
        // Position label
        var posLabelFrame = CGRect(x: 20, y: 287, width: 37, height: 21)
        _positionLabel = UILabel(frame: posLabelFrame)
        view.addSubview(_positionLabel)
        
        // Duration label
        var durLabelFrame = CGRect(x: 264, y: 287, width: 37, height: 21)
        _durationLabel = UILabel(frame: durLabelFrame)
        view.addSubview(_durationLabel)
        
        // Position slider
        var posSliderFrame = CGRect(x: 65, y:287, width:191, height: 28)
        _positionSlider = UISlider(frame: posSliderFrame)
        _positionSlider.addTarget(self, action: "seekStarted", forControlEvents: UIControlEvents.TouchDown)
        _positionSlider.addTarget(self, action: "seekFinished", forControlEvents: UIControlEvents.TouchUpInside)
        _positionSlider.addTarget(self, action: "seekFinished", forControlEvents: UIControlEvents.TouchUpOutside)
        view.addSubview(_positionSlider)
        
        appDelegate.rdioInstance.delegate = self
        
        self.view = view;
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
    
    func playClicked(sender: UIButton!) {
        if (!_playing) {
            var keys: [String] = ["t11680039", "t11680092", "t11680148", "t11680205"]
            player.playSources(keys)
        } else {
            player.togglePause()
        }
    }
    
    func loginClicked(sender: UIButton!) {
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
    
    func nextClicked(sender: UIButton) {
        player.next()
    }
    
    func previousClicked(sender: UIButton) {
        player.previous()
    }
    
    func seekStarted() {
        if (!_playing) {
            return
        }
        _seeking = true
    }
    
    func seekFinished() {
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

