from pathlib import Path
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design'; OUT.mkdir(exist_ok=True)
doc=Document(); sec=doc.sections[0]
sec.page_width=Inches(8.5); sec.page_height=Inches(11)
sec.top_margin=sec.bottom_margin=Inches(.65)
sec.left_margin=sec.right_margin=Inches(.8)
for name in ['Normal','Title','Subtitle','Heading 1','Heading 2','Heading 3']:
    style=doc.styles[name]; style.font.name='Calibri'; style.font.color.rgb=RGBColor(0,0,0)
    style.paragraph_format.space_after=Pt(5)
doc.styles['Normal'].font.size=Pt(11)
doc.styles['Normal'].paragraph_format.line_spacing=1.08
doc.styles['Title'].font.size=Pt(32)
doc.styles['Heading 1'].font.size=Pt(22)
doc.styles['Heading 2'].font.size=Pt(13)
doc.styles['Subtitle'].font.size=Pt(14)
header=sec.header.paragraphs[0]; header.text='BULLET MANIA    |    GAME DESIGN DOCUMENT'
header.style='Normal'; header.runs[0].font.size=Pt(9)
footer=sec.footer.paragraphs[0]; footer.alignment=WD_ALIGN_PARAGRAPH.RIGHT
footer.add_run('Version 1.0  |  8 October 2026  |  ')
field=OxmlElement('w:fldSimple');field.set(qn('w:instr'),'PAGE');footer._p.append(field)
for r in footer.runs:r.font.size=Pt(9)

def p(text):return doc.add_paragraph(text)
def h(text):doc.add_heading(text,2)
def page(n,title):
    heading=doc.add_heading(f'{n:02d} {title}',1); heading.paragraph_format.page_break_before=True
def table(headers,rows,widths):
    tab=doc.add_table(rows=1,cols=len(headers));tab.alignment=WD_TABLE_ALIGNMENT.CENTER;tab.autofit=False
    for col,w in zip(tab.columns,widths):col.width=Inches(w)
    for i,text in enumerate(headers):tab.rows[0].cells[i].text=text
    for row in rows:
        cells=tab.add_row().cells
        for i,value in enumerate(row):cells[i].text=str(value)
    for ri,row in enumerate(tab.rows):
        trpr=row._tr.get_or_add_trPr()
        if ri==0:
            repeat=OxmlElement('w:tblHeader');trpr.append(repeat)
        no_split=OxmlElement('w:cantSplit');trpr.append(no_split)
        for ci,cell in enumerate(row.cells):
            cell.width=Inches(widths[ci]);cell.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
            tcpr=cell._tc.get_or_add_tcPr()
            shade=OxmlElement('w:shd');shade.set(qn('w:fill'),'142338' if ri==0 else ('F1F4F7' if ri%2==0 else 'FFFFFF'));tcpr.append(shade)
            borders=OxmlElement('w:tcBorders')
            for edge in ['top','left','bottom','right']:
                el=OxmlElement('w:'+edge);el.set(qn('w:val'),'single');el.set(qn('w:sz'),'4');el.set(qn('w:color'),'D9D9D9');borders.append(el)
            tcpr.append(borders)
            margins=OxmlElement('w:tcMar');
            for edge in ['top','left','bottom','right']:
                el=OxmlElement('w:'+edge);el.set(qn('w:w'),'65');el.set(qn('w:type'),'dxa');margins.append(el)
            tcpr.append(margins)
            for para in cell.paragraphs:
                para.paragraph_format.space_after=Pt(2);para.paragraph_format.space_before=Pt(2)
                for r in para.runs:
                    r.font.size=Pt(10);r.font.color.rgb=RGBColor(255,255,255) if ri==0 else RGBColor(0,0,0);r.bold=ri==0
    gap=doc.add_paragraph(); gap.paragraph_format.space_after=Pt(0); gap.paragraph_format.line_spacing=Pt(3); gap.add_run(' ').font.size=Pt(1)

