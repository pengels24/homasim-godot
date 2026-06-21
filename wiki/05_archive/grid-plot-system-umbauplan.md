================================================================================
UMSETZUNGSPLAN: Grid-Flächen-System für HO·MA·SIM
================================================================================

ÜBERSICHT:
- Grid: 5x5 Flächen à 10x10 Tiles = 50x50 bebaubar
- Plus 4 Tiles Gehweg-Rahmen = 58x58 Tiles gesamt
- Startfläche: Spieler wählt am Rand (gratis)
- Erweiterungen: Alle 2-3 Level freigeschaltet, müssen angrenzen, kostenpflichtig

<!-- ================================================================================
PHASE 1: Datenbank & Backend Grundlagen
================================================================================ -->

<!-- --- Schritt 1.1: Datenbank erweitern ---
- hotels Tabelle erweitern:

ALTER TABLE hotels
  ADD COLUMN grid_size INT DEFAULT 5,
  ADD COLUMN unlocked_plots JSON DEFAULT '[]';

- grid_size: Anzahl Flächen pro Seite (5x5)
- unlocked_plots: Array von gekauften Flächen, z.B. [[0,0], [1,0], [0,1]] -->

<!-- --- Schritt 1.2: RoomDefinitions erweitern ---
Datei: src/Config/RoomDefinitions.php
Neuer Eintrag:

'sidewalk' => [
  'name' => 'Gehweg',
  'label' => 'GW',
  'cost' => 0,
  'width' => 1,
  'height' => 1,
  'icon' => 'square',
  'is_walkable' => false,
  'is_buildable' => false,
] -->

<!-- --- Schritt 1.3: Plot-Helper Funktion erstellen ---
Neue Datei: src/Helpers/plot_helper.php

Funktionen:
- getPlotCoordinates($x, $y) // Welcher Plot für gegebene Tile-Koordinaten?
- isPlotUnlocked($hotel, $plotX, $plotY) // Ist Plot gekauft?
- isPlotAtEdge($plotX, $plotY, $gridSize) // Liegt Plot am Rand?
- getAdjacentPlots($plotX, $plotY) // Welche Plots grenzen an?
- canUnlockPlot($hotel, $plotX, $plotY) // Darf Plot gekauft werden?

Beispiel-Implementierung:

<?php
function getPlotCoordinates($tileX, $tileY, $plotSize = 10, $sidewalkWidth = 4) {
  $adjustedX = $tileX - $sidewalkWidth;
  $adjustedY = $tileY - $sidewalkWidth;
  if ($adjustedX < 0 || $adjustedY < 0) return null; // Auf Gehweg
  return [
    'plot_x' => floor($adjustedX / $plotSize),
    'plot_y' => floor($adjustedY / $plotSize)
  ];
}

function isPlotUnlocked($hotel, $plotX, $plotY) {
  $unlocked = json_decode($hotel['unlocked_plots'] ?? '[]', true);
  foreach ($unlocked as $plot) {
    if ($plot[0] == $plotX && $plot[1] == $plotY) return true;
  }
  return false;
}

function isPlotAtEdge($plotX, $plotY, $gridSize = 5) {
  return $plotX === 0 || $plotX === ($gridSize - 1) ||
         $plotY === 0 || $plotY === ($gridSize - 1);
}

function getAdjacentPlots($plotX, $plotY) {
  return [
    [$plotX - 1, $plotY],     // Links
    [$plotX + 1, $plotY],     // Rechts
    [$plotX, $plotY - 1],     // Oben
    [$plotX, $plotY + 1]      // Unten
  ];
}

function canUnlockPlot($hotel, $plotX, $plotY) {
  // Bereits freigeschaltet?
  if (isPlotUnlocked($hotel, $plotX, $plotY)) return false;

  // Erster Plot (Startfläche)?
  $unlocked = json_decode($hotel['unlocked_plots'] ?? '[]', true);
  if (empty($unlocked)) {
    return isPlotAtEdge($plotX, $plotY);
  }

  // Muss an gekauften Plot angrenzen
  $adjacent = getAdjacentPlots($plotX, $plotY);
  foreach ($adjacent as $adj) {
    if (isPlotUnlocked($hotel, $adj[0], $adj[1])) return true;
  }
  return false;
} -->

<!-- ================================================================================
PHASE 2: Grid-Rendering anpassen
================================================================================ -->

