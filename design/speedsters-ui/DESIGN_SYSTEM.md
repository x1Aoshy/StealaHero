# Steal a Hero × Speedsters — UI design system (source of truth for every artboard)

Extracted from the Speedsters game (Update2: World1Update3New.rbxl StarterGui, Shared/GamePanelStyle + StudUi,
design/spin-wheel-afk/*.dc.html). Every artboard MUST use these exact values and recipes. Reference artboard in the
same markup style: C:\Users\Aoshy´\Desktop\Update2\design\spin-wheel-afk\Main.dc.html (read it once).

## Voice
Chunky, glossy, cartoon-speedster Roblox UI: Fredoka One everywhere, every shape and every text outlined in ink
(#0B1B2D), vivid vertical glossy gradients on buttons, stud-texture headers, navy panels, gold highlights, lightning motifs.
Loud but tidy: strict alignment, generous gaps, big touch targets (>=44px), numbers in tabular figures.

## Tokens
| token | value |
|---|---|
| ink (all outlines + text strokes) | #0B1B2D |
| panel | #182644 |
| panel-deep (wells, pills, inputs) | #132038 |
| card | #324E6F |
| card-hi (hover/selected card) | #3E5F86 |
| header-blue | #287BCE |
| text | #FFFFFF |
| text-2 (labels) | #CFE3FF |
| text-3 (hints) | #9FB4D1 |
| gold (currency, highlights) | #FFD321 |
| gold-hi | #FFEA00 |
| cyan (speed) | #00E5FF |
| danger | #C82D2D |
| scrim | rgba(0,0,0,0.5) |
| game backdrop (mock world behind UI) | sky linear-gradient(180deg,#1F4A73 0%,#143253 55%,#0C1C30 100%); Steal a Hero ground = green studs #69D014 (rgb 105,208,20) band at the bottom: linear-gradient(180deg,#76DB1E 0%,#5FB812 100%) with the stud dot texture at 0.35 opacity |

Rarity (from the game's Directory.Rarity): Common #979797 · Uncommon #00FF00 · Rare #1990FF · Epic #C402FF ·
Legendary #FF8522 · Mythic #FF2B64 · Secret #2E2E2E (always shown with a rainbow gradient border: linear-gradient(90deg,#FF00C8,#FFEA01,#00D49F,#00FF33,#0084BC,#FF00DD)) · Eternal #FF1EF0 · Divine #FBFF00.

## Gradient families (vertical, rot 90 = top→bottom; exact Speedsters values)
Use as `background: linear-gradient(180deg, A 0%, B mid%, C 100%)` for fills and as the OUTER ring (see Button) for strokes.
| family | fill | ring (gradient stroke) | used for |
|---|---|---|---|
| green (buy/confirm/claim) | #F2FF00 0%, #36F800 49%, #0EA52C 100% | #A8FF80 0%, #06F81A 64%, #1E5909 100% | Buy, Claim, Hatch, Unlock |
| cyan (speed/treadmill) | #02FFEE 0%, #00E3F8 46%, #20ACB9 100% | #94F4FF 0%, #05F8F8 64%, #095859 100% | Treadmill, speed boosts |
| blue (index/progress) | #4BE6FF 0%, #00AFFF 48%, #005AFF 100% | #8CE8FF 0%, #2598E9 100% | Hero Index, progress fills |
| gold (money/premium) | #FFE85A 0%, #FFBE00 50%, #DE8000 100% | #FFF6B4 0%, #FFBE00 64%, #6E3A00 100% | Money, 2x Money, VIP |
| magenta (rebirth/eggs) | #FF0687 0%, #E405F8 46%, #9D12A7 100% | #FF9CFA 0%, #E405F8 64%, #540A59 100% | Eggs, Rebirth |
| purple (rare items) | #EE00FF 0%, #AA1CD2 78%, #6638A5 100% | #FF8CF9 0%, #FF47F6 51%, #D900FF 100% | Mythic/Epic shop cards |
| red (shop/danger) | #FF5A6E 0%, #FF0037 50%, #A8002A 100% | #FFA1A3 0%, #FF8688 51%, #FF272B 100% | Shop, villain alerts, close |
| orange (backpack/gear) | #FFC04D 0%, #FF580A 60%, #B83A00 100% | #FFE0A0 0%, #FF8A3D 64%, #6E2A00 100% | Backpack, Gear |
| lime (codes/gifts) | #F2FF7A 0%, #AFFF01 55%, #5E9E00 100% | #F7FFB0 0%, #AFFF01 64%, #2F5200 100% | Codes, Free gifts |
Diagonal promo banners (shop gamepasses, rot -28): VIP #FF9D00→#FFEA01 31%→#FF7700; 2x Speed #FF003C→#FF0550 30%→#FF058A;
2x Money #00FF26→#45FF01 31%→#00FF5E; Starter Pack #CC00FF→#EA00FF 30%→#9D00FF; Server boost rainbow #FF00C8,#FFEA01 31%,#00D49F 39%,#00FF33 60%,#0084BC 75%,#FF00DD.

## Type (Google Fonts: <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fredoka+One&amp;display=swap"> in <helmet>)
font-family: "Fredoka One", "Arial Rounded MT Bold", "Trebuchet MS", system-ui, sans-serif. One weight.
Ink text outline (copy exactly):
- OUTLINE-L (>=28px titles, big numbers): `text-shadow: 0 3px 0 #0B1B2D, 2px 2px 0 #0B1B2D, -2px 2px 0 #0B1B2D, 2px -2px 0 #0B1B2D, -2px -2px 0 #0B1B2D, 0 -2px 0 #0B1B2D;`
- OUTLINE-S (<28px): `text-shadow: 0 2px 0 #0B1B2D, 1px 1px 0 #0B1B2D, -1px 1px 0 #0B1B2D, 1px -1px 0 #0B1B2D, -1px -1px 0 #0B1B2D;`
Scale: window title 36 · section title 22 · big value 40 · button 22–28 · label 15–17 (letter-spacing .06em, uppercase for section labels, color text-2) · hint 13–14 (text-3). Numbers: font-variant-numeric: tabular-nums. Money uses $ and short suffixes (1.2K, 3.5M, 2B, 1T, 1Qa).

## Shape
Radii: window 18 · card 12 · button 12 · small chip 10 · pill 999 · round icon button 50%.
Borders (ink): window 4px · header bottom 4px · card 2px · button 3px · chip 2px.
Depth: window `box-shadow: 0 14px 0 rgba(0,0,0,0.28)`; card `box-shadow: inset 0 -4px 0 rgba(0,0,0,0.25)`;
button `box-shadow: inset 0 -6px 0 rgba(0,0,0,0.22), inset 0 3px 0 rgba(255,255,255,0.35), 0 5px 0 rgba(0,0,0,0.25)`.
STUDS texture (headers, buttons, cards): `background-image: radial-gradient(circle at 50% 45%, rgba(255,255,255,0.22) 0 28%, rgba(0,0,0,0.16) 31% 40%, transparent 43%); background-size: 22px 22px;`
— on a gradient fill combine: `background-image: <studs>, linear-gradient(...)` with `background-size: 22px 22px, 100% 100%`.

## Component recipes (inline styles; adapt sizes only)
WINDOW: outer `background:#182644; border:4px solid #0B1B2D; border-radius:18px; box-shadow:0 14px 0 rgba(0,0,0,0.28); overflow:hidden; display:flex; flex-direction:column;` centred over the scrimmed game backdrop.
HEADER: height 66–72, `background-color:#287BCE` + STUDS, `border-bottom:4px solid #0B1B2D`, title centred white 36px OUTLINE-L, optional sticker icon left of title, a colored family may replace blue (shop = red family, eggs = magenta, treadmill = cyan, index = blue).
CLOSE: 48×48 `<button aria-label="Close">` red family fill, 3px ink border, radius 12, inset depth, white X sticker icon; top-right inside header.
GLOSSY BUTTON (a real <button>): wrapper ring = 3px padding with the family RING gradient, radius 14, 3px ink border outside the ring; inner face = family FILL gradient + STUDS, radius 10, inset depth; label white Fredoka OUTLINE-L 24px, optional sticker icon left. Simplified acceptable form: single element with `border:3px solid #0B1B2D; background-image: STUDS, FILL; box-shadow: button depth` plus an inner 2px ring via `outline: 2px solid <ring mid color>; outline-offset:-5px`.
CARD: `background-color:#324E6F` + STUDS, 2px ink, radius 12, card depth; selected = card-hi + 3px gold ring.
PILL / WELL: `background:#132038; border:2px solid #0B1B2D; border-radius:999px` (value readouts, timers, prices).
CURRENCY CHIP: pill + gold coin/hex icon + gold value OUTLINE-S.
BADGE "!": 22px circle, red family fill, 2px ink, white "!" 15px, top-right of a button, slight rotate(10deg).
SIDEBAR BUTTON (Speedsters LeftSideBar): 76×76 square, radius 16, family FILL + STUDS, 3px ink border, ring, sticker icon 40px centred-top, label 14px OUTLINE-S under the icon overlapping the bottom edge; column gap 10.
PROGRESS BAR: track pill panel-deep 2px ink height 26; fill = blue family (or cyan for speed) + STUDS; text centred white OUTLINE-S.
RARITY TAG: chip radius 999, fill = rarity colour (Secret = rainbow), 2px ink, white 13px OUTLINE-S uppercase.
HERO PORTRAIT PLACEHOLDER (no hero images offline): rounded 12 tile, `background: radial-gradient(circle at 50% 35%, <hero primary lightened> 0%, <hero primary> 55%, <hero primary darkened> 100%)`, 3px border in rarity colour + 2px ink outside, centred sticker SVG of a speedster mask/cowl (simple stroke silhouette: head circle + eye slits + lightning bolt) in the hero SECONDARY colour with ink under-stroke, hero name under it. Label the set once somewhere as "portrait: live 3D viewport in game".

## Icons — sticker style (inline SVG only, never emoji)
24×24 viewBox, drawn twice: first `stroke="#0B1B2D" stroke-width="5.4"`, then same path `stroke="#FFFFFF"` (or gold/cyan) `stroke-width="2.2"`, both `fill="none" stroke-linecap="round" stroke-linejoin="round"`. Solid glyphs (bolt, coin) may use `fill` colour + ink stroke 2.4.
Paths (reuse): bolt `M13 2 4 14h7l-1 8 9-12h-7z` · close `M6 6l12 12 M18 6 6 18` · trophy `M8 21h8 M12 17v4 M7 4h10v5a5 5 0 0 1-10 0z M17 5h3v2a3 3 0 0 1-3 3 M7 5H4v2a3 3 0 0 0 3 3` · clock `M12 7v5l3 2 M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z` · star `M12 3l2 6 6 2-6 2-2 6-2-6-6-2 6-2z` · ticket `M4 6h16v4a2 2 0 0 0 0 4v4H4v-4a2 2 0 0 0 0-4z` · cart `M3 4h2l2.5 11h11L21 7H6.2 M9 20a1 1 0 1 0 0-.01 M18 20a1 1 0 1 0 0-.01` · egg `M12 3c3.5 0 6.5 5 6.5 10a6.5 6.5 0 0 1-13 0C5.5 8 8.5 3 12 3z` · book/index `M5 4h10a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3z M5 17a3 3 0 0 1 3-3h10` · gear `M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z M12 2v3 M12 19v3 M4.9 4.9l2.1 2.1 M17 17l2.1 2.1 M2 12h3 M19 12h3 M4.9 19.1 7 17 M17 7l2.1-2.1` · gift `M4 11h16v9H4z M3 7h18v4H3z M12 7v13 M12 7c-2-4-6-3-5 0 M12 7c2-4 6-3 5 0` · shield `M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z` · run (treadmill/speed) `M13 4a2 2 0 1 0 0-.01 M9 20l3-6 3 3v4 M7 10l3-3 4 1 3 3 M11 13l-4 1` · home/plot `M3 11l9-7 9 7 M5 10v10h14V10` · swap/trade `M7 7h13l-3-3 M17 17H4l3 3` · settings uses gear · codes uses ticket · rebirth `M4 12a8 8 0 0 1 14-5.3L20 5v5h-5 M20 12a8 8 0 0 1-14 5.3L4 19v-5h5` · lock `M6 11h12v9H6z M8 11V8a4 4 0 0 1 8 0v3` · arrow-up `M12 19V5 M5 12l7-7 7 7` · coin: circle r9 fill #FFD321 ink 2.4 + "$" path `M12 7v10 M14.5 9.5c0-1.2-1.1-2-2.5-2s-2.5.8-2.5 2 1 1.7 2.5 2 2.5 1 2.5 2.2-1.1 2-2.5 2-2.5-.8-2.5-2`.

## Motion (spec; show as annotated frames in the style guide, and as CSS in artboards only where noted)
- Window open: scrim 0→0.5 in 0.18s; window scale 0.6→1.06 (0.2s, Back-Out) →1.0 (0.08s). Close: 1.0→0.85 + fade 0.12s.
- Button: hover scale 1.05 (0.08s); press scale 0.92 + depth shadow collapses to 2px (0.06s); release spring back (0.18s Back-Out). Click sound ui-bubble-click.
- Badge "!": idle bounce every 2.4s (translateY -4px, rotate ±8°).
- Shine: a 40%-wide white diagonal band (opacity .45) sweeps across premium/gamepass buttons every 3s (0.6s).
- Money change: value scale pulse 1→1.18→1 (0.25s) + floating "+$X" in gold rising 40px and fading (0.8s).
- Toasts: slide down from top 0.25s Back-Out, hold 2.5s, slide up 0.2s.
- Legendary+ rarity: slow glow pulse on the rarity border (2s loop); Secret: rainbow hue rotate.
- Hatch: egg shake 3× (0.6s) → white flash (0.12s) → hero card pop 0.4→1.1→1 → rarity banner slides in.
Allowed CSS animation in artboards: define @keyframes in the <helmet><style> ONLY for: badge bounce, shine sweep, rarity glow. Keep them subtle.

## Steal a Hero UX to keep (screens, same flows, restyled)
HUD: left tools column (Shop, Hero Index, Rebirth, Trading, Free Gifts, Treadmill Speed Shop, 2x Speed), right tools (Group Reward, Starter Pack),
bottom-centre Money card + Speed card (+boosts), tabs "EGGS" (growing eggs list) and "HERO INDEX", backpack hotbar (hero/egg tools, 1–9),
right HUD treadmill-upgrade button, notifications top-centre. Windows: Shop (gamepasses + gear), Hero Index, Growing Eggs list, Rebirth,
Settings, Codes, Gear Shop, Trail Shop, Treadmill Shop (10 tiers), Treadmill Speed Shop, Pet (hero) list, Fuse Machine, Trade, Message popups.

## Real game data (use it; never invent other stats)
Heroes (id · rarity · base $/s · primary · secondary):
Flash Common 25 (205,25,35)/(255,215,0) · Superman Rare 60 (0,85,205)/(205,25,35) · Batman Epic 120 (28,28,32)/(230,180,20) ·
Zoom Legendary 300 (18,22,30)/(0,150,255) · Reverse Flash Mythic 850 (240,210,20)/(180,20,20) · A-Train Common 25 (30,70,150)/(220,220,230) ·
Homelander Mythic 900 (15,45,120)/(200,20,30) · Spider-Man Common 25 (200,25,30)/(25,60,180) · Miles Morales Epic 130 (20,20,22)/(220,20,30) ·
Spider-Gwen Rare 55 (235,235,245)/(230,40,140) · Spider-Man 2099 Legendary 320 (12,28,85)/(255,30,40) · Venom Mythic 880 (12,12,16)/(240,240,250) ·
Aquaman Common 25 (230,140,20)/(20,130,70) · Red Death Legendary 350 (160,15,20)/(25,25,25) · Savitar Legendary 360 (160,175,190)/(100,200,255) ·
Sonic Epic 140 (0,100,240)/(255,255,255) · Super Sonic Legendary 400 (255,220,20)/(255,50,50) · Silver Surfer Secret 2500 (215,225,235)/(160,200,255).
Zones → villain: Forest Flash · Lake Aquaman · Desert Homelander · Jungle Spider-Man · Snow Batman · Volcano Red Death · Abyss Ocean A-Train · Prehistoric Reverse Flash · Cosmic Zoom.
Escape bounty by rarity: Common $150 · Uncommon $250 · Rare $400 · Epic $800 · Legendary $1,800 · Mythic $3,500 · Secret $7,500. Safe zone = the hub (X ≤ 75).
Egg growth: Common eggs 20s, Rare 30s, Epic 45–50s, Legendary 60–80s, Mythic 90s, Secret 120s (base). Treadmill unlock (first base upgrade): $1,000. Start money $250.
Treadmill tiers (name · price · speed ×): Treadmill free ×6 · Sci-Fi $15K ×15 · Flame $250K ×36 · Celebrity $5M ×90 · Golden $120M ×240 · The Freeze $3B ×300 · Lucky Block $75B ×600 · Hacker $2T ×1,500 · Demonic $50T ×3,000 · Angelic $1Qa ×6,000.
Treadmill pays SpeedPower + 10 coins/s × multiplier; SpeedPower multiplies hero income (10 SP ×1, 100 ×2, 1000 ×3).
Unknown values (gamepass prices, Robux): use placeholders like [R$ PRICE]. Player name placeholder: [PLAYER].
