MY UPDATE
-------------
24-NOV-2026 - v0.2.1.0
Fixed interrupting assigned work when leaving a vehicle driven by a worker as AutoDrive/CoursePlay/FollowMe/classic AI jobs are stopped. The ContractorMod tab now shows the state only for the system that is actually driving and the remaining time for CP and AD.

23-NOV-2026 - v0.2.0
Added a ContractorMod tab to the in-game menu (Esc/Enter during a running game) for real-time worker management: hire (max 10 workers, a newly hired worker spawns next to the active character), fire (blocked while the worker is in a vehicle), rename, switch to a worker, and a per-worker table with location (coordinates or vehicle name), state (CoursePlay course / AutoDrive task / AI job / driving / on foot) and remaining time.

20-NOV-2026 - v0.1.0
Fixed trigger detection for individual characters. Triggers are now detected only for the active character.


ORIGINAL TEXT
-------------
This mod enable simulating a defined number of characters you control one by one during a solo game.

By default, 4 characters are available Alex, Brenda, Chris and David.
At first loading of a map, they are located at the Career starting point.
When saving the game, characters location and vehicle is saved so they will be restored when next loading the game.
So you will be able to continue your game exactly as you left it.

Default keys to switch between characters are:
- NEXT    : Tab
- PREVIOUS: Shift + Tab
They can be changed but by default they replaced the standard switch between vehicles since it's disable.

This mod is compatible with CoursePlay and FollowMe mods.
So, for example, when using FollowMe, one character will be the Leader and another one the Follower.
Characters can be seen on the minimap when activating default category (the last one represented by a house) in the map overview screen and you can also deactivate/activate characters from this view.

TO FIX: Name, gender, color, body, hair, accessories and number of characters can be changed in ContractorMod.xml file located in modSettings directory for new games.
Once a game has been saved, they can be changed in ContractorMod.xml file present in related savegame folder.
TO IMPLEMENT: ContractorMod.xml file also contains configuration for passengers for mods vehicles. You can add your own mods here.


IN-GAME SETTINGS TAB
---------------------
The in-game menu (Esc/Enter during a running game) has a ContractorMod tab where the number of workers can be changed in real time (min 1, max 10): hire and fire workers, rename them, see their location (coordinates or vehicle), state (CoursePlay course / AutoDrive task / AI job / driving / on foot), remaining time, and switch to them or fire them. A hired worker spawns next to the active character; a worker inside a vehicle cannot be fired.