<!-- --- Schritt 2.1: Grid-Größe berechnen ---
Datei: grid.js
Neue Konstanten am Anfang:

const PLOT_SIZE = 10;           // 10x10 Tiles pro Fläche
const SIDEWALK_WIDTH = 4;       // 4 Tiles Rahmen
const GRID_PLOTS = 5;           // 5x5 Flächen
const TOTAL_GRID_SIZE = (GRID_PLOTS * PLOT_SIZE) + (SIDEWALK_WIDTH * 2);
// = 58x58 Tiles gesamt

Grid-Initialisierung anpassen:
- gridWidth und gridHeight auf TOTAL_GRID_SIZE setzen -->

<!-- --- Schritt 2.2: Gehweg-Tiles rendern ---
Neue Funktion in grid.js: -->

<!-- renderSidewalk() {
  // Oberer Rand
  for (let x = 0; x < TOTAL_GRID_SIZE; x++) {
    for (let y = 0; y < SIDEWALK_WIDTH; y++) {
      this.createSidewalkTile(x, y);
    }
  }

  // Unterer Rand
  for (let x = 0; x < TOTAL_GRID_SIZE; x++) {
    for (let y = TOTAL_GRID_SIZE - SIDEWALK_WIDTH; y < TOTAL_GRID_SIZE; y++) {
      this.createSidewalkTile(x, y);
    }
  }

  // Linker Rand (ohne Ecken)
  for (let y = SIDEWALK_WIDTH; y < TOTAL_GRID_SIZE - SIDEWALK_WIDTH; y++) {
    for (let x = 0; x < SIDEWALK_WIDTH; x++) {
      this.createSidewalkTile(x, y);
    }
  }

  // Rechter Rand (ohne Ecken)
  for (let y = SIDEWALK_WIDTH; y < TOTAL_GRID_SIZE - SIDEWALK_WIDTH; y++) {
    for (let x = TOTAL_GRID_SIZE - SIDEWALK_WIDTH; x < TOTAL_GRID_SIZE; x++) {
      this.createSidewalkTile(x, y);
    }
  }
} -->

<!-- createSidewalkTile(x, y) {
  const tile = document.createElement('div');
  tile.className = 'tile sidewalk';
  tile.style.gridColumnStart = x + 1;
  tile.style.gridRowStart = y + 1;
  tile.style.gridColumnEnd = 'span 1';
  tile.style.gridRowEnd = 'span 1';
  this.grid.appendChild(tile);
} -->

<!-- In init() aufrufen:
this.renderSidewalk(); -->

<!-- CSS hinzufügen (main.scss oder grid.scss):

.tile.sidewalk {
  background-color: #4a5568;
  border: 1px solid #2d3748;
  pointer-events: none; // Nicht anklickbar
} -->

<!-- --- Schritt 2.3: Plot-Grenzen visualisieren ---
Neue Funktion in grid.js: -->

<!-- renderPlotBorders() {
  const startTile = SIDEWALK_WIDTH;
  const endTile = SIDEWALK_WIDTH + (GRID_PLOTS * PLOT_SIZE);

  // Vertikale Linien
  for (let i = 1; i < GRID_PLOTS; i++) {
    const x = startTile + (i * PLOT_SIZE);
    const border = document.createElement('div');
    border.className = 'plot-border-vertical';
    border.style.gridColumn = `${x + 1} / span 1`;
    border.style.gridRow = `${startTile + 1} / span ${GRID_PLOTS * PLOT_SIZE}`;
    this.grid.appendChild(border);
  }

  // Horizontale Linien
  for (let i = 1; i < GRID_PLOTS; i++) {
    const y = startTile + (i * PLOT_SIZE);
    const border = document.createElement('div');
    border.className = 'plot-border-horizontal';
    border.style.gridColumn = `${startTile + 1} / span ${GRID_PLOTS * PLOT_SIZE}`;
    border.style.gridRow = `${y + 1} / span 1`;
    this.grid.appendChild(border);
  }
} -->

<!-- CSS:

.plot-border-vertical,
.plot-border-horizontal {
  border: 1px dashed rgba(255, 255, 255, 0.2);
  pointer-events: none;
  z-index: 5;
} -->

================================================================================
PHASE 3: Plot-Status System
================================================================================

<!-- --- Schritt 3.1: Plot-Overlays erstellen ---
Neue Funktion in grid.js:

