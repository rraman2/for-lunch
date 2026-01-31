# For Lunch

A simple iOS app that shows **what’s for lunch (and breakfast) at school today**.

- **New users**: Pick your school from a searchable list (by school or district name) and optionally filter by state.
- **Returning users**: See today’s breakfast and lunch menu for your saved school.
- **Launch scope**: Only schools in these **8 states** are supported: **California, Colorado, Maine, Massachusetts, Michigan, Minnesota, New Mexico, Vermont**.

Menu data is loaded in this order:

1. **Bundled** `menus.json` (in the app)
2. **usa-school-menu API** (remote backend in this repo) — see the `usa-school-menu/` folder.
3. **Nearest date** from bundled data (if no exact date)
4. **Nutrislice** (for schools that expose it and have slugs in `schools.json`)

The **usa-school-menu** service is a small API and database of menus (one JSON file per school). You can add Walnut Grove and other schools manually from PDFs there, and automate more schools later.

## Requirements

- Xcode 15+
- iOS 16+

## Opening the project

1. Clone the repo and open `ForLunch.xcodeproj` in Xcode.
2. Select the **ForLunch** scheme and a simulator or device.
3. Set your **Team** under **Signing & Capabilities** if needed.
4. Build and run (⌘R).

## Managing the usa-school-menu service URL

The app calls the **usa-school-menu** API for menu data. The base URL is controlled by the build setting **`USA_SCHOOL_MENU_BASE_URL`** (not hardcoded in Info.plist).

- **Debug** (simulator / local dev): `http://localhost:3000` — run `node server.js` in `usa-school-menu/` and the app will use it.
- **Release** (TestFlight / App Store): Set your production API URL in Xcode:
  1. Select the **ForLunch** project in the navigator.
  2. Select the **ForLunch** target → **Build Settings**.
  3. Search for **USA_SCHOOL_MENU_BASE_URL** (or add it under **User-Defined**).
  4. Set **Release** to your deployed URL (e.g. `https://api.yourdomain.com`).

**Access the service from your iPhone (same Wi‑Fi as your Mac):**

1. **Run the server on your Mac:**  
   `cd usa-school-menu && node server.js` (leave it running).

2. **Find your Mac’s IP address:**  
   - **System Settings → Wi‑Fi → [your network] → Details** (or **Advanced**), or  
   - In Terminal: `ipconfig getifaddr en0` (Wi‑Fi) or `ipconfig getifaddr en1` (Ethernet).  
   Example: `192.168.1.5`.

3. **Point the app at your Mac:**  
   In Xcode: **ForLunch** target → **Build Settings** → search **USA_SCHOOL_MENU_BASE_URL** → set **Debug** to `http://YOUR_MAC_IP:3000` (e.g. `http://192.168.1.5:3000`, no trailing slash).

4. **Build and run on your iPhone** (⌘R with your device selected). The app on the phone will load menus from the server on your Mac.

The simulator always uses `http://localhost:3000`; the device uses whatever you set for **USA_SCHOOL_MENU_BASE_URL**, so you don’t need to change it when switching between simulator and device.

**iPhone not getting menu data (same Wi‑Fi):**

1. **Restart the server** – when you run `node server.js` it now prints the URL(s) to use (e.g. `http://192.168.1.5:3000`). Use that exact URL in Xcode.
2. **Set the URL in Xcode** – ForLunch target → **Build Settings** → **USA_SCHOOL_MENU_BASE_URL** (Debug) = `http://YOUR_MAC_IP:3000` (no trailing slash). Then **Product → Clean Build Folder** (⇧⌘K) and run on your iPhone again.
3. **Test from your Mac** – in Terminal:  
   `curl "http://YOUR_MAC_IP:3000/api/menu?schoolId=walnut-grove-pleasanton-ca&date=2026-01-30"`  
   You should see JSON. If that fails, the server isn’t reachable (e.g. firewall).
4. **Firewall** – **System Settings → Network → Firewall** (or **Security & Privacy → Firewall**). Allow incoming connections for Node, or temporarily turn the firewall off to test.
5. **Same Wi‑Fi** – iPhone and Mac must be on the same Wi‑Fi network (not guest network vs main).