doc.add_paragraph('Bullet Mania',style='Title')
doc.add_paragraph('Game Design Document',style='Subtitle')
p('Version 1.0\n8 October 2026\nPrepared by\nDelon Villarer Agnata  |  Student ID 160423164\nHenry Hilton  |  Student ID 160423172\nPlatform Windows PC\nEngine GameMaker')
h('Document purpose')
p('This document explains how Bullet Mania is played, how its systems interact, and what remains to be tested. It is a blueprint for maintaining the current prototype and planning its next development pass.')
p('Bullet Mania is a single-player neon bullet hell in which a pilot dodges patterned projectiles, upgrades a continuously firing ship, and defeats three bosses across three sectors. Success depends on reading patterns, using a small collision core, and deciding when to spend defensive resources.')
p('Status: implemented prototype. The project has previously compiled with GameMaker runtime 2026.0.0.23 for Windows VM. Full-run playtesting, visual verification in the live game, and balance tuning remain outstanding. This document does not claim those checks have passed.')
h('Reading guide')
p('Sections 1–10 follow the structure in GCD Ch7 GDD. Rules and numeric values describe the current code unless marked Proposed. Audience assumptions, narrative framing, and audio direction are design proposals rather than validated research or shipped features.')
for t in ['1 Game overview    2 Vision and experience    3 Target player','4 Gameplay    5 Mechanics and systems    6 Level design','7 Story and world    8 Visual and audio direction','9 Interface and controls    10 Prototype plan']:p(t)

h('Source and revision record')
p('Reference structure: GCD - Ch7 - GDD.pptx, Chapter 7 Game Design Document, Informatics Engineering, Universitas Surabaya; slides 18–41 inform the section structure and specificity. Its examples are teaching material, not Bullet Mania features.')
p('Project evidence: Bullet Mania.yyp; rooms/Room1/Room1.yy; objects/obj_game/Create_0.gml, Step_0.gml, Draw_0.gml; README.md; exported character roster. Version 1.0 records the prototype as inspected on 8 October 2026. Update this document after testing or changing rules.')


page(1,'Game overview')
p('Bullet Mania is a top-down arcade shooter built around survival, close calls, and short-term upgrades. The player controls a cyan ship inside a fixed arena while its weapons fire upward automatically. Six enemy formations and three bosses form one complete run.')
table(['Field','Design'],[
('Genre','Bullet hell arcade shooter'),('Perspective','Top-down 2D, fixed arena'),('Players','One local player'),('Primary platform','Windows PC with keyboard and optional mouse for menus'),('Engine and language','GameMaker and GML'),('Game space','One 1366 × 768 room; three logical sectors'),('Mode','One complete-run arcade mode with local score rankings'),('Run duration','Variable; no validated duration target yet'),('Distribution','Not decided; no payments or real-money shop implemented')],[1.6,5.3])
h('Scope')
p('The prototype contains movement, focus, dash, automatic shooting, pulses, pickups, three bosses, two shops, username entry, a local leaderboard, key rebinding, frame-rate caps, VSync settings, pause, and retry. All character and environment art is drawn from primitives in code.')
h('Limits')
p('There is no online leaderboard, multiplayer, narrative campaign, audio, gamepad support, or permanent upgrade progression. Persistent data covers settings, the best-score record, and the local top ten. Purchases and credits expire when a new run begins.')

page(2,'Vision and experience')
p('Bullet Mania should make a dense projectile field feel readable enough to learn. The player looks for a route through a pattern, uses focus for precise movement, and saves dash or pulse for the moments when a route closes. Automatic shooting keeps attention on positioning instead of repeated attack input. The white collision core allows near misses around the larger ship silhouette and supports the feeling of escaping by a small margin.')
p('The difficulty develops through distinct encounters rather than a larger world map. Regular formations teach aimed volleys, rings, and fans. Each boss combines those ideas differently and changes attacks as health falls. A cleared boss grants recovery and opens a supply dock, giving the player a deliberate pause before the next sector. Purchases should reflect the current run: repair damage, reinforce defense, or improve the dash reactor.')
p('The intended emotional rhythm is tension during combat, relief at a clear, consideration in the shop, and motivation to retry after the result. These are experience goals to validate with players. The neon presentation supports that rhythm through contrasting colors, hit flashes, trails, and announcements. Effects should communicate events without hiding incoming bullets. The game should remain approachable to a player learning bullet hell while giving score-focused players reasons to practice close passes and resource efficiency.')
h('Design pillars')
p('Readable danger. Distinguish the ship core, round hostile bullets, and labeled diamond pickups. Boss warnings communicate where a rain curtain will fall.')
p('Precise survival. Focus, dash, shields, and pulses offer different responses to pressure. Their limits make timing and positioning matter.')
p('A run that changes through choices. Pickups and shop purchases improve the current ship. Local rankings provide a repeatable goal after the final result.')
h('Decision filter')
p('A new feature should strengthen pattern reading, survival decisions, or meaningful run progression. A feature that does not support these goals should wait until the current run is proven enjoyable and stable.')