renderPlotOverlays() {
  const startTile = SIDEWALK_WIDTH;

  for (let plotY = 0; plotY < GRID_PLOTS; plotY++) {
    for (let plotX = 0; plotX < GRID_PLOTS; plotX++) {
      const status = this.getPlotStatus(plotX, plotY);

      if (status === 'unlocked') continue; // Kein Overlay für gekaufte

      const overlay = document.createElement('div');
      overlay.className = `plot-overlay plot-${status}`;
      overlay.dataset.plotX = plotX;
      overlay.dataset.plotY = plotY;

      const gridX = startTile + (plotX * PLOT_SIZE);
      const gridY = startTile + (plotY * PLOT_SIZE);

      overlay.style.gridColumn = `${gridX + 1} / span ${PLOT_SIZE}`;
      overlay.style.gridRow = `${gridY + 1} / span ${PLOT_SIZE}`;

      if (status === 'available') {
        overlay.innerHTML = `
          <div class="plot-overlay-content">
            <button class="btn-unlock-plot">
              Kaufen<br>${this.getPlotCost(plotX, plotY).toLocaleString('de-DE')} €
            </button>
          </div>
        `;
        overlay.addEventListener('click', () => this.unlockPlot(plotX, plotY));
      } else if (status === 'locked') {
        const requiredLevel = this.getRequiredLevel(plotX, plotY);
        overlay.innerHTML = `
          <div class="plot-overlay-content">
            <i data-lucide="lock"></i>
            <span>Level ${requiredLevel}</span>
          </div>
        `;
      }

      this.grid.appendChild(overlay);
    }
  }

  // Lucide Icons neu initialisieren
  if (typeof lucide !== 'undefined') {
    lucide.createIcons();
  }
}

getPlotStatus(plotX, plotY) {
  // Prüfe ob in unlockedPlots
  const isUnlocked = this.unlockedPlots.some(p => p[0] === plotX && p[1] === plotY);
  if (isUnlocked) return 'unlocked';

  // Prüfe ob freigeschaltet (Level)
  const maxPlots = Math.floor(this.hotel.level / 2) + 1;
  const currentUnlocked = this.unlockedPlots.length;

  if (currentUnlocked >= maxPlots) return 'locked';

  // Prüfe ob angrenzend an gekaufte Fläche
  const adjacent = [
    [plotX - 1, plotY],
    [plotX + 1, plotY],
    [plotX, plotY - 1],
    [plotX, plotY + 1]
  ];

  const hasAdjacentUnlocked = adjacent.some(([x, y]) =>
    this.unlockedPlots.some(p => p[0] === x && p[1] === y)
  );

  if (hasAdjacentUnlocked || this.unlockedPlots.length === 0) {
    return 'available';
  }

  return 'locked';
}

getPlotCost(plotX, plotY) {
  const plotNumber = this.unlockedPlots.length + 1;
  return Math.pow(2, plotNumber - 1) * 10000; // 10k, 20k, 40k, 80k...
}

getRequiredLevel(plotX, plotY) {
  const plotNumber = this.unlockedPlots.length + 1;
  return plotNumber * 2;
}

CSS für Overlays:

.plot-overlay {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
  cursor: pointer;
  transition: all 0.3s ease;
}

.plot-overlay.plot-available {
  background-color: rgba(251, 146, 60, 0.3);
  border: 2px solid #fb923c;
}

.plot-overlay.plot-available:hover {
  background-color: rgba(251, 146, 60, 0.5);
}

.plot-overlay.plot-locked {
  background-color: rgba(239, 68, 68, 0.3);
  border: 2px solid #ef4444;
  cursor: not-allowed;
}

.plot-overlay-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  color: white;
  text-align: center;
}

.btn-unlock-plot {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  color: white;
  border: none;
  padding: 1rem 2rem;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-unlock-plot:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.4);
} -->

<!-- --- Schritt 3.2: Plot-Status vom Server laden ---
In grid.js beim Laden:

async loadPlotData() {
  try {
    const response = await fetch(`/api/hotel/plots?hotel_id=${this.hotel.id}`);
    const data = await response.json();

    if (data.success) {
      this.unlockedPlots = data.unlocked_plots || [];
      this.renderPlotOverlays();
    }
  } catch (error) {
    console.error('Error loading plot data:', error);
  }
}

Neuer API Endpoint in HotelController.php:

