🛠️ **Patch Notes - v0.2.2 (Hotfix & Polishing)**

I have heavily tweaked the balancing and with v0.2.2 I am bringing you a massive update regarding Quality of Life! Thank you to all the hardworking testers!

**Time Control (HUD & Hotkeys):**
- The time control now features 4 buttons: Pause (Space), Normal (1x), Fast (5x), Fast Forward (10x).
- The pause now remembers the previous speed and instantly returns to it when pressed again.

**UI & Controls:**
- Monitor & PiP Windows: The ESC key now logically closes the last opened window (LIFO).
- Room Context Menu: As soon as a room context menu opens, the hover tooltip disappears instantly. The menu also follows the camera unless manually moved.
- Added exclusive fullscreen and "mouse confined" modes to prevent accidental clicks on a second monitor.
- New Settings: Added two audio toggles to mute cash register sounds ("cha-ching") and menu sounds. The camera zoom for "Go to Room" can now be disabled.

**Balancing & Gameplay:**
- Guest Spawn: The very first arrival of guests on day 1 is now strictly timed to 07:00-07:30 to prevent idle times.
- Business & Nomads: Business guests now only generate if a superior room has actually been built. Corrected spawn logic for Digital Nomads.
- Bar: Corrected opening hours (12:00 to 23:30).

**Polishing & Code Cleanup:**
- Tooltips: Room status icons (cleaning/maintenance) now have dynamic and correct tooltips (e.g., "requested" vs "urgently needed" in different colors).
- Warnings: Cleaned up numerous annoying Godot engine warnings and removed hardcoded texts into the localization system.
- Tutorial: A new tip reminds you about cleaning and maintenance staff just in time when rooms get dirty.

Have fun building and managing your hotel! 🏨✨