page(3,'Target player')
p('Proposed audience: PC players who enjoy arcade shooting, repeated attempts, recognizable attack patterns, and score comparison on a shared machine. The design suits short play sessions, although actual run duration still needs measurement.')
table(['Dimension','Assumption to test'],[('Age','Teen and adult players; no formal age classification has been assessed'),('Experience','Comfortable with keyboard movement; bullet hell experience optional'),('Context','Solo play on a Windows computer, including shared classroom or home use'),('Preferences','Responsive controls, visible feedback, mastery through repetition'),('Motivation','Beat a boss, complete a run, improve a named local record')],[1.5,5.4])
h('Player persona')
p('A student plays between other activities on a laptop. They understand WASD but are new to dense bullet patterns. They need a visible hitbox, a simple manual, and a way to slow movement. After several attempts, they want to recognize the Helix Warden pattern and see their name climb above a friend’s score on the same computer. This is an illustrative persona, not a researched participant.')
h('Learning and accessibility')
p('The flight manual explains default actions and supplies. Key rebinding supports alternative keyboard layouts. Menu navigation remains available through fixed keys and mouse input, and frame-rate settings accommodate different hardware.')
p('Color is supported by shape and text: pickups use letters, shields use rings, and boss identities use distinct silhouettes. Proposed improvements include adjustable flash intensity, reduced camera shake, clearer tutorial prompts, and gamepad navigation. These options are not currently implemented.')
h('Validation questions')
p('Can a first-time player find their collision core? Do they distinguish an enemy bullet from a pickup? Can they recover after a failed attempt without instructions from the developer? Does a local leaderboard encourage another run?')

page(4,'Gameplay')
h('Core loop')
p('Read the incoming pattern, move or focus through a gap, keep firing automatically, and use dash or pulse when necessary. Defeat enemies to earn score, credits, and supplies. Clear a boss, recover, make shop purchases, and continue to the next sector.')
# A readable flow figure authored from code, without generated imagery.
im=Image.new('RGB',(1400,370),'white');d=ImageDraw.Draw(im);font=ImageFont.truetype('C:/Windows/Fonts/calibri.ttf',26)
labels=['Read pattern','Dodge and fire','Earn rewards','Defeat boss','Shop and upgrade']
for i,label in enumerate(labels):
    x=10+i*280;d.rounded_rectangle((x,45,x+245,155),radius=10,fill='#eef3f8',outline='#142338',width=3)
    d.text((x+122,100),label,font=font,fill='black',anchor='mm')
    if i<4:d.line((x+245,100,x+278,100),fill='#142338',width=4);d.polygon([(x+278,100),(x+266,93),(x+266,107)],fill='#142338')
