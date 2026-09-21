const { spawn } = require('child_process');
const path = require('path');

const webDir = path.join(__dirname, 'build', 'web');
const logFile = path.join(__dirname, '.freebuff', 'preview-1a247ada-8108-449c-b96d-eb4f1c747c0c.log');

const child = spawn('python', ['-m', 'http.server', '8083', '--directory', webDir], {
  detached: true,
  stdio: ['ignore', 'pipe', 'pipe'],
  windowsHide: true
});

const fs = require('fs');
const logStream = fs.createWriteStream(logFile);
child.stdout.pipe(logStream);
child.stderr.pipe(logStream);

child.unref();
console.log('PID:', child.pid);
