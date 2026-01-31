# usa-school-menu

Database and API for US school breakfast/lunch menus. The **For Lunch** iOS app calls this service to load menus.

## Data layout

- **One file per school:** `data/schools/<schoolId>.json`
- **School ID** must match the `id` in the For Lunch app’s `schools.json` (e.g. `walnut-grove-pleasanton-ca`).
- **Format** of each file: date (YYYY-MM-DD) → breakfast and lunch arrays.

Example `data/schools/walnut-grove-pleasanton-ca.json`:

```json
{
  "2025-01-30": {
    "breakfast": ["Breakfast Burrito", "Cold Cereal", "Fruit", "Milk"],
    "lunch": ["Cheese Pizza", "Chicken Sandwich", "Garden Salad", "Milk"]
  },
  "2025-01-31": {
    "breakfast": ["..."],
    "lunch": ["..."]
  }
}
```

Add as many dates as you have (e.g. from a monthly PDF). You can create files by hand from district PDFs; automation can be added later.

## API

- **GET** `/api/menu?schoolId=<id>&date=YYYY-MM-DD`  
  Returns `{ "breakfast": ["..."], "lunch": ["..."] }` for that school and date.  
  If the school or date is missing, returns `{ "breakfast": [], "lunch": [] }`.

- **GET** `/` or `/health`  
  Returns `{ "ok": true }` for health checks.

## Run locally

```bash
cd usa-school-menu
node server.js
```

Listens on **http://localhost:3000** (or `PORT` if set).

## Adding Walnut Grove Elementary (manual from PDF)

1. Open `data/schools/walnut-grove-pleasanton-ca.json`.
2. For each day in the PDF, add an entry with key `YYYY-MM-DD` and `breakfast` / `lunch` arrays of item names.
3. Save the file. The server reads from disk on each request (no restart needed).

## Adding more schools

1. Add the school to the For Lunch app’s `schools.json` (with the same `id` you use here).
2. Create `data/schools/<schoolId>.json` with the same structure as above.
3. Fill dates from the school’s PDF or website.

## Deployment

Run `node server.js` behind any HTTP server (e.g. reverse proxy). Set `PORT` as needed. For the iOS app, set the base URL in the app (see For Lunch README) to your deployed host, e.g. `https://your-domain.com`.
