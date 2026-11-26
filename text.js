cat > test/fare.test.js << 'EOF'
const test = require('node:test');
const assert = require('node:assert');
const { estimateFare } = require('../server');

test('bike fare for 5 km', () => {
  assert.strictEqual(estimateFare('bike', 5), 50);
});

test('invalid vehicle', () => {
  assert.strictEqual(estimateFare('plane', 5), null);
});
EOF`
