// Unit test for crowdLevelForCount(), the pure function inside index.js
// that turns an attendee count into "High" / "Medium" / "Low". No
// Firebase, no emulator - just calling the real exported function.
//
// Run:  cd functions && npm test

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { crowdLevelForCount } = require('./index.js');

test('0 attendees is Low', () => {
  assert.equal(crowdLevelForCount(0), 'Low');
});

test('1 attendee is still Low', () => {
  assert.equal(crowdLevelForCount(1), 'Low');
});

test('2 attendees crosses into Medium', () => {
  assert.equal(crowdLevelForCount(2), 'Medium');
});

test('29 attendees is still Medium', () => {
  assert.equal(crowdLevelForCount(29), 'Medium');
});

test('30 attendees crosses into High', () => {
  assert.equal(crowdLevelForCount(30), 'High');
});

test('a large count is still High', () => {
  assert.equal(crowdLevelForCount(500), 'High');
});
