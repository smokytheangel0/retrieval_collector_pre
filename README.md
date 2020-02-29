#setup
you will need the flutter toolchain to run the app
and the rust toolchain to run the driver script
you can find instructions at these links
https://flutter.dev/docs/get-started/install
https://www.rust-lang.org/tools/install

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



