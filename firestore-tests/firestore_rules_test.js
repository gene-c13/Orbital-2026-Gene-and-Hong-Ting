// Tests for firestore.rules, run against the real Firestore emulator so
// they check the actual rules file, not a copy of the logic.
//
// Setup (one time):   cd firestore-tests && npm install
// Run (from the project root, so it can find firestore.rules):
//   firebase emulators:exec --only firestore "cd firestore-tests && npm test"
//
// Or, in two terminals:
//   1) firebase emulators:start --only firestore
//   2) cd firestore-tests && npm test

const { readFileSync } = require('node:fs');
const { before, after, beforeEach, describe, test } = require('node:test');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'after-hours-rules-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// Writes data directly, bypassing the rules - for setting up a starting
// state (e.g. "a post that already exists") before the test itself runs.
async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(path).set(data);
  });
}

describe('users/{uid}', () => {
  test('an unauthenticated user cannot read a profile', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.collection('users').doc('alice').get());
  });

  test('a user can write their own profile', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(db.collection('users').doc('alice').set({ username: 'alice' }));
  });

  test("a user cannot write someone else's profile", async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(db.collection('users').doc('bob').set({ username: 'hacked' }));
  });

  test("a user cannot fake stat fields on someone else's profile", async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(
      db.collection('users').doc('bob').set({ hours_this_month: 999 }, { merge: true }),
    );
  });
});

describe('posts/{postId}', () => {
  test("a user cannot edit the caption on someone else's post", async () => {
    await seed('posts/p1', { uid: 'alice', caption: 'original', is_public: true, likes: 0, comment_count: 0 });
    const db = testEnv.authenticatedContext('bob').firestore();
    await assertFails(db.collection('posts').doc('p1').update({ caption: 'hacked' }));
  });

  test('a user CAN like someone else\'s post (only likes/comment_count change)', async () => {
    await seed('posts/p2', { uid: 'alice', caption: 'original', is_public: true, likes: 0, comment_count: 0 });
    const db = testEnv.authenticatedContext('bob').firestore();
    await assertSucceeds(db.collection('posts').doc('p2').update({ likes: 1 }));
  });

  test("a user cannot flip is_public on someone else's post", async () => {
    await seed('posts/p3', { uid: 'alice', caption: 'original', is_public: true, likes: 0, comment_count: 0 });
    const db = testEnv.authenticatedContext('bob').firestore();
    await assertFails(db.collection('posts').doc('p3').update({ is_public: false }));
  });
});

describe('users/{uid}/friends/{friendUid}', () => {
  test('a user cannot write a friendship they are not part of', async () => {
    const db = testEnv.authenticatedContext('charlie').firestore();
    await assertFails(
      db.collection('users').doc('alice').collection('friends').doc('bob').set({ since: 'now' }),
    );
  });

  test("a user CAN add themself into someone else's friends list (accept flow)", async () => {
    const db = testEnv.authenticatedContext('bob').firestore();
    await assertSucceeds(
      db.collection('users').doc('alice').collection('friends').doc('bob').set({ since: 'now' }),
    );
  });
});

describe('chats/{chatId}', () => {
  test('a participant can read their own chat', async () => {
    await seed('chats/c1', { participants: ['alice', 'bob'] });
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(db.collection('chats').doc('c1').get());
  });

  test('a non-participant cannot read a single chat by id', async () => {
    await seed('chats/c2', { participants: ['alice', 'bob'] });
    const db = testEnv.authenticatedContext('charlie').firestore();
    await assertFails(db.collection('chats').doc('c2').get());
  });

  test('a non-participant cannot list/query the chats collection either', async () => {
    await seed('chats/c3', { participants: ['alice', 'bob'] });
    // Deliberately no .where() filter - this is the exact query a bad actor
    // would try. Before the fix, this succeeded and returned every chat.
    const db = testEnv.authenticatedContext('charlie').firestore();
    await assertFails(db.collection('chats').get());
  });
});

describe('usernames/{username}', () => {
  test('a user can claim a free username', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(db.collection('usernames').doc('partyanimal').set({ uid: 'alice' }));
  });

  test('a different user cannot overwrite a username that is already taken', async () => {
    await seed('usernames/partyanimal', { uid: 'alice' });
    const db = testEnv.authenticatedContext('bob').firestore();
    await assertFails(db.collection('usernames').doc('partyanimal').set({ uid: 'bob' }));
  });
});
