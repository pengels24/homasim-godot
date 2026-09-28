# 🏨 HO·MA·SIM – Getting Started
### A Guide for the Pre-Alpha · v0.2.1

> **Note:** The full interactive tutorial is still in development. This guide bridges the gap and covers everything you need to know to get your hotel up and running.

---

## 🎯 What's the Goal?

You build and manage a hotel. Guests arrive, check in, eat, relax – and eventually check out. Your job: keep them happy so you earn money, level up, and expand your hotel further.

The game is an **economic simulation with visible life** – all guests and staff physically move through your hotel. There are no pure spreadsheet menus.

---

## 🚪 From the Main Menu to the Game

Before you see your hotel, you'll briefly go through the **main menu**:

### 1. Launch the Game
Start HO·MA·SIM. You land on the **main menu**.

### 2. Create or Select a Manager
On first launch, the **"Create Your Manager"** dialog opens. Here you set up your player profile:

- Enter a **Name**
- Choose **Gender** (Male / Female / Non-binary)
- Choose **Skin tone** (Light / Medium / Dark)
- Choose **Hair color** (Blonde, Brown, Black, Light Blonde, Red, Grey)
- Choose **Outfit** (Black Suit / Grey Suit / Casual / Uniform)

On the right you'll see a **pixel art preview** of your manager. Confirm with **"Create Manager"**.

On subsequent launches you can directly select your existing manager – the last used one stays saved.

### 3. "Your Hotels" – Hotel Overview
After selecting your manager, **"Your Hotels"** opens – your personal hotel overview. You'll see:

- **Left:** Your manager card with avatar, name, level and number of hotels
- **Centre/Right:** All your hotel saves as cards with preview image and quick stats:
  - **Level** – your current hotel level
  - **Day** – how many in-game days have passed
  - **Guests** – currently checked-in guests
  - **Rep** – your reputation value
  - **Capital** – current balance

- The **"+"** tile creates a new hotel
- The **"×"** on a card deletes that hotel

### 4. Create a New Hotel
In the **"Create New Hotel"** dialog you configure your game:

**Hotel Name:** Give your hotel a name (required).

**Difficulty** – choose one of four modes:

| Mode | Description |
|---|---|
| **Easy** | More starting capital, less pressure |
| **Standard** | Balanced start (€50,000 starting capital) |
| **Hard** | Less capital, higher challenge |
| **Custom** | All values manually adjustable (arrow keys) |

In **Custom** mode you can fine-tune all values with ← / → arrows:
- **Starting Capital** – your initial budget
- **Construction Refund** – how much % you get back when demolishing
- **EXP Boost** – experience point multiplier
- **Room Dirt Rate** – how quickly rooms get dirty
- **Room Degradation** – how quickly rooms take damage

**Starting Plot:** On the right you'll see a preview of your starting plot including the lobby entrance side.

Confirm with **"Create"** (green) or cancel with **"Cancel"** (red).

### 5. Start Playing
After creating, your hotel appears as a new card in "Your Hotels". Click on it to load it – the game starts and you land directly in your hotel. You're the manager now!

**What you see on first launch:**
- The game starts **automatically paused** (display: "### Game Paused ###") – take a moment to get your bearings
- You see your **empty starting plot** (grey area = buildable land, green = non-buildable outside area)
- In the corner your **Lobby** is already placed – that's all you start with

> 💡 **Build some rooms first** before you unpause the game! Without rooms, no guests will arrive. The build menu is always visible at the bottom and automatically pauses the game when used.

- A hint appears at the top: **"Reception opens (07:00)"** – the first wave of guests arrives at 07:00
- When you're ready: press **▶** (top right) to start the game

---

## 🖥️ The HUD – What Do You See on Screen?

### Top Bar (left to right)
| Element | Meaning |
|---|---|
| **Number + ☆☆☆☆☆** | Your current hotel level + star rating |
| **💰 Amount** | Current capital (balance) |
| **Counter** | Active guests |
| **0 / 150** | EXP progress to next level |
| **500 / 1000** | Reputation points |
| **📅 1** | Current in-game day |
| **06:00** | Current in-game time |
| **⏸ ▶ ▶▶** | Game speed: Pause / Normal / Fast-Forward |

> 💡 **Auto-Pause:** All F-menus (F1–F10) and the build menu automatically pause the game when opened. You can build, manage staff, or browse the tech tree without time passing.

### Icon Bar – Top Right (F-Keys)
All main menus are also accessible by clicking their icons:

