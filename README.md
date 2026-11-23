# Bullet Mania

A neon bullet hell built entirely from GameMaker drawing primitives. No imported art or AI-generated assets.

Open `Bullet Mania.yyp` in GameMaker and press F5 to play.

Every application launch opens Pilot Sign-In. Enter a non-empty name of up to 12 characters, then press Enter or click Enter Arcade. Names support letters, digits, spaces, hyphens, and underscores; they normalize to uppercase so spelling case does not create separate players. The same pilot stays active through retries during that session.

The **Leaderboard** is available from the main and results menus. It stores the top ten pilots on this computer, keeping each name's best score from a completed run (victory or defeat). The active pilot is highlighted, and each entry shows whether that run cleared the game. Equal scores retain their previous ordering; a tied victorious run can replace that pilot's defeat status. Scores save immediately to `bullet_mania_leaderboard.ini` in GameMaker's local sandbox. Abandoned runs are not submitted. The leaderboard is local to this installation and is separate from the existing Best Score reset option.

The main menu has Start Run, How to Play, and Quit Game buttons, an animated perspective grid, and an orbiting neon bullet sculpture. Navigate with Up/Down (or W/S) and Enter/Space, or use the mouse. The controls screen is also available while paused. Pause and results menus offer resume/retry and a return to the main menu.

## Controls

Choose **Options → Key Bindings** from the main or pause menu to remap movement (including the alternate arrow-key slots), focus, dash, pulse, pause, and the retry shortcut. Select a row with the keyboard or mouse, confirm, release the activation key, then press the new key. Duplicate assignments swap the two affected bindings. Escape cancels capture or returns to the previous menu; use Restore Defaults to restore Escape as the pause key. Changes save automatically in the local INI alongside the best score and persist between runs. The HUD and flight manual show current bindings.

**Options → Reset Best Score** opens a confirmation screen with Cancel selected initially. Confirm Reset sets the saved best score to zero immediately, preserving custom controls and the current run's score. Completing a run can establish a new record. Escape cancels the confirmation. Back returns through Options to the originating main or pause menu.

**Options → Frame Rate** cycles through 30, 60 (default), 120, 144, and 240 FPS. **V Sync** toggles vertical synchronization (on by default). Use Enter/click to cycle, or Left/Right on a selected setting. Settings apply immediately and save between sessions. VSync and hardware performance can limit the achieved frame rate below the requested cap.

Gameplay uses a fixed 60 Hz simulation with elapsed-time accumulation, independent of the rendering cap. Movement, bullet speeds, boss patterns, cooldowns, and pickup lifetimes keep their original timing. Pressed dash/pulse inputs are queued until the next simulation tick and consumed once, including when a rendered frame contains several ticks. Pause and scene transitions discard accumulated simulation time. Menu animation uses elapsed time. Individual frame deltas are capped at 100 ms to avoid an unbounded catch-up after a stall.

Menu navigation stays on arrows/W/S and Enter/Space, with mouse support. Escape resumes from the pause menu regardless of the gameplay pause binding. The table below lists defaults.

| Key | Action |
| --- | --- |
| Enter | Start |
| WASD / arrows | Move |
| Shift | Focus: move slowly and show the hitbox |
| Space | Invulnerable dash, with a 1.5-second cooldown |
| X | Pulse: clear bullets and damage enemies (three per run) |
| Escape | Pause / resume |
| R | Restart after defeat or victory |

Shooting is automatic. The white dot at the ship's center is its collision core. Survive five sectors (20 stages), each with three formations followed by a boss. Close passes earn graze points. Remaining hull adds a victory bonus. Best score is saved locally using GameMaker's sandbox.

## Sector shop

The Neon Supply shop opens after each of the first four bosses, following the usual two-second recovery interval. Regular enemy kills grant 25/35/45 credits by enemy type; the five bosses grant 250/350/450/550/650. Credits are separate from score, shown in the HUD, and reset on a new run.

| Purchase | Credits | Effect |
| --- | --- | --- |
| Weapon upgrade | 200 | One weapon level, up to level 3 |
| Shield charge | 100 | One shield charge, up to 2 |
| Hull repair | 75 | One hull point, up to 5 |
| Pulse refill | 125 | One pulse, up to 3 |
| Dash reactor | 175 | Reduce recharge by 0.25 seconds; two upgrades lower it from 1.5 to 1 second |

Full or unaffordable items are dimmed and reject purchases without charging credits. Gameplay freezes while shopping. Uncollected supplies are secured automatically on docking. Choose Next Sector to continue; the shop cannot be reopened during that sector. All upgrades last for the current run.

## Stages

| Sector | Formations in order | Boss |
| --- | --- | --- |
| Neon Frontier | Arc Guard, Crosswind, Diamond Relay | Helix Warden |
| Ion Passage | Crosswind, Diamond Relay, Arc Guard | Ion Tempest |
| Prism Belt | Diamond Relay, Arc Guard, Crosswind | Prism Engine |
| Echo Foundry | Arc Guard, Diamond Relay, Crosswind | Echo Sentinel |
| Nova Core | Crosswind, Arc Guard, Diamond Relay | Nova Crown |

