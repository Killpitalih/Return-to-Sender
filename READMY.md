# Return to Sender

**By Andrei and Kiryl**

A top-down pixel-art action game where enemy projectiles are your weapon.
Explore forest ruins, cross a frozen wilderness, and defeat the final boss.

## How to play

You cannot damage enemies directly. Reflect their projectiles back at them!
Aim toward an enemy and time your reflection when a projectile is nearby.
Keep moving and watch the cooldown between reflections.

| Control | Action |
| --- | --- |
| W / A / S / D | Move |
| Mouse | Aim |
| Left click / Space | Reflect a nearby projectile |
| Escape | Close instructions or leave difficulty selection |

Choose **How to Play** in the main menu to see the instructions again.

## Difficulty

Choose Play, then select your starting health:

| Difficulty | HP |
| --- | ---: |
| Insane | 1 |
| Hard | 3 |
| Medium | 5 |
| Easy | 10 |

Your remaining health carries over between rooms.

## Your journey

1. Explore the forest ruins in room_02 and enter the enclosed arena.
2. Defeat its enemies, collect the key, and leave through the northern door.
3. Follow the winding path through the frozen wilderness in room_03.
4. Enter the final arena and defeat the boss to complete the game.

The red bar at the top shows remaining arena enemies or the boss's remaining
health, depending on the encounter.

## Running the game

### Browser build

Play through the game's hosted page. To test an exported web build locally,
open a terminal in the export folder and run:

```sh
python3 -m http.server 8000
```

Then visit **http://localhost:8000/index.html**. Keep all exported files
together. Opening index.html directly as a local file can cause loading errors.

### Desktop build

Extract the entire downloaded ZIP before launching the executable. Keep all
supplied files together, including any .pck file. Exported desktop builds do
not require the Godot editor.

### Source project

Developed with Godot 4.7. Import `project.godot` in a compatible Godot version,
allow the assets to import, and press F5 to start from the main menu.

Source: https://github.com/Killpitalih/Return-to-Sender

## Release review and remaining work

The core flow is implemented: menus, difficulty selection, arena progression,
room transitions, boss music, encounter bars, and the ending screen.
Automated checks cover these flows; a complete human playthrough of the latest
exported browser build is still needed to assess balance and navigation.

Priorities before the first public demo:

- **Clear projectiles during room changes.** Projectiles from the previous room
  currently survive the transition.
- **Improve the death restart.** Dying in room_03 currently restarts at room_02.
  Consider restarting the current room or adding a checkpoint.
- **Finish music handling.** Boss music currently does not loop. Returning to
  the main menu also needs an explicit background-music reset.
- **Add a pause menu.** Suggested actions: Resume, Restart Room, Main Menu,
  and music/sound controls.
- **Test the actual web release.** Complete a run without debug HP, then ask
  someone unfamiliar with the game to try Easy.
- **Prepare the release page.** Include gameplay screenshots, a cover image,
  controls, and any asset attribution required by the artwork/audio licenses.

## Credits

Game created by **Andrei and Kiryl**. Made with the **Godot Engine**.

Thank you for playing!