| Key | Function |
|---|---|
| `F1` | **Reception** – Check-In / Check-Out overview |
| `F2` | **Tech Tree** – research & unlock new features |
| `F3` | **Guest List** – all current guests & their status |
| `F4` | **Room List** – all rooms, cleanliness, condition |
| `F5` | **Staff** – hire, fire, assign employees |
| `F6` | **Cash Book** – income & expenses |
| `F7` | **SimBrowser** – in-game browser |
| `F8` | **Quest Book** – active goals & milestones |
| `F9` | Hotel Overview *(not yet implemented)* |
| `F10` | **Tutorial / Codex** – reference & help |
| `L` | **Activity Log** – chronological event log |
| `ESC` | Close current menu / open pause menu |
| `Home` | Centre view on lobby |

### Left Sidebar – Overlays & Filters
Toggles coloured overlay views on the play field. Each click enables/disables the filter:

| Overlay | Shows... |
|---|---|
| **Dirt** | How dirty each room is |
| **Condition** | Wear & repair needs |
| **Occupancy** | Which rooms are currently occupied |
| **Room Categories** | Rooms colour-coded by type |
| **Value** | Quality rating of rooms |
| **WiFi** | WiFi coverage in the hotel |
| **Climate** | Air conditioning coverage |

### Right Side (below top bar)
- **Activity Log** (also via `L`) – opens the chronological event log

### Play Field (Centre)
- **Grey area** = your buildable plot
- **Green area** = non-buildable outside land

**Camera Controls:**
| Action | Key |
|---|---|
| Move camera | `WASD` or arrow keys |
| Zoom | Mouse wheel or Numpad `+` / `-` |
| Centre view | `Home` |

### Build Menu (bottom, always visible)
| Tab | Category |
|---|---|
| 🛏 | **Beds & Rooms** |
| 🍴 | **Gastronomy** (Bar, Kitchen, Restaurant) |
| 🏠 | **Management** (Staff) |
| 💆 | **Wellness** (Pool, Gym, Spa) |
| 💼 | **Business** (Conference) |
| 🔨 | **Demolish Tool** – tear down rooms |
| ➕ | **Buy Plot** – expand your land |

---

## 🔨 Building – How It Works

### Placing a Room
1. Select the desired category (tab) in the **build menu at the bottom**
2. Click the room type – it now follows your mouse as a **ghost**
3. Move the mouse over the plot and click to place

### Ghost Colours
| Colour | Meaning |
|---|---|
| 🟩 **Green** | Placement possible – you can build here |
| 🟥 **Red** | Placement not possible – reason usually shown in tooltip |

### Room Variants
After selecting a room type, a bar with **variants** appears at the bottom (e.g. different room sizes). Click a variant to select it.

### Build Shortcuts
| Key | Function |
|---|---|
| `R` | Rotate room |
| `.` (Period) | Cycle door position |
| `Shift` (hold) | Multi-build – after placing, the room stays selected so you can keep building |
| `ESC` or `RMB` | Cancel build mode |

### ⚠️ Important: There Are No Corridor Pieces!
There are **no separate corridor elements** to build. Hallways form automatically through the **natural gaps** between rooms – so leave some space when placing rooms so your guests and staff can move through your hotel.

---

## 🚀 First Steps – One at a Time

### Step 1: Understand Your Hotel
You start with a **Lobby** (already built). The lobby is your reception – all guests arrive here and check out here. You **cannot demolish** the lobby.

---

### Step 2: Build Rooms
Without rooms, no guests arrive. The **build menu is always visible at the bottom** – nothing to open:

1. Select the **Rooms** tab in the build menu
2. Place at least **2–3 Single Rooms** (cheap, no prerequisites)
3. Make sure rooms connect to the lobby or are reachable via a corridor

> **Cost:** Single Room = €2,000 | Income: ~€80 / night

---

### Step 3: Hire Staff (from Level 2)
Nothing works without staff. But first: **you need a Staff Room!**

**Order:**
1. Build a **Small Staff Room** (€2,500, unlocked at Level 2)
   → Each staff room lets you hire 4 employees
2. Open `F5` (Staff Management)
3. Hire a **Housekeeper** → cleans rooms after checkout
4. Optional: a **Maintenance Worker** → repairs broken objects

**Without a housekeeper:** Guests check into dirty rooms → bad reviews!

---

### Step 4: Receive Guests
When new guests arrive, the **game automatically pauses** and a toast notification "New Guests" appears. Check-in and checkout always go through the **Reception (Lobby)**:

