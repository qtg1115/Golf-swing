# Brave Kid: School Story

A Roblox game where a new kid goes to school and deals with bullies by **running, hiding, or standing up to them**. Going to class raises your level, and items from the school shop make you stronger.

Everything in the game is in English.

## Play it in Roblox Studio

1. Download `SchoolSimulator.rbxlx` from this repository.
2. In Roblox Studio choose **File → Open from File** and pick that file.
3. Press **Play**.

You start on the blue pad at the front gate. The goal for your current chapter is always shown on the left side of the screen.

If Studio shows `HTTP 403` for a recent place on the home screen, close that message and open the file instead.

## Story

1. Talk to **Mr. Park** at the front gate
2. Find **Mia** by the lockers, she gives you a Friend's Note
3. Escape or stand up to **Rex** in the hallway
4. Attend 2 classes to level up
5. Buy the **Fast Sneakers** at the school shop
6. Help **Sky** at the playground
7. Report back to Mr. Park and get the **Courage Badge**
8. Face **Max**, the toughest bully

## Controls

- **W A S D** to move
- **E** to interact when you are near a person or object
- Buttons appear on screen when a bully catches you

## What to do at school

| Place | What happens |
| --- | --- |
| Classrooms | Join class for XP, coins, and better grades |
| Cafeteria | Eat at lunch to refill energy and courage |
| School shop | Buy candy, juice, a whistle, sneakers |
| Playground | Play, and take gym class |
| Library | Study to raise every grade |
| Nurse office | Rest and recover |
| Green bushes and lockers | Hide from bullies |

## Bully encounters

When a bully reaches you, four choices appear:

- **Run away** — get far enough away before they catch up (sneakers help a lot)
- **Hide** — only works when you are standing near bushes or lockers
- **Stand up** — you win when your stand-up power is at least their power
- **Items** — the Friend's Note escapes instantly, the Whistle adds +5 power

Stand-up power = your level + Courage Badge + friends you helped.

## Items

| Item | Effect |
| --- | --- |
| Candy Bar | +25 energy |
| Brave Juice | +30 courage |
| Lunch Box | energy and courage |
| Study Book | better grades and XP |
| Whistle | +5 power during an encounter |
| Friend's Note | escape an encounter |
| Fast Sneakers | run faster |
| Courage Badge | +3 power, always on |

## Editing the game

You can change the game by editing these files, then rebuilding.

| To change | File |
| --- | --- |
| Story, bullies, items, levels | `src/shared/Config.luau` |
| The school map | `src/server/SchoolBuilder.luau` |
| Bully behaviour | `src/server/BullyService.luau` |
| Class, shop, task rules | `src/server/GameService.luau` |
| On-screen UI | `src/client/Hud.luau` |

Rebuild the place file after editing:

```bash
rojo build -o SchoolSimulator.rbxlx
```

Or use live sync with the Rojo Studio plugin (`rojo serve`). Plugin setup is described in `STUDIO.md`.
