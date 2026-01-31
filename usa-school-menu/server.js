/**
 * usa-school-menu API
 * Serves school breakfast/lunch menus by schoolId and date.
 * GET /api/menu?schoolId=<id>&date=YYYY-MM-DD
 * Response: { "breakfast": ["item1", ...], "lunch": ["item1", ...] }
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const DATA_DIR = path.join(__dirname, 'data', 'schools');
const PORT = process.env.PORT || 3000;

function getLocalIPs() {
  const nets = os.networkInterfaces();
  const ips = [];
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) ips.push(net.address);
    }
  }
  return ips;
}

function parseQuery(url) {
  const i = url.indexOf('?');
  if (i === -1) return {};
  const q = new URLSearchParams(url.slice(i));
  return { schoolId: q.get('schoolId'), date: q.get('date') };
}

function readSchoolMenu(schoolId) {
  const file = path.join(DATA_DIR, `${schoolId}.json`);
  if (!fs.existsSync(file)) return null;
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return null;
  }
}

function handleMenuRequest(schoolId, date) {
  if (!schoolId || !date) {
    return { status: 400, body: { error: 'Missing schoolId or date' } };
  }
  const menu = readSchoolMenu(schoolId);
  if (!menu || !menu[date]) {
    return { status: 200, body: { breakfast: [], lunch: [] } };
  }
  const day = menu[date];
  return {
    status: 200,
    body: {
      breakfast: day.breakfast || [],
      lunch: day.lunch || [],
    },
  };
}

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Content-Type', 'application/json');

  const url = req.url || '';
  const [pathname] = url.split('?');

  if (req.method === 'GET' && pathname === '/api/menu') {
    const { schoolId, date } = parseQuery(url);
    const result = handleMenuRequest(schoolId, date);
    res.statusCode = result.status;
    res.end(JSON.stringify(result.body));
    return;
  }

  if (req.method === 'GET' && (pathname === '/' || pathname === '/health')) {
    res.statusCode = 200;
    res.end(JSON.stringify({ ok: true, service: 'usa-school-menu' }));
    return;
  }

  res.statusCode = 404;
  res.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`usa-school-menu API listening on http://localhost:${PORT}`);
  const ips = getLocalIPs();
  if (ips.length) {
    console.log('  On your iPhone (same Wi-Fi), set USA_SCHOOL_MENU_BASE_URL in Xcode to:');
    ips.forEach((ip) => console.log(`    http://${ip}:${PORT}`));
  }
  console.log('  GET /api/menu?schoolId=<id>&date=YYYY-MM-DD');
});
