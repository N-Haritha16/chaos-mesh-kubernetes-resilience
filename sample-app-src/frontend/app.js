const http = require('http');

const port = process.env.PORT || 8080;

const server = http.createServer((_req, res) => {
  if (_req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Chaos Mesh Demo Frontend - Healthy\n');
});

server.listen(port, () => {
  console.log(`Frontend listening on port ${port}`);
});
