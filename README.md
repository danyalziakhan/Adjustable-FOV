# Adjustable FOV

A Witcher 3 mod that adds a field of view slider to the Mods menu. The game
ships without an FOV option, so this adds one.

The slider runs from -25 to +25 and is applied on top of the vanilla FOV of 60
(70 while sprinting). Leaving it at 0 gives you the stock camera. Changes apply
as soon as you move the slider, and the FOV holds through combat, aiming, and
mounting, riding or dismounting a horse.

There is one slider rather than one per state, so it feels like it was natively
part of the game, the way CD Projekt RED would have implemented it.

## Versions

There is a folder for each version of the game, each holding the `bin` and
`Mods` folders that go into the game directory.

`Remastered` is for game version 5.0 and later. All of it lives in one new
script built on the game's script annotations, so it doesn't replace any vanilla
scripts and never needs Script Merger.

`Next-Gen` is for 4.04. It ships full copies of the vanilla scripts it edits.
Its FOV logic was originally based on wghost81's
[FOV Tweak](https://www.nexusmods.com/witcher3/mods/8470).

## Installing

Copy the contents of the folder for your game version into your Witcher 3
folder.

On Next-Gen, also add modAdjustableFOV.xml to dx12filelist.txt (or
dx11filelist.txt), or let Menu Filelist Updater do it. If you also run
[Smooth Mount Dismount](https://www.nexusmods.com/witcher3/mods/7265), use
Script Merger, since both edit horseRiding.ws.

MIT licensed.
