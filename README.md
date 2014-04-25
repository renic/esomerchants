Guild Market Exporter
============

Guild Market Exporter is a UI Mod for ESO

created by @zalrenic; founder of The Merchants Guild - an [eso trade guild](http://esomerchants.org)

http://esomerchants.org

Installation
============

1. Copy the GuildMarketExporter folder to your elder scrolls online addon folder

* On Windows this is usually C:\Users\< username >\Documents\Elder Scrolls Online\live\AddOns\

* On Mac this is usually ~/Documents/Elder Scrolls Online/live/AddOns/

2. Relod the UI if your client is currently running (/reloadui works fine)

Usage
============

1. Open a guild store

2. Use the command /gme

3. Wait for the scan to complete

4. Click the 'save' button

Output
============

After saving, look inside the ~/Documents/Elder Scrolls Online/live/AddOns/SavedVariables folder.  You will find a file named GuildMarketExporter.lua.  This file contains all the exported data from the mod.

Please feel free to upload your exports at http://esomerchants.org/upload/ ... we are currently working on browsing, searching, and analyzing the data for use on the web.

Change Log
============
0.1 - initial release

0.2 - Bug Fixes and New Features

* Fixed bug where Wrong Guild was Associated to Orders

* Added Item Level to Exported Data

* Added Actual Prices Paid on Completed Orders Via Guild History
 
0.2.1 - Re-Added Check to See if Guild Store is Open

0.2.2 - Added extra check to prevent UI error when not all guild slots are filled.

0.2.3 - Now reinitializes itself every time the guild store is opened to stomp a bug that prevented it from moving to the next guild when the number of guilds changes after intial loading of the addon.
