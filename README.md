# Adjustable FOV

A Witcher 3 mod that adds a field of view slider to the Mods menu. The game
ships without an FOV option, so this adds one.

The slider runs from -25 to +25 and is applied on top of the vanilla FOV of 60
(70 while sprinting). Leaving it at 0 gives you the stock camera.

## Relation to FOV Tweak

The original approach came from wghost81's
[FOV Tweak](https://www.nexusmods.com/witcher3/mods/8470), which worked out how
to hold a chosen FOV in each of the player states. This mod started from that.

The difference is what it exposes. FOV Tweak gives you a separate slider for
combat, exploration, sprinting, sailing and horse riding. This one has a single
slider that shifts everything together, so it feels like it was natively part of
the game, the way CD Projekt RED would have implemented it. If you want per
state control, use FOV Tweak instead.

The code has drifted quite a bit since. The FOV logic now sits in one place on
CR4Player instead of being copied into every state file, the slider applies as
soon as you move it, and mounting and dismounting are covered by a timer because
those states have no script of their own here.

## Installing

Copy the contents into your Witcher 3 folder, then add modAdjustableFOV.xml to
dx12filelist.txt (or dx11filelist.txt). Menu Filelist Updater will do that part
for you.

Only horseRiding.ws overlaps with
[Smooth Mount Dismount](https://www.nexusmods.com/witcher3/mods/7265), so use
Script Merger if you run both.

MIT licensed.
