# Socket

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Gagnant/Socket/master/LICENSE) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Cocoapods compatible](https://img.shields.io/badge/Cocoapods-compatible-brightgreen.svg)](http://cocoapods.org)

Socket is a TCP/IP socket networking library. It offers asynchronous operation, and a native Cocoa class complete with delegate support. Includes non-blocking send/receive operations, full delegate support, run-loop based, self-contained class, and support for IPv4 and IPv6.

## Installation

### Carthage

Check out the [Carthage](https://github.com/Carthage/Carthage) docs on how to add a install. The `Socket` framework is already setup with shared schemes. To integrate Socket into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "Gagnant/Socket"
```

Run `carthage update`, and you should now have the latest version of Socket in your Carthage folder.

### CocoaPods

Socket is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Socket', :git => 'https://github.com/Gagnant/Socket.git'
```

### Other

Simply grab the framework (either via git submodule or another package manager).

Add the `Socket.xcodeproj` to your Xcode project. Once that is complete, in your "Build Phases" add the `Socket.framework` to your "Link Binary with Libraries" phase.

## License

Socket is licensed under the MIT License.
