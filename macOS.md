
<h2 align="center">Trident Cockpit is an alternative macOS native control app for the <a href="https://www.sofarocean.com/products/trident?aff=30">Sofar Trident Underwater Drone.</a></h2>

<h1 align="center">
<a href="https://dimaru.github.com.tridentcockpit">iOS version here</a>
</h1>


---

# Development of the native macOS version has been discontinued.

## Features

* Controls the Trident Underwater Drone by Sofar Ocean
* Watch video stream from the drone
* Keyboard, mouse and gamepad control 
* Controls camera, light, stabilization
* Realtime drone orientation view
* Show depth, temperature, camera and battery times
* Past dives video from drone: watch, download and delete.
* Show maintenance data: internal pressure, internal temperature, battery cycle count
* Support payload connection and control. (now GoPro HERO 3/3+)

### Payload control:
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

## Keyboard Shortcuts

### Moton control

 Shortcut | Description
|:-:|:-:|
 <kbd>Up Arrow</kbd> | Forward
 <kbd>Down Arrow</kbd> | Backward
 <kbd>Left Arrow</kbd> | Turn Left (rotate counterclockwise)
 <kbd>Right Arrow</kbd> | Turn Right (rotate clockwise)
 <kbd>W</kbd> | Tilt Down
 <kbd>E</kbd> | Tilt Up

### Motor speed modifiers

 Shortcut | Description 
|:-:|:-:|
without modifiers | 10% of motor speed
&#8997;<kbd>Option</kbd> + (<kbd>&uarr;</kbd> &#65372; <kbd>&darr;</kbd> &#65372; <kbd>&larr;</kbd> &#65372; <kbd>&rarr;</kbd> &#65372; <kbd>W</kbd> &#65372; <kbd>E</kbd>) | 25% of motor speed
&#8963;<kbd>Control</kbd> + (<kbd>&uarr;</kbd> &#65372; <kbd>&darr;</kbd> &#65372; <kbd>&larr;</kbd> &#65372; <kbd>&rarr;</kbd> &#65372; <kbd>W</kbd> &#65372; <kbd>E</kbd>) | 50% of motor speed
&#8679;<kbd>Shift</kbd> + (<kbd>&uarr;</kbd> &#65372; <kbd>&darr;</kbd> &#65372; <kbd>&larr;</kbd> &#65372; <kbd>&rarr;</kbd> &#65372; <kbd>W</kbd> &#65372; <kbd>E</kbd>) | 100% of motor speed

### Other shortcuts

 Shortcut | Description
|:-:|:-:|
 <kbd>L</kbd> | Light control
 <kbd>R</kbd> | Camera control
 <kbd>Y</kbd> | Drone view relative yaw
 <kbd>A</kbd> | Drone view absolute yaw

## Building from Source

For build instructions please check out [build.yml](https://github.com/DimaRU/TridentCockpit/blob/master/.github/workflows/build.yml), which should be up-to-date at all times.

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
* [FlatButton](https://github.com/OskarGroth/FlatButton) - Layer based NSButton with Interface Builder styling options
* [CircularProgress](https://github.com/sindresorhus/CircularProgress) - Circular progress indicator for your macOS app


## Author

**Dmitriy Borovikov** - [DimaRU](https://github.com/DimaRU), AOWD diver, iOS developer, Openrov Trident Kickstarter backer #1284

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Credits

Thanks to Jim N. for "Software Exploration - DDS and the Trident" series of posts on [Openrov forum](https://forum.openrov.com/t/software-exploration-dds-and-the-trident-5-fastrtps/7277)

## Disclaimer

This project is unofficial (meaning not supported by or affiliated with Sofar Ocean). Use it at your own risk.
