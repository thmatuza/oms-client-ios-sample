# OMS Native SDK sample applications

This is a iOS sample applications project for [Open Media Streamer Native SDK](https://github.com/open-media-streamer/oms-client-native). It is based on the sample applications for [The Intel CS for WebRTC Client iOS SDK](https://software.intel.com/sites/products/documentation/webrtc/ios/index.html).

It is written in Swift.

# How to build
## Prerequisites
* Replace the frameworks

WebRTC and OMC frameworks are located in /libs. There are default framework builds, but you can replace them with your own framework builds. Getting information on how to build WebRTC and OMC frameworks, please refer to [oms-nativesdk](https://github.com/open-media-streamer/oms-client-native).

## Build Project
For conference sample
```
open conference/OMSConference.xcworkspace
```

For p2p sample
```
open  p2p/OMSP2P.xcworkspace
```