- Click on the **Lobby** → the reception menu opens
- There you see waiting guests and can process **Check-In** and **Checkout**

> In early stages **you personally** handle the reception desk. This is intentional! Later, tech tree upgrades enable automatic check-in and checkout.

💡 **Observe guests:** Click directly on a guest in the hotel to open a **PiP camera** with their current status values (hunger, thirst, satisfaction, etc.). You can have up to **3 PiP windows open at once**.

---

### Step 5: Provide Food & Drinks (optional but important)
Hungry guests get unhappy quickly. The lobby snack machine helps briefly but won't cut it long-term.

**Gastronomy order (Tech Tree):**
1. **Bar** (research G1.1 → €1,800, needs bartender)
2. **Kitchen** (G1.2 → €3,000, needs chef)
3. **Restaurant** (G1.3 → €5,000, needs waiter)

> ⚠️ The restaurant only works with an active kitchen + chef + waiter. Don't build the restaurant without also running the kitchen!

---

## 💡 Key Game Mechanics

### Guest Needs
Every guest has needs: **Hunger, Thirst, Fatigue, Fun**. If these aren't met, **satisfaction** drops. At very low satisfaction, the guest leaves a bad review and you lose reputation.

Click on a guest to open their PiP camera and see their current status.

### Patience
Guests only wait a **limited time** for check-in, food, or a free seat. If they wait too long, they leave unsatisfied. Keep your operation running smoothly.

### Cleanliness
Rooms get **dirty** after checkout. A housekeeper must clean the room before it can be occupied again. Broken objects are repaired by the maintenance worker.

### Staff Morale
Employees lose morale through work. They recover in the **Staff Room**. Below 50% morale: slower. At 0%: they quit. Monitor your staff's morale in `F5`.

### Money & Levelling
- **EXP** is earned through guest checkouts, completed quests and special actions
- Each **Level-Up** unlocks new tech tree features
- In the **Tech Tree** (F2) you spend research points on new rooms, bonuses and features

---

## ❓ Frequently Asked Questions

**"No guests are arriving!"**
→ Make sure at least 1 room has been built. Wait a moment – guests don't arrive instantly.

**"I can't hire any staff!"**
→ Build a staff room first. No staff room = no staff capacity = no hiring possible.

**"The restaurant is empty even though guests are around!"**
→ Check: Do you have a kitchen with a chef? Do you have a waiter in the restaurant? Both are required!

**"A room shows a warning symbol!"**
→ Hover over the room with your mouse. The tooltip explains the problem (e.g. no staff assigned, broken object, too dirty).

**"I see strange symbols on the rooms!"**
→ These are status indicators: 🔧 = repair needed, 🧹 = cleaning needed, ⚠️ = no staff.

---

## 🗺️ Typical Daily Schedule

```
– Guests wake up, want breakfast
– Checkout wave: day-trip guests depart
– Restaurant & Bar open
– Housekeepers clean rooms, maintenance repairs – if assigned
– Lunchtime: Restaurant & Bar busy
– New guests arrive throughout the day
– Dinner: second restaurant rush
– Night hours, hotel quieter
– Nightly settlement: room income is credited
```

---

## 📋 Quick Reference: Rooms & Requirements

| Room | Cost | Requirement | Income |
|---|---|---|---|
| Lobby | €0 | – (already built) | – |
| Single Room | €2,000 | none | ~€80 / night |
| Double Room | €3,500 | none | ~€130 / night |
| Family Room | €6,000 | Tech Tree Z1.2 | ~€200 / night |
| Superior Room | €15,000 | Tech Tree Z1.3 | ~€400 / night |
| Staff Room | €2,500 | Level 2 | (required for staff) |
| Bar | €1,800 | Tech Tree G1.1 | ~€15 / drink |
| Kitchen | €3,000 | Tech Tree G1.2 | (required for food) |
| Restaurant | €5,000 | Tech Tree G1.3 | ~€25 / meal |
| Pool | €5,000 | Tech Tree W1.2 | (satisfaction ↑) |
| Gym | €3,800 | Tech Tree | (satisfaction ↑) |
| Spa / Sauna | €4,500 | Tech Tree W1.3 | (satisfaction ↑) |
| Conference Room | €5,000 | Tech Tree P1.2 | Day guests |

---

*HO·MA·SIM Pre-Alpha v0.2.1 · This guide is preliminary and will be updated alongside the game.*
