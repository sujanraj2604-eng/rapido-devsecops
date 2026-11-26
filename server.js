const http = require('http');

function estimateFare(vehicle, distance) {
    if (vehicle === 'bike') {
        return distance * 10;
    }

    return null;
}

const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html' });

    res.end(`
        <html>
        <head>
            <title>Rapido Clone</title>
        </head>
        <body>
            <h1>Rapido Clone</h1>
            <h2>Ride Booking Application</h2>
            <p>Server is running successfully!</p>
        </body>
        </html>
    `);
});

if (require.main === module) {
    server.listen(3000, () => {
        console.log('Rapido application running on port 3000');
    });
}

module.exports = { estimateFare };