d.line([(1250,160),(1250,255),(130,255),(130,165)],fill='#142338',width=3)
d.text((700,295),'Repeat for the next sector  •  Final boss clear leads to victory',font=font,fill='black',anchor='mm')
im.save(OUT/'gameplay_loop.png');doc.add_picture(str(OUT/'gameplay_loop.png'),width=Inches(6.9))
h('Run flow')
p('Launch → Pilot Sign-In → Main Menu → Sector 1 → Shop → Sector 2 → Shop → Sector 3 → Result. Losing all hull points ends the run at any combat stage. Results allow retry, leaderboard viewing, or returning to the main menu. Pause freezes simulation and opens Resume, How to Play, Options, and Main Menu.')
h('Win and loss')
p('Victory requires defeating Prism Engine after the earlier sectors. Defeat occurs when hull reaches zero. Each new run starts with five hull points, three pulses, weapon level 1, no shields, no dash upgrades, and zero credits. A result submits the run to the local leaderboard; abandoning a run does not.')
h('Score rules')
p('Regular enemies award 150, 250, or 350 points by type. Bosses award 8,000, 10,000, and 12,000. Victory adds 1,000 points per remaining hull point. A capped pickup awards 500 points. Graze awards one point per simulation tick while a bullet is within 24 pixels but outside the collision radius, provided the player is neither invulnerable nor dashing. Graze is not limited to one reward per bullet in the current code.')

page(5,'Mechanics and systems')
table(['Mechanic','Rule and constraint'],[('Movement','5.3 pixels per 60 Hz tick; normalized diagonals. Player center is clamped to x 42–1324 and y 120–722.'),('Focus','Hold Shift by default. Speed becomes 2.5 pixels per tick; show an extra outline around the collision core.'),('Dash','Space by default. 11 movement ticks at 15 pixels per tick along the last movement direction. Base recharge 90 ticks; reactor upgrades reduce it to 75 or 60.'),('Shooting','Automatic. Level 1 fires two shots every 5 ticks; level 2 adds a center shot; level 3 fires five shots every 4 ticks. Each hit deals 5 damage.'),('Pulse','X by default. Spend one pulse, clear hostile bullets, and deal 130 damage to eligible enemies. Boss entry and phase breaks block damage.'),('Collision','A hit occurs within bullet radius plus the 4-pixel player core. Hull hit costs one point and gives 110 ticks of invulnerability.'),('Shield','Absorb a hit before hull damage; consume one charge and grant 75 ticks of invulnerability. Maximum two charges.')],[1.1,5.8])
h('Supplies')
p('W upgrades the weapon to level 3; S adds a shield up to two; + restores hull up to five; P refills pulses up to three. Every third regular kill guarantees a pickup. Other kills have a 15% drop chance. Kill 3 and kill 6 guarantee weapon cores. First and second bosses also drop W and S.')
p('Pickups drift down by 1.15 pixels per tick, attract toward the player within 125 pixels, collect within 26 pixels, and expire after ten seconds or leaving the lower arena. They blink during their final two seconds. Boss docking automatically secures remaining pickups.')
h('Economy')
table(['Purchase','Credits','Limit'],[('Weapon level',200,'3'),('Shield charge',100,'2'),('Hull repair',75,'5'),('Pulse refill',125,'3'),('Dash reactor',175,'2 upgrades')],[3.4,1.1,2.4])
p('Regular kills earn 25, 35, or 45 credits; bosses earn 250, 350, or 450. Credits are separate from score. The shop rejects capped or unaffordable purchases without deducting funds. Supplies, reactor upgrades, and credits persist only within the run.')

page(6,'Level design')
p('Three logical sectors reuse one fixed arena. The background scrolls visually, but the camera and collision space remain fixed. Each sector contains two formations followed by one boss. The combat area sits below the HUD; player movement is restricted to the lower playfield.')
table(['Sector','Formation sizes','Boss health','Challenge'],[('1','4 then 5','Helix Warden 1,000','Aimed triples, radial rings, and opposing spirals'),('2','6 then 7','Ion Tempest 1,300','Read rain warnings while avoiding aimed fans'),('3','8 then 9','Prism Engine 1,600','Combine ring gaps, targeted volleys, and spiral timing')],[.65,1.4,1.8,3.05])
h('Enemy roster')
p('Aimed Shooter is a pink diamond with 35 health and a targeted triple volley. Ring Emitter is a violet diamond with 35 health and ten-shot radial rings. Fan Shooter is a gold diamond with 85 health and sweeping five-shot fans. Formation positions spread across the arena and oscillate horizontally. Attack intervals become shorter in later stages.')
h('Boss phases')
table(['Boss','Phase 1','Phase 2','Phase 3'],[('Helix Warden','Opposing three-arm spirals','Two-speed radial petals','Faster spirals plus aimed bursts'),('Ion Tempest','Warned rain with a safe corridor','Rain plus aimed fans','Double curtains plus fans'),('Prism Engine','Rotating 18-shot rings','Aimed fans and slow rings','Four spiral arms and periodic rings')],[1.45,1.8,1.8,1.85])
p('Phases advance at two-thirds and one-third health. Entry lasts two seconds. A phase shift clears bullets and grants a one-second attack break. Ion rain warns for 50 ticks, with a corridor centered on the player’s position at warning time; the corridor is safe from the curtain, not all attacks.')
p('Every boss clear removes hostile bullets, restores one hull and one pulse within their caps, and gives two seconds of invulnerability. The first two clears lead to a shop after the recovery interval. Selecting Next Sector adds a 1.5-second preparation gap.')
h('Balance issue to resolve')
p('Regular formations attempt to retreat after 25 seconds. The current movement code also pulls them toward their formation height each tick, which may prevent a clean exit. Verify and correct this before relying on a timeout to advance stages.')