**Deploying the server:** Run `usa-school-menu` on any host (VPS, serverless, etc.) that can serve Node and the `data/schools/*.json` files. Point **USA_SCHOOL_MENU_BASE_URL** (Release) at that host’s base URL (no trailing slash).

## App flow

1. **First launch**: The app shows **Choose Your School** with a state filter bar and search. Only schools in the 8 launch states appear.
2. **Select a school**: Tapping a school saves it and shows **today’s menu** (breakfast and lunch).
3. **Later launches**: The app goes straight to today’s menu for the saved school.
4. **Change school**: Use **Change school** in the menu screen to pick a different school (sheet).

## Adding more schools

The app uses a bundled list of schools in `ForLunch/Resources/schools.json`. Each entry needs:

- `id`: Unique string (e.g. `"cusd-ca"`). **Must match the key you use in `menus.json`** if you add menu data from PDFs.
- `name`: School or district display name.
- `districtName`: District name.
- `stateCode`: Two-letter state code (**only** one of: `CA`, `CO`, `ME`, `MA`, `MI`, `MN`, `NM`, `VT`).
- `nutrisliceDistrictSlug`: (Optional.) Nutrislice API subdomain for fallback live API.
- `nutrisliceSchoolSlug`: (Optional.) Nutrislice school path for fallback live API.

You can omit the Nutrislice fields for schools where you only use PDF-sourced data. Add new objects to the `schools.json` array (only in the 8 states above) and rebuild.

## Adding menu data from PDFs

To show menus for a school without relying on Nutrislice, add entries to `ForLunch/Resources/menus.json`. The file maps **school id** → **date (YYYY-MM-DD)** → **breakfast** and **lunch** item names.

**Format:**

```json
{
  "school-id-from-schools-json": {
    "2025-01-30": {
      "breakfast": ["Item 1", "Item 2"],
      "lunch": ["Item A", "Item B"]
    },
    "2025-01-31": {
      "breakfast": [],
      "lunch": ["Item C"]
    }
  }
}
```

**Steps:**

1. Add the school to `schools.json` with a unique `id` (e.g. `"cusd-ca"`).
2. Download or open the school’s menu PDF (or webpage) for the week/month.
3. For each date you want to show, add an entry under that school id in `menus.json` with `breakfast` and `lunch` arrays of item names (strings).
4. Rebuild the app. The app checks the database first; if it finds today’s date for the selected school, it shows that menu.

You can add as many dates as you like (e.g. a full month). Add new dates when you get new PDFs.

**Using the usa-school-menu API:** The app also calls the `usa-school-menu` backend (see `usa-school-menu/README.md`). To use it: run `node server.js` in `usa-school-menu/`, then run the app. The app reads `USA_SCHOOL_MENU_BASE_URL` from Info.plist (default `http://localhost:3000`). For a device or deployed API, set that key to your server URL (e.g. `https://your-api.com`).

## Project structure

```
ForLunch/
├── ForLunchApp.swift          # App entry
├── Info.plist
├── Models/
│   ├── SupportedState.swift  # 8 launch states
│   ├── School.swift
│   ├── MenuModels.swift      # Nutrislice API models
│   └── MenuDatabaseModels.swift  # menus.json schema
├── Views/
│   ├── ContentView.swift     # Root: school picker vs menu
│   ├── SchoolPickerView.swift
│   └── MenuView.swift        # Today’s breakfast & lunch (DB first, then Nutrislice)
├── Services/
│   ├── MenuService.swift     # Nutrislice API client (fallback)
│   ├── MenuDatabaseService.swift  # Loads bundled menus.json
│   ├── RemoteMenuService.swift   # Calls usa-school-menu API
│   ├── SchoolSearchService.swift
│   └── SchoolStorage.swift   # UserDefaults for selected school
└── Resources/
    ├── schools.json          # Bundled school list (launch states only)
    └── menus.json            # Menu data by school id and date (from PDFs)
```

## License

Use and modify as you like for your own deployment.
