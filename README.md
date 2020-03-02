#description
this app is designed to collect data which will help determine whether
allowing drivers and yard crew to locate trailers using gps saves more time and fuel
than the more typical detective work that goes into finding an particular trailer in
a carrier's storage yard.

#setup
you will need the flutter toolchain to run the app
and the rust toolchain to run the driver script
you can find instructions at these links
https://flutter.dev/docs/get-started/install
https://www.rust-lang.org/tools/install

after installing flutter you should use the master channel by running
```
flutter channel master
```

you will need to add your google maps api keys (ios and Android) in two places
```
android/app/src/main/_AndroidManifest.xml
```
then rename the file to AndroidManifest.xml

and

```
ios/Runner/_AppDelegate.swift
```
then rename the file to AppDelegate.swift

you will find a string similar to "ADD YOUR KEY HERE" in each file in the place where you should put the key