public function getPlots() {
  header('Content-Type: application/json');

  if (!isset($_SESSION['user_id'])) {
    echo json_encode(['success' => false, 'message' => 'Not logged in']);
    return;
  }

  $hotelId = (int)($_GET['hotel_id'] ?? 0);
  $db = Database::getInstance()->getConnection();

  $stmt = $db->prepare("
    SELECT unlocked_plots, level FROM hotels
    WHERE id = ? AND user_id = ?
  ");
  $stmt->execute([$hotelId, $_SESSION['user_id']]);
  $hotel = $stmt->fetch();

  if (!$hotel) {
    echo json_encode(['success' => false, 'message' => 'Hotel not found']);
    return;
  }

  echo json_encode([
    'success' => true,
    'unlocked_plots' => json_decode($hotel['unlocked_plots'] ?? '[]', true),
    'level' => (int)$hotel['level']
  ]);
}

Route in index.php hinzufügen:

$router->get('/api/hotel/plots', 'HotelController::getPlots');

--- Schritt 3.3: Click-Handler für Plots ---
Funktion in grid.js:

async unlockPlot(plotX, plotY) {
  const cost = this.getPlotCost(plotX, plotY);

  const confirmed = confirm(
    `Fläche (${plotX}, ${plotY}) für ${cost.toLocaleString('de-DE')} € kaufen?`
  );

  if (!confirmed) return;

  try {
    const response = await fetch('/api/hotel/unlock-plot', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        hotel_id: this.hotel.id,
        plot_x: plotX,
        plot_y: plotY
      })
    });

    const result = await response.json();

    if (result.success) {
      this.hotel.money = result.new_money;
      this.unlockedPlots = result.unlocked_plots;

      // UI aktualisieren
      this.updateMoneyDisplay();
      this.clearPlotOverlays();
      this.renderPlotOverlays();

      this.showToast('Fläche erfolgreich gekauft!', 'success');
    } else {
      this.showToast(result.message, 'error');
    }
  } catch (error) {
    console.error('Error unlocking plot:', error);
    this.showToast('Fehler beim Kauf', 'error');
  }
}

clearPlotOverlays() {
  this.grid.querySelectorAll('.plot-overlay').forEach(el => el.remove());
} -->

================================================================================
PHASE 4: Hotel-Erstellung anpassen
================================================================================

--- Schritt 4.1: Startflächen-Auswahl UI ---
Neue View-Datei: src/Views/hotel/create.php

<div class="card">
  <h2>Neues Hotel gründen</h2>

  <form id="hotel-create-form" method="POST">
    <div class="form-group">
      <label for="hotel-name">Hotel-Name:</label>
      <input type="text" id="hotel-name" name="name" required>
    </div>

    <div class="form-group">
      <label>Wähle deine Startfläche:</label>
      <p class="help-text">Wähle eine Fläche am Rand für dein erstes Grundstück.</p>

      <div id="plot-selector" class="plot-grid">
        <!-- Wird mit JavaScript gefüllt -->
      </div>

      <input type="hidden" id="start-plot-x" name="start_plot_x" required>
      <input type="hidden" id="start-plot-y" name="start_plot_y" required>
    </div>

    <button type="submit" class="btn">Hotel gründen</button>
  </form>
</div>

<script>
const GRID_SIZE = 5;

function renderPlotSelector() {
  const selector = document.getElementById('plot-selector');
  selector.style.display = 'grid';
  selector.style.gridTemplateColumns = `repeat(${GRID_SIZE}, 1fr)`;
  selector.style.gap = '0.5rem';

  for (let y = 0; y < GRID_SIZE; y++) {
    for (let x = 0; x < GRID_SIZE; x++) {
      const plot = document.createElement('div');
      plot.className = 'plot-selector-tile';

      const isEdge = x === 0 || x === GRID_SIZE - 1 || y === 0 || y === GRID_SIZE - 1;

      if (isEdge) {
        plot.classList.add('selectable');
        plot.dataset.x = x;
        plot.dataset.y = y;
        plot.addEventListener('click', () => selectPlot(x, y));
      } else {
        plot.classList.add('blocked');
        plot.title = 'Muss am Rand liegen';
      }

      selector.appendChild(plot);
    }
  }
}

function selectPlot(x, y) {
  // Alle deselektieren
  document.querySelectorAll('.plot-selector-tile.selected').forEach(el => {
    el.classList.remove('selected');
  });

  // Neue Auswahl
  event.target.classList.add('selected');
  document.getElementById('start-plot-x').value = x;
  document.getElementById('start-plot-y').value = y;
}

