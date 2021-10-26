# traceph-ios-app
TracePH iOS app is a Swift mobile application.

##Prerequisites
* CocoaPods
* Xcode (latest version)
* iOS device (max iOS 15.0)


## Getting Started
Here is a step-by-step instruction on how to install the app to your device. Emulators do not support bluetooth therefore they can't be used to test the app.

1) Clone this repository.

2) Install the cocoapod modules.

3) Connect your developer account to your Xcode by going to `XCode > Preferences > Accounts`.

4) Open Secrets.swift. If you have access to decrypt it, do have it decrypted. Else, leave the file blank.

5) Connect your device to the Xcode and make sure it's set up in `Window > Devices and Simulators`. Make sure that your iOS device trusts your Mac.

6) Build and install the app. You should be able to see the app in your iOS device.


### Local deployment
If you're planning on connecting the app to your local database or to your local machine, here is a step-by-step instruction.

1) Clone the following repositories found in this organization: **node-api** and **auth-api**. The auth-api repository is only available to members of the organization. However, the app will still work regardless of this server setup with the exception of the report feature.

2) Follow the instructions of their corresponding README on how to setup the server.

3) In the app, update the **ROOT_URL** in the file API/config.swift to your chosen URL.

4) Install the app to your device.


## Contact Us
Email us at [detectph.updsc@gmail.com](mailto:detectph.updsc@gmail.com).
You can also visit our [website](https://www.detectph.com) to know more about our app.


## Authors
* **Enzo Vergara** - [Github](https://github.com/enzosv)
* **Asti Lagmay** - [Github](https://github.com/astilagmay)
* **Angelique Rafael** - [Github](https://github.com/JelloJill)