Arc Guard uses staggered stationary rows with individual horizontal drift. Crosswind sends alternating rows sweeping in opposing directions, adding straight lanes to aimed shooters. Diamond Relay arranges ships around a central point with bobbing movement and ring accents on fan shooters. Each sector adds one ship (5 through 9) and modestly increases firing pressure; formations retreat after 25 seconds if not destroyed. Grid colors follow the sector's boss palette.

## Boss encounters

| Boss | Visual | Phase 1 | Phase 2 | Phase 3 |
| --- | --- | --- | --- | --- |
| Helix Warden | Violet diamond with twin cores | Opposing three-arm spirals | Layered radial petals | Faster spirals with aimed bursts; all phases alternate with pinwheels |
| Ion Tempest | Gold pentagon with wide rails | Bullet rain with a warned escape corridor | Rain plus aimed fans and alternating diagonal sweeps | Double curtains plus fans and sweeps |
| Prism Engine | Cyan hexagonal reactor | Rotating rings | Aimed fans mixed with slow rings | Four spiral arms with periodic rings; all phases alternate with edge blooms |
| Echo Sentinel | Pink heptagon with shutter pods | Side walls with a warned horizontal gap | Shutters plus slow rings | Faster shutters and rings |
| Nova Crown | Gold octagon with orbiting crown | Warned, locked fan plus slow ring | Wider fan and denser ring | Largest fan with shorter recovery |

Boss phases change at two-thirds and one-third health. Entry grants two seconds to reposition; phase transitions clear bullets and grant a one-second attack break. Bosses cannot take damage during entry or phase breaks. Ion Tempest marks its safe corridor with cyan lines before launching rain; its other projectiles can still cross that corridor. Boss defeats clear projectiles, restore one hull point and one pulse (up to their starting limits), and grant two seconds of player invulnerability. Echo Sentinel marks its horizontal gap before firing both side walls. Nova Crown shows its locked fan direction before release; neither warning follows subsequent player movement. Supplementary rings can cross shutter gaps. Defeat all five bosses to win.

## Power-ups

Supplies are labeled neon diamonds, distinct from round hostile bullets. Fly within 125 pixels to attract them; they drift down, expire after ten seconds, and blink during their final two seconds. Every third defeated regular enemy drops a supply; other kills have a 15% bonus-drop chance. The third and sixth regular kills guarantee weapon cores. The first four bosses also drop a weapon and shield core.

| Core | Effect | Limit |
| --- | --- | --- |
| W / cyan | Upgrade auto-fire: twin shots, then triple shots, then faster five-shot spread | Level 3, lasts for the run |
| S / violet | Absorb one bullet hit and grant 1.25 seconds of invulnerability | Two charges |
| + / pink | Restore one hull point | Five hull |
| P / gold | Refill one pulse | Three pulses |

Collecting a supply at its limit awards 500 points instead. Upgrades reset on a new run; pause freezes pickup movement and expiry. The HUD shows weapon level and shield charges, and shield rings surround the ship. The flight manual explains each core.

The palette uses cyan, hot pink, violet, and warm yellow over midnight blue. Ships, enemy polygons, projectile glows, explosions, scrolling grids, and interface elements are all drawn in code.

Menu screens, run start/retry, pause/resume, and results use eased crossfades lasting about one-third of a second. Buttons slide in with staggered timing and smoothly brighten on selection. Input and gameplay wait until the transition completes; mouse hit areas follow the animated buttons. Previous-frame surfaces are released after the fade, with a plain fade fallback when the application surface is unavailable.

In-game animation includes ship banking, fading movement/dash echoes, shot streaks, expanding impact and pulse rings, orbiting pickup lights, enemy hit flashes, boss arrival growth, a trailing boss-health bar, animated announcements, and a dash recharge meter. Cosmetic effects preserve projectile positions and the player's white collision core.

Implementation lives in `objects/obj_game`: Create initializes the game and helper methods, Step handles gameplay, and Draw renders the scene and menus. Room1 contains one controller instance.

## Performance and checks

Hostile projectiles share a runtime sprite drawn from code primitives once: one sprite submission replaces four circle draws per bullet. No imported or AI-generated art is used. If surface creation fails, solid projectile circles remain visible. Generated sprites and transition surfaces are released on controller cleanup.

Hostile bullets, player shots, and sparks use constant-time swap removal rather than shifting arrays. Bullet/core collision and graze checks use squared distances. Only cosmetic sparks are capped (320); gameplay projectiles are never dropped to enforce a budget. Sideways player shots are also culled outside the arena.

Run `node tests/patterns.cjs` from the project root to check the 20-stage schedule, every boss phase for 60 simulated seconds, locked warnings, safe passage geometry at release, phase clearing, finite bullet positions, and swap-removal survivors. This harness executes the production attack functions with GameMaker math built-ins supplied in JavaScript; it does not measure rendering performance.

Validation: compiled with GameMaker runtime 2026.0.0.23 (Windows VM). A disposable native runtime fixture passed all 20 stage transitions, four shops, victory, generated-sprite creation, and a 4,000-bullet/60-tick simulation stress check without dropping projectiles. Real playtest frame rates and difficulty balance still need checking on target hardware. This version has no audio. The existing GDD and exported roster predate this expansion.
