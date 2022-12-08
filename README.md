# Cylinder Remade

![](https://github.com/rweichler/cylinder/blob/cb8f000dfb1045b9b7cb872ba9b8c843f7f73ebc/code.png)

## Latest version: 0.0.3 beta

[Here](https://github.com/ryannair05/Cylinder-Remade/blob/master/packages/com.ryannair05.cylinderremade_0.0.3-beta_iphoneos-arm.deb?raw=true)'s the deb.

## what???

This is a jailbreak tweak that lets you animate your icons when you swipe pages on the SpringBoard.

Differences to Barrel:

1. Combining multiple effects
2. Effects are written in [Swift](https://www.swift.org/about/), but can also be written in Objective-C

Custom scripts can be submitted to [/r/cylinder](http://reddit.com/r/cylinder).

If you want to make your own effects, check out /tweak/CylinderAnimator.swift for examples

Compatible with iOS 14 and up.

# How to build/install this

## Dependencies

* Mac OS X, Linux or jailbroken iOS
* Theos
* Xcode (or, clang/make with a private/patched SDK to build preferences &gt;= iOS 14)

## Setup

Clone the repository and cd into it

```
git clone https://github.com/ryannair05/Cylinder-Remade.git
cd cylinder
```

### For those who don't have Xcode installed

Open `config.mk` and edit the line that says `SDK=` to reflect where your copy of the iPhone SDK is.

The theos team has been nice enough to host them for us here: https://github.com/theos/sdks

Just download one of those (must be >= iOS 13), unzip it somewhere, delete the original .tar.gz and paste wherever you unzipped it after the `SDK=` in the config.mk.

## Building

If you just want a .deb, run this:

```
make package
```

If you want it to build and install on your device, run this:
```
make do IPHONE_IP=iphone_wifi_ip_here
```
You need OpenSSH installed in order for the installation to work.