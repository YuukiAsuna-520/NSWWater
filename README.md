# NSW Water – iOS (SwiftUI)

A lightweight iOS app to browse NSW dam information. Built with **SwiftUI, MVVM, Combine, MapKit**, and **SPM (swift-collections)**. It supports stub-first development, API auth (Bearer + subscription key), resilient JSON parsing (no date dependency), and a small MRU cache for latest resources.

---

## How this app meets the assessment criteria

> Each item lists *what the criterion is*, *what the app does*, and *where to find it in code.*

### 1) App structure, navigation & basic UI
- **What:** Clear structure, multiple screens, consistent navigation and titles.
- **What we did:** `NavigationStack` root, a **List screen** (dams with search) and a **Detail screen** (map + latest metrics).
- **Where:**  
  - `Views/DamListView.swift` – list, search, alert overlay, refresh.  
  - `Views/DamDetailView.swift` – detail layout, info labels, map.  
  - `Model/Dam.swift`, `Model/DamResource.swift` – domain models.

### 2) List & search
- **What:** Present a list with basic filtering.
- **What we did:** Real-time filtering by `name` or `id`. Empty query returns all.
- **Where:**  
  - `DamListViewModel.filtered` and `searchText`.  
  - `DamListView` binds `.searchable(text: $vm.searchText, prompt: "Search by name or id")`.

### 3) Detail + Map
- **What:** A rich detail page including a map.
- **What we did:** Shows coordinates, full volume (if available), and a Map with marker.
- **Where:**  
  - `DamDetailView` uses `Map(initialPosition: .region(...))` with `Marker`.

### 4) Networking (API integration, auth, headers)
- **What:** Fetch live data from NSW Water Insights API. Handle auth & headers.
- **What we did:**  
  - Optional **OAuth**: `AUTH_BASIC` → GET **access token** → send `Authorization: Bearer ...`.  
  - **Subscription key**: send under both header names: `apikey` and `Ocp-Apim-Subscription-Key`.  
  - Respect **BuildFlags** to fall back to stub when not configured.
- **Where:**  
  - `DamListViewModel`:
    - `ensureOAuthToken()` – obtains access token (if `AUTH_BASIC` present).  
    - `GETRaw(...requiresApiKey:)` / `GET<T>` – shared fetch + headers.  
    - `loadFromNetworkReplacingStub()` – loads `/dams` envelope.  
  - `Support/BuildFlags.swift` – `useNetwork` toggle.  
  - `Support/StubLoader.swift` – initial stub fallback.

### 5) JSON parsing (robust, no date dependency)
- **What:** Parse potentially inconsistent JSON shapes without breaking the UI; **no dependence on date**.
- **What we did:**  
  - Support multiple response shapes for `/dams/{id}/resources/latest`:  
    - A single object;  
    - `{ "resources": [ ... ] }` (we pick the last item that has numbers);  
    - `{ "resource": {…} }` or `{ "data": {…} }`;  
    - **Loose dictionary** fallback with field name aliases (e.g. `percent_full`, `percentage_full`, `accessible_storage_percentage`, etc.).  
  - The UI only needs numeric fields (`percentFull`, `volume`, `inflow`, `release`); **dates are ignored**.
- **Where:**  
  - `DamListViewModel.tryParseLatest(from:)`  
  - `DamListViewModel.damResourceFromLooseDict(_:)`  
  - `Model/DamResource.swift` – contains optional numeric fields only; *no date is required*.

### 6) Local data (persistence) – Favorites (local only)
- **What:** Use local persistence feature (choose local vs cloud → **local**).
- **What we did:** A simple **FavoritesStore** that persists favorite dam IDs locally (e.g., JSON on disk / `UserDefaults`). The List shows favorite toggles; previews or app root inject `FavoritesStore` via `.environmentObject`.
- **Where:**  
  - `Persistence/FavoritesStore.swift` (ObservableObject).  
  - Used by `DamListView` (favorite toggling).  
  - **Note:** In previews, remember to inject `.environmentObject(FavoritesStore())` to avoid crashes.

### 7) SPM package (swift-collections)
- **What:** Integrate a SwiftPM dependency and show it used in code.
- **What we did:** Added **`swift-collections`** and use `OrderedDictionary` as a small **MRU cache** for latest resource per dam.
- **Where:**  
  - `DamListViewModel.latestByDam: OrderedDictionary<String, DamResource>`  
  - On new latest: we re-insert to keep it **most-recent**; when count exceeds **40**, drop the oldest.  
  - This demonstrates **why** `OrderedDictionary` is appropriate: O(1) lookup + predictable insertion order, ideal for MRU trimming.

### 8) Build flags & configuration management
- **What:** Switch between stub and real network easily.
- **What we did:**  
  - `BuildFlags.useNetwork` gates all network calls.  
  - If keys are empty and flag is off, the app keeps the stub data (with a console log).
- **Where:**  
  - `Support/BuildFlags.swift`  
  - `DamListViewModel.shouldUseNetwork`, `loadFromNetworkReplacingStub()`.

### 9) Error handling & state
- **What:** Convey loading and error states in UI.
- **What we did:**  
  - `vm.isLoading` → `ProgressView()` overlay.  
  - `vm.lastError` → `.alert` in `DamListView`.  
  - Empty-state with `ContentUnavailableView`.
- **Where:**  
  - `DamListView`.

### 10) Unit tests only (no UI tests)
- **What:** Keep unit tests; remove UI tests.
- **What we did:**  
  - Project retains **Unit Test target**  
  - All **UI Test** targets are removed.
- **Where:**  
  - `Tests/DamResourceTests`.  
  - No `UITests` target in the project.

---

## Getting started

1. **Keys:**  
   In `DamListViewModel`:
   - `AUTH_BASIC` 
   - `API_KEY`  
   Both are required by some endpoints.

---

## Known limitations

- API has rate limits (408/429). The ViewModel applies a brief global cooldown and per-dam TTL (5s).  
- Latest metrics intentionally ignore dates and only render numeric fields.  
- No offline sync; Favorites persistence is local only.

---

## File map (quick index)

- **Model**: `Dam.swift`, `DamResource.swift`  
- **ViewModel**: `DamListViewModel.swift` (auth, headers, GETRaw/GET, stub fallback, MRU, JSON parsing)  
- **Views**: `DamListView.swift`, `DamDetailView.swift`  
- **Support**: `BuildFlags.swift`, `StubLoader.swift`  
- **Persistence**: `FavoritesStore.swift` (local, no cloud)  
- **Tests**: `DamResourceTests` (unit tests only)
