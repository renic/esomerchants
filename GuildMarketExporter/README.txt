---- Installation ----

1. Copy the GuildMarketExporter folder to your elder scrolls online addon
   folder

On Windows this is usually ...
C:\Users\< username >\Documents\Elder Scrolls Online\live\AddOns\

On Mac this is usually ...
<your home folder>/Documents/Elder Scrolls Online/live/AddOns/

2. Relod the UI if your client is currently running (/reloadui works fine)

---- Usage ----

1. Open a guild store

2. Use the command /gme

3. Wait for the scan to complete

4. Click the 'save' button

---- Output ----

After saving, look inside the ...
<your home folder>\Documents\Elder Scrolls Online\live\SavedVariables
folder. You will find a file named GuildMarketExporter.lua. This file contains
all the exported data from the mod.

Please upload your exports at http://esomerchants.org/upload/ ...
We are currently working on browsing, searching, and analyzing the data for
use on the web.

---- Additional ----

I'm releasing this mod under the Open Source BSD 2-clause license.
You can help with development, or keep up with changes at
https://github.com/renic/esomerchants

---- Change Log ----
0.1 - initial release
0.2 - Bug Fixes and New Features
* Fixed bug where Wrong Guild was Associated to Orders
* Added Item Level to Exported Data
* Added Actual Prices Paid on Completed Orders Via Guild History
0.2.1 - Re-Added Check to See if Guild Store is Open