page(7,'Story and world')
h('Narrative framing')
p('Proposed fiction: the pilot enters a simulated neon defense network whose three guardian systems have locked down the route. Helix Warden controls rotating energy paths, Ion Tempest controls the falling storm, and Prism Engine coordinates the final reactor. The pilot must disable all three to restore the signal.')
p('This framing gives the existing bosses and sector progression a shared purpose without introducing dialogue or cutscenes. It is not currently presented as a story in the game. The implemented experience communicates its setting through names such as Pilot Sign-In, Signal Lost, Storm Cleared, and Neon Supply.')
h('World rules')
p('The arena is an abstract digital combat space. Geometry represents machines and energy, rather than living characters. Projectiles follow readable repeated patterns; supply cores improve the pilot’s ship during the current attempt. A loss ends the signal, and a retry starts a fresh simulation with the same pilot identity.')
h('Locations')
p('Sector 1 is associated with Helix Warden and rotating patterns. Sector 2 introduces the Ion Tempest rain corridor. Sector 3 culminates in the Prism Engine reactor. All three currently share the same visual arena. Neon Supply is a menu-based dock between the first two sectors, not a separate explorable location.')
h('Delivery and scope')
p('Use brief labels, boss names, and result text to carry the theme. Proposed additions are a one-sentence introduction and short sector subtitles. A branching plot, voiced characters, cutscenes, and dialogue systems are outside the current scope. Gameplay information must remain readable without understanding the fiction.')

page(8,'Visual and audio direction')
p('The art direction uses thin neon outlines, geometric silhouettes, luminous cores, and a midnight-blue grid. All visuals are authored with drawing primitives. Imported character art and AI-generated assets are not used.')
table(['Color','RGB','Role'],[('Cyan','40 240 255','Player outline, weapon cores, Prism Engine'),('Hot pink','255 55 155','Aimed enemies, repair cores, danger accents'),('Violet','155 90 255','Helix Warden, shields, rings'),('Warm gold','255 210 80','Ion Tempest, fan enemies, pulses, credits'),('Midnight blue','6 8 22','Background and negative space')],[1.25,1.25,4.4])
roster=ROOT/'previews/characters/bullet_mania_roster.png'
if roster.exists():doc.add_picture(str(roster),width=Inches(5.3))
p('Character reference sheet. These are enlarged static exports of the current code-drawn models; the live game rotates and animates them.')
h('Motion and readability')
p('Crossfades, sliding buttons, ship banking, dash echoes, projectile streaks, impact rings, pickup lights, and boss health feedback express state changes. Effects must preserve visible bullet paths and the white collision core. Test large pulse flashes and overlapping projectile glows for readability.')
h('Audio direction')
p('No audio is implemented. Proposed: original synth loops that intensify for bosses, short cues for pickups and purchases, and distinct alerts for damage, dash readiness, and phase changes. Important warnings must remain visually understandable when muted. Audio creation and licensing remain a future task.')

