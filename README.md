# description
this app is designed to collect data which will help determine whether\
allowing drivers and yard crew to locate trailers using gps saves time and fuel\
compared the more typical detective work that goes into\
finding an particular trailer in a carrier's storage yard.

# setup
you will need the flutter toolchain to run the app\
and the rust toolchain to run the driver script\
you can find instructions at these links\
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


# tutorial
the main workflow is for active trailer users and requires follow up\
the way you approach this flow is to:
* press the add button
* enter the supporting info like name and description
* flip the toggle switch to enable auto mode
* press start, and search for the trailer
* press end once you encounter the trailer
* press done to save the record

the follow up flow measures a direct travel of the same route\
to follow up:
* press the list item that you wish to add a direct time to
* travel to the starting location, using the map if neccessary to determine where this is
* after arriving the start button will turn green
* you can then proceed to the end location
* after arriving the end button will turn red
* press done to save the record
