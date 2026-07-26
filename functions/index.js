const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// Ordered highest threshold first: first match wins.
const CROWD_THRESHOLDS = [
  { min: 30, level: "High" },
  { min: 2, level: "Medium" },
];

function crowdLevelForCount(count) {
  for (const { min, level } of CROWD_THRESHOLDS) {
    if (count >= min) return level;
  }
  return "Low";
}
exports.crowdLevelForCount = crowdLevelForCount;

// Fires on both create and delete of an attendee doc, so joining and
// leaving the guestlist both keep crowd_level accurate.
exports.updateCrowdLevel = onDocumentWritten(
  "events/{eventId}/attendees/{attendeeId}",
  async (event) => {
    const { eventId } = event.params;
    const attendeesRef = db
      .collection("events")
      .doc(eventId)
      .collection("attendees");

    // Aggregation count query: always matches the true subcollection size,
    // never drifts like an incrementing counter could.
    const snapshot = await attendeesRef.count().get();
    const attendeeCount = snapshot.data().count;

    await db.collection("events").doc(eventId).update({
      attendee_count: attendeeCount,
      crowd_level: crowdLevelForCount(attendeeCount),
    });
  }
);
