# description
this app is designed to collect data which will help determine whether\
allowing drivers and yard crew to locate trailers using gps saves time and fuel\
compared the more typical detective work that goes into\
finding a particular trailer in a carrier's storage yard.

# setup
you will need the flutter toolchain to run the app\
and the rust toolchain to run the driver script (located at: https://github.com/smokytheangel0/run_driver_RC)

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
## auto
the main workflow is for active trailer users and requires follow up\
the way you approach this flow is to:
* press the add button
* enter the supporting info like name and description of trip
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

## anecdotal
there are two ways to approach anecdotal input \
the first is the easiest but most time consuming
* press the add button
* enter the supporting info like name and description of trip
* enter the interviewee's estimated retrieval time
* travel to the estimated start location
* press start
* travel to the estimated traile location
* press end
* press done to save a complete record

the other way to do this saves time in the event that \
you cannot drive the route immediately
* press the add button
* enter the supporting info like name and description of trip
* enter the interviewee's estimated retrieval time
* press map
* find the estimated start location on the map
* press start
* tap the estimated start location on the map
* find the estimated end location on the map
* press end
* tap the estimated end location on the map
* press done
* press done to save the initial record

to follow up later, you perform the same steps as the auto follow up
* press the list item that you wish to add a direct time to
* travel to the starting location, using the map if neccessary to determine where this is
* after arriving the start button will turn green
* you can then proceed to the end location
* after arriving the end button will turn red
* press done to save the record

### it is important to note that the anecdotal records are not separated from auto at the current time
### this is a database design flaw on my part which will be corrected in later versions

# trivia
This project began as an unplanned though altogether neccesary step before\
before beginning the MiFare Ultralight C based trailer custody/locator app. \
This data collector took a week and a half to get to the 'not quite done' stage \
that it was in as of the initial commit here. \
and was really my first excercise in pushing as hard as I could to finish \
so that the 'real work' could begin. \
The 'real work' was later dropped due to new supplier restrictions on minimum orders\
of the fare cards.

It was intended to be a cheap alternative to whatever solution the transportation \
company's contractors could stack up, designed to address primarily the needs of \
the drivers, mechanics, yard crew, and lower management.
