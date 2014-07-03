ActivityUploader
================

Automatically upload exercise activity files downloaded to your Mac by your activity monitor like Garmin Forerunner or Suunto watch to websites like Strava, FetchEveryone and DailyMile.

Motivation
----------

I use multiple websites to track my running and cycling activities and was getting tired of having to manually go to each and upload either via the, soon to be obsolete Garmin Communicator plugin or by manually uploading the .tcx or .fit files.

Garmin has decided to retire the Garmin ANT+ Agent and Garmin Communicator plugin in favour of Garmin Express, which doesn't have a browser plugin so you now need to manually upload your .tcx or .fit files to sites like Strava, DailyMile and FetchEveryone, until such time as these sites cough up the $5000 Garmin demands in order to offer syncing functionality with Garmin Connect.

ActivityUploader make this simple and easy for OS X users by completely automating the upload process by taking advantage of OS X's launchd and its `WatchPaths` functionality.

Plugins
-------

ActivityUploader is extensible to other sites via a very simple plugin architecture.

Currently offered plugins:

* Strava
* FetchEveryone (TODO)


Is it any good?
---------------

Probably not.  This is one of my first forays into ruby programming so whilst it's functional and gets the job done, it's probably not the most elegant of coding.

If you want to help make it better, please do. See CONTRIBUTING.md for more details on how you can help make this better.

Installation
------------

[TBC]

Usage
-----

[TBC]

Configuration
-------------

It all happens in config.yml.

Tested with
-----------

- Garmin Forerunner 405CX
  - Garmin ANT+ Agent
  - Garmin Express (TODO)
