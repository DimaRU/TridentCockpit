![Build](https://github.com/DimaRU/TridentCockpit/workflows/Build/badge.svg) 
<div>
<a href="https://www.patreon.com/DimaRU" data-patreon-widget-type="become-patron-button"><img src="https://img.shields.io/endpoint?style=for-the-badge&url=https%3A%2F%2Fshieldsio-patreon.herokuapp.com%2FDimaRU"></a>
</div>
<h2 align="center">Trident Cockpit is an alternative iOS/iPadOS/macOS control app for the <a href="https://www.sofarocean.com/products/trident?aff=30">Sofar Trident Underwater Drone.</a></h2>

<p align="center">
<a href="https://apps.apple.com/us/app/trident-cockpit/id1501545121"><img src="images/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg" width="200" /></a>
</p>

![iPhone screenshot](Screenshots/iPhone%2011%20Pro%20Max.png)

### [macOS page (development discontinued)](macOS.md)
---

## Features

* Controls the Trident Underwater Drone by Sofar Ocean
* Watch live video stream from the drone
* Gamepad control 
* Controls camera, light, stabilization
* Recording pilot video stream
* GPS geotagging pilot video
* Realtime drone orientation view
* Show depth, temperature, camera and battery times
* Past dives video from drone: watch, download and delete.
* Show maintenance data: internal pressure, internal temperature, battery cycle count
* Support payload connection and control. (now GoPro HERO 3/3+)

## Payload control:
#### GoPro HERO 3/3+
* Control camera power
* Camera recording control
* Live preview
* Show battery level
* Show recording time left

### Supported gamepads

* Xbox Wireless Controller
* DualShock 4
* Any MFi certified gamepad

## Support the project
<a href="https://www.patreon.com/DimaRU" data-patreon-widget-type="become-patron-button"><img src="https://img.shields.io/endpoint?style=for-the-badge&url=https%3A%2F%2Fshieldsio-patreon.herokuapp.com%2FDimaRU"></a>

If you’re benefiting from my project, or simply like what I do, you can help me by donating some amount onetime or each month. Supporting me on [Patreon](https://www.patreon.com/DimaRU) will help pay for hardware needed for further development.
The money received will go towards:

* Buy a GoPro Max 360 for support latest GoPro models in the app.
* Buy an iPad to speed up iPad version testing.

With Patreon, you can send me a small monthly amount of money, or make a one-time donation by canceling the monthly subscription after the first payment.


## Building from Source

For build instructions please check out [.travis.yml](https://github.com/DimaRU/TridentCockpit/blob/master/.travis.yml), which should be up-to-date at all times.

### Required software

* CMake

1. Install Xcode from App Store
2. Install build tools by running `brew install cmake`

### Build

* Run from the terminal:

```
git clone --recurse-submodules https://github.com/DimaRU/TridentCockpit.git
cd TridentCockpit
```

* Open TridentCockpit.xcodeproj in the [latest public version of Xcode](https://itunes.apple.com/us/app/xcode/id497799835). *TridentCockpit may not build if you use any other version.*
* Change the Team to your own team in the "Signing & Capabilities" panel.
* Ensure that the scheme is set to TridentCockpitiOS.
* Build the project.


## Dependencies

* [Eprosima Fast RTPS](https://github.com/DimaRU/Fast-RTPS) - implementation of the OMG RTPS protocol. Modified version based on Eprosima Fast RTPS.
* [Foonathan memory](https://github.com/DimaRU/memory) - Memory allocator for Fast RTPS. Modified version for iOS comparability.
* [FastRTPSBridge](https://github.com/DimaRU/FastRTPSBridge) - A Swift wrapper for FastRTPS library
* [CDRCodable](https://github.com/DimaRU/CDRCodable) - Swift Codable serialization/deserialization framework for Common Data Representation (CDR) binary format.
* [Shout](https://github.com/DimaRU/Shout) - A Swift SSH framework that wraps libssh2. Modified version.
* [BlueSocket](https://github.com/DimaRU/BlueSocket) - Socket framework for Swift using the Swift Package Manager. Modified version based on IBM BlueSocket.
* [Moya](https://github.com/Moya/Moya) - Network abstraction layer written in Swift.
* [PromiseKit](https://github.com/mxcl/PromiseKit) - Promises for Swift & ObjC.
* [Kingfisher](https://github.com/onevcat/Kingfisher) - A lightweight, pure-Swift library for downloading and caching images from the web.
* [PWSwitch](https://github.com/Shaninnik/PWSwitch) - Highly customizable UISwitch built with CALayers and CAAnimations. Modified version.
* [LinearProgressBar](https://github.com/gordoneliel/LinearProgressBar) - Simple progress bar for iOS.
* [CameraButton](https://github.com/otusweb/iOS-camera-button) - A button that behave the same way as the video camera button in the iOS camera. Modified version.


## Author

**Dmitriy Borovikov** - [DimaRU](https://github.com/DimaRU), AOWD diver, iOS developer, Openrov Trident Kickstarter backer #1284

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Credits

Thanks to Jim N. for "Software Exploration - DDS and the Trident" series of posts on [Openrov forum](https://forum.openrov.com/t/software-exploration-dds-and-the-trident-5-fastrtps/7277)

## Disclaimer

This project is unofficial (meaning not supported by or affiliated with Sofar Ocean). Use it at your own risk.

## [Privacy policy](privacy_policy.md)