renderPlotSelector();
</script>

CSS für Plot-Selector:

.plot-selector-tile {
  aspect-ratio: 1;
  border: 2px solid #4a5568;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.plot-selector-tile.selectable {
  background: linear-gradient(135deg, #10b981, #059669);
}

.plot-selector-tile.selectable:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4);
}

.plot-selector-tile.selected {
  border-color: #fbbf24;
  box-shadow: 0 0 0 3px rgba(251, 191, 36, 0.3);
}

.plot-selector-tile.blocked {
  background: #374151;
  cursor: not-allowed;
  opacity: 0.5;
}

--- Schritt 4.2: Rand-Erkennung ---
Bereits in Phase 1.3 implementiert (isPlotAtEdge)

--- Schritt 4.3: Hotel-Create POST erweitern ---
In HotelController.php → store() Methode:

public function store() {
  // ... existing validation ...

  $startPlotX = (int)($_POST['start_plot_x'] ?? -1);
  $startPlotY = (int)($_POST['start_plot_y'] ?? -1);

  // Validierung: Muss Rand-Fläche sein
  require_once __DIR__ . '/../Helpers/plot_helper.php';

  if (!isPlotAtEdge($startPlotX, $startPlotY)) {
    $_SESSION['error'] = 'Startfläche muss am Rand liegen.';
    header('Location: /hotel/create');
    return;
  }

  // Hotel erstellen
  $stmt = $db->prepare("
    INSERT INTO hotels (user_id, name, money, grid_size, unlocked_plots)
    VALUES (?, ?, 50000, 5, ?)
  ");

  $unlockedPlots = json_encode([[$startPlotX, $startPlotY]]);
  $stmt->execute([$_SESSION['user_id'], $name, $unlockedPlots]);

  // ... rest ...
}

================================================================================
PHASE 5: Build-Mode Einschränkungen
================================================================================

--- Schritt 5.1: Platzierungs-Validierung ---
In BuildManager.js → isValidPosition():

Nach der Kollisionsprüfung hinzufügen:

// Prüfe ob in freigeschalteter Fläche
const plotCoords = this.getPlotFromTile(x, y);
if (!plotCoords) {
  return { valid: false, reason: 'Außerhalb des Baubereichs' };
}

const isUnlocked = this.grid.unlockedPlots.some(
  p => p[0] === plotCoords.plotX && p[1] === plotCoords.plotY
);

if (!isUnlocked) {
  return { valid: false, reason: 'Fläche nicht freigeschaltet' };
}

// Neue Methode:
getPlotFromTile(tileX, tileY) {
  const SIDEWALK_WIDTH = 4;
  const PLOT_SIZE = 10;

  const adjustedX = tileX - SIDEWALK_WIDTH;
  const adjustedY = tileY - SIDEWALK_WIDTH;

  if (adjustedX < 0 || adjustedY < 0) return null; // Auf Gehweg

  return {
    plotX: Math.floor(adjustedX / PLOT_SIZE),
    plotY: Math.floor(adjustedY / PLOT_SIZE)
  };
}

--- Schritt 5.2: Ghost-Tile Anpassung ---
In updateGhost():

const validation = this.buildManager.isValidPosition(x, y);

if (!validation.valid) {
  this.ghostTile.classList.add('invalid');
  this.ghostTile.classList.remove('valid');
  this.ghostTile.title = validation.reason; // Tooltip
} else {
  this.ghostTile.classList.add('valid');
  this.ghostTile.classList.remove('invalid');
  this.ghostTile.title = '';
}

CSS:

.ghost.invalid {
  background-color: rgba(239, 68, 68, 0.5) !important;
  border-color: #ef4444 !important;
}

--- Schritt 5.3: Backend-Validierung ---
In HotelController.php → addRoom():

Nach dem Money-Check:

require_once __DIR__ . '/../Helpers/plot_helper.php';

// Prüfe ob in freigeschalteter Fläche
$plotCoords = getPlotCoordinates($x, $y);
if (!$plotCoords) {
  throw new \Exception("Position außerhalb des Baubereichs.");
}

if (!isPlotUnlocked($hotel, $plotCoords['plot_x'], $plotCoords['plot_y'])) {
  throw new \Exception("Fläche nicht freigeschaltet.");
}

================================================================================
PHASE 6: Level & Freischaltung
================================================================================

--- Schritt 6.1: Freischalt-Logik ---
In plot_helper.php:

function getMaxPlotsForLevel($level) {
  // Level 1: 1 Plot (Start)
  // Level 2-3: 2 Plots
  // Level 4-5: 3 Plots
  // Level 6-7: 4 Plots
  // etc.
  return 1 + floor($level / 2);
}

function getAvailablePlots($hotel) {
  $unlocked = json_decode($hotel['unlocked_plots'] ?? '[]', true);
  $maxPlots = getMaxPlotsForLevel($hotel['level']);

  return [
    'unlocked_count' => count($unlocked),
    'max_plots' => $maxPlots,
    'can_unlock_more' => count($unlocked) < $maxPlots
  ];
}

--- Schritt 6.2: Plot-Kauf API ---
Neuer Endpoint in HotelController.php:

public function unlockPlot() {
  header('Content-Type: application/json');

  if (!isset($_SESSION['user_id'])) {
    echo json_encode(['success' => false, 'message' => 'Not logged in']);
    return;
  }

  $data = json_decode(file_get_contents('php://input'), true);
  $hotelId = (int)($data['hotel_id'] ?? 0);
  $plotX = (int)($data['plot_x'] ?? -1);
  $plotY = (int)($data['plot_y'] ?? -1);

  require_once __DIR__ . '/../Helpers/plot_helper.php';
  $db = Database::getInstance()->getConnection();

  try {
    $db->beginTransaction();

    // Hotel laden
    $stmt = $db->prepare("
      SELECT * FROM hotels
      WHERE id = ? AND user_id = ? FOR UPDATE
    ");
    $stmt->execute([$hotelId, $_SESSION['user_id']]);
    $hotel = $stmt->fetch();

    if (!$hotel) {
      throw new \Exception("Hotel nicht gefunden.");
    }

    // Validierung: Kann Plot freigeschaltet werden?
    if (!canUnlockPlot($hotel, $plotX, $plotY)) {
      throw new \Exception("Plot kann nicht freigeschaltet werden.");
    }

    // Kosten berechnen
    $unlocked = json_decode($hotel['unlocked_plots'] ?? '[]', true);
    $plotNumber = count($unlocked) + 1;
    $cost = pow(2, $plotNumber - 1) * 10000;

    if ($hotel['money'] < $cost) {
      throw new \Exception("Nicht genug Geld!");
    }

    // Plot freischalten
    $unlocked[] = [$plotX, $plotY];
    $newMoney = $hotel['money'] - $cost;

    $stmt = $db->prepare("
      UPDATE hotels
      SET money = ?, unlocked_plots = ?
      WHERE id = ?
    ");
    $stmt->execute([$newMoney, json_encode($unlocked), $hotelId]);

    $db->commit();

    echo json_encode([
      'success' => true,
      'new_money' => $newMoney,
      'unlocked_plots' => $unlocked
    ]);

  } catch (\Exception $e) {
    if ($db->inTransaction()) $db->rollBack();
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
  }
}

Route hinzufügen in index.php:

$router->post('/api/hotel/unlock-plot', 'HotelController::unlockPlot');

--- Schritt 6.3: Level-Up Notification ---
In der Level-Up Logik (wo auch immer das passiert):

// Nach Level-Up:
$newMaxPlots = getMaxPlotsForLevel($newLevel);
$currentPlots = count($unlocked);

if ($currentPlots < $newMaxPlots) {
  // Toast/Notification im Frontend
  return [
    'level_up' => true,
    'new_plot_available' => true,
    'message' => 'Level Up! Neue Fläche freigeschaltet!'
  ];
}

Im Frontend (grid.js oder game.js):

if (data.new_plot_available) {
  this.showToast('🎉 Neue Fläche freigeschaltet!', 'success');
  this.renderPlotOverlays(); // Neu rendern
}

================================================================================
PHASE 7: UI & Polish
================================================================================

--- Schritt 7.1: Plot-Info Panel ---
Neue Sektion im Status-Board oder separates Panel:

<div class="status-item">
  <div class="status-label">Grundstücke</div>
  <div class="status-value">
    <span id="plot-count">1</span> / <span id="plot-max">2</span>
  </div>
</div>

<button id="btn-show-plots" class="btn btn-secondary">
  Grundstücke verwalten
</button>

Modal/Sidebar beim Click:

<div id="plots-panel" class="panel">
  <h3>Grundstücke</h3>

  <div class="plots-list">
    <!-- Für jeden Plot: -->
    <div class="plot-item plot-unlocked">
      <span class="plot-coords">(0, 0)</span>
      <span class="plot-status">✓ Gekauft</span>
    </div>

    <div class="plot-item plot-available">
      <span class="plot-coords">(1, 0)</span>
      <button class="btn-unlock">Kaufen: 10.000 €</button>
    </div>

    <div class="plot-item plot-locked">
      <span class="plot-coords">(0, 1)</span>
      <span class="plot-status">🔒 Level 4</span>
    </div>
  </div>
</div>

--- Schritt 7.2: Gehweg-Grafik ---
OPTION A: Einfache Textur
Erstelle/lade eine Straßen-Textur (sidewalk.png)

CSS anpassen:

.tile.sidewalk {
  background-image: url('/assets/img/sidewalk.png');
  background-size: cover;
  border: 1px solid #2d3748;
}

OPTION B: Animated (Autos, Fußgänger)
Komplexere Lösung mit Canvas oder animierten GIFs:

renderAnimatedSidewalk() {
  // Autos fahren lassen
  setInterval(() => {
    const car = document.createElement('div');
    car.className = 'sidewalk-car';
    // Position berechnen, animieren
  }, 5000);
}

CSS Animation:

.sidewalk-car {
  position: absolute;
  width: 32px;
  height: 16px;
  background: url('/assets/img/car.png');
  animation: drive 10s linear;
}

@keyframes drive {
  from { left: -50px; }
  to { left: 100%; }
}

--- Schritt 7.3: Lokalisierung ---
In src/Language/homasim_de.php:

// Plots
'plots.title' => 'Grundstücke',
'plots.locked' => 'Gesperrt (Level ### benötigt)',
'plots.available' => 'Verfügbar für ### €',
'plots.unlocked' => 'Gekauft',
'plots.unlock_success' => 'Fläche erfolgreich gekauft!',
'plots.unlock_error' => 'Fläche konnte nicht gekauft werden.',
'plots.not_enough_money' => 'Nicht genug Geld!',
'plots.must_be_adjacent' => 'Fläche muss an gekaufte Fläche angrenzen.',
'plots.max_reached' => 'Maximale Anzahl Flächen erreicht.',

// Hotel Create
'hotel.create.choose_plot' => 'Wähle deine Startfläche',
'hotel.create.must_be_edge' => 'Startfläche muss am Rand liegen',

Verwendung in Views:

<?= T('plots.locked', $requiredLevel) ?>
<?= T('plots.available', $cost) ?>

================================================================================
ZUSAMMENFASSUNG & REIHENFOLGE
================================================================================

Empfohlene Umsetzungs-Reihenfolge:

TAG 1: Backend Grundlagen (Phase 1)
  - Datenbank erweitern (30 min)
  - RoomDefinitions erweitern (15 min)
  - plot_helper.php erstellen (1-2 Stunden)

TAG 2: Grid-Rendering (Phase 2)
  - Grid-Größe anpassen (30 min)
  - Gehweg rendern (1 Stunde)
  - Plot-Grenzen visualisieren (30 min)

TAG 3: Plot-Status System (Phase 3)
  - Plot-Overlays erstellen (2 Stunden)
  - API Endpoint (1 Stunde)
  - Click-Handler (1 Stunde)

TAG 4: Hotel-Erstellung (Phase 4)
  - UI für Startflächen-Auswahl (2 Stunden)
  - Backend anpassen (1 Stunde)

TAG 5: Build-Einschränkungen (Phase 5)
  - Validierung Frontend (1 Stunde)
  - Ghost anpassen (30 min)
  - Validierung Backend (30 min)

TAG 6: Level & Freischaltung (Phase 6)
  - Freischalt-Logik (1 Stunde)
  - Kauf-API (1-2 Stunden)
  - Notifications (30 min)

TAG 7: Polish (Phase 7)
  - Plot-Info Panel (1-2 Stunden)
  - Gehweg-Grafik (1-2 Stunden)
  - Lokalisierung (30 min)

GESAMT: ~12-18 Stunden über 7 Tage verteilt

================================================================================
WICHTIGE HINWEISE
================================================================================

1. TESTEN nach jedem Schritt!
2. Git-Commits nach jedem abgeschlossenen Schritt
3. Console-Logs für Debugging nutzen
4. Bei Problemen: Schritt zurück und debuggen
5. Nicht zu viele Schritte auf einmal