page(9,'Interface and controls')
p('Pilot Sign-In appears at every launch. Names are non-empty, limited to 12 characters, and normalize to uppercase. The identity stays active through retries. Main Menu contains Start Run, How to Play, Options, Leaderboard, and Quit Game.')
table(['Action','Default input'],[('Move','WASD or arrow keys'),('Focus','Hold Shift'),('Dash','Space'),('Pulse','X'),('Pause','Escape'),('Retry after result','R'),('Menu select and confirm','Arrows or W/S; Enter or Space; mouse click'),('Name submission','Enter or Enter Arcade button')],[3.1,3.8])
h('Screen functions')
p('The top HUD shows score, best score, hull, pulses, dash readiness, weapon level, shields, and credits. Boss encounters add a name, phase indicator, and health bar below it. The player’s white dot marks the collision core. Supply notices appear near the bottom of the arena.')
p('Options contains Key Bindings, Frame Rate, V Sync, Reset Best Score, and Back. Binding capture waits for the activation key to release, then accepts a new key; duplicates swap assignments. Escape cancels capture. Settings save automatically. FPS choices are 30, 60, 120, 144, and 240; VSync defaults on and may constrain achieved FPS to the monitor.')
p('Reset Best Score requires confirmation with Cancel initially selected. It clears the saved scalar record but does not erase the separate leaderboard. This distinction should be explained clearly in a future UI pass.')
h('Leaderboard and results')
p('The local top ten keeps the highest completed-run score for each normalized name and records whether that run won. It highlights the active pilot. Tied scores keep their existing order; a tied win can replace a defeat status for that pilot. There is no online service or account authentication. Result screens show score and pilot, then offer retry, leaderboard, or main menu.')
h('Layout reference')
p('HUD occupies roughly y 0–90. The arena boundary runs from x 24–1342 and y 100–744. Menus place text and selectable rows on the left, with an animated reactor motif and contextual status on the right. Animated row positions and mouse hit areas use the same offset.')

page(10,'Prototype plan')
h('Implemented baseline')
p('The prototype already contains the full three-sector run and supporting menus. The next milestone is a verified playable build, not adding more content. Preserve the existing code-drawn art constraint and document changes to timing or economy alongside their tests.')
table(['Priority','Work and acceptance check'],[('1','Launch, enter a name, finish or lose a run, and verify the score survives a relaunch. Check ten-entry ordering, duplicate names, and ties.'),('1','Play every boss phase. Confirm entry immunity, phase breaks, rain warnings, damage, win/loss, and shop transitions.'),('1','Verify formation retreat; ensure no encounter can stall permanently. Check dash immunity on its final movement tick.'),('2','Buy each shop item at normal, capped, and insufficient balances. Verify no double charges and correct new-run resets.'),('2','Test 30/60/120/144/240 FPS and VSync on actual hardware. Compare movement distance, firing cadence, cooldowns, and phase timing.'),('2','Test keyboard and mouse navigation, key swaps, Escape recovery, reset confirmation, and crossfades at each frame cap.'),('3','Run novice playtests; record deaths, completion time, pulse use, pickup clarity, and shop choices. Tune with observations.'),('3','Design and add original audio; consider reduced flashes and camera shake controls.')],[.7,6.2])
h('Technical implementation')
p('GameMaker uses one obj_game controller in Room1. Create defines systems and a fixed-step simulate method; Step handles menus and elapsed-time accumulation; Draw renders primitives. Simulation runs at 60 Hz, while visual menu timing uses elapsed time. Frame deltas cap at 100 ms to limit catch-up after stalls. Movement is not interpolated between simulation ticks, so higher render caps alone do not guarantee smoother entity motion.')
p('bullet_mania.ini stores controls, display settings, and the best-score record. bullet_mania_leaderboard.ini stores the local top ten in GameMaker’s sandbox. Credits, shop upgrades, supplies, and combat state reset for a new run.')
for style in doc.styles:
    for border in list(style.element.iter(qn('w:pBdr'))): border.getparent().remove(border)
for para in doc.paragraphs:
    for border in list(para._p.iter(qn('w:pBdr'))): border.getparent().remove(border)
doc.save(OUT/'Bullet Mania Game Design Document.docx')
print(OUT/'Bullet Mania Game Design Document.docx')
