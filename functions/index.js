"use strict";

// Sankofa Twi — admin Cloud Functions (Firebase Functions v2).
// These run with Admin SDK privileges, so each one re-checks that the caller
// is in admins/{uid} before doing anything. Deploy with:
//   firebase deploy --only functions

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

// ── Daily push nudges (FCM) ─────────────────────────────────────────────────
// A once-a-day, friendly reminder. Tier 1: gentle "your tro tro is waiting".
// Tier 2 (FOMO): only when a real streak is at risk (last active *yesterday*).
// Social nudges are event-driven and can be added separately. Deploy needs the
// Blaze plan + Cloud Scheduler API enabled.
function _dayKey(d) {
  return (
    d.getFullYear() +
    "-" +
    String(d.getMonth() + 1).padStart(2, "0") +
    "-" +
    String(d.getDate()).padStart(2, "0")
  );
}

exports.sendDailyNudges = onSchedule(
  { schedule: "0 18 * * *", timeZone: "Europe/London" },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const today = _dayKey(now);
    const yd = new Date(now);
    yd.setDate(yd.getDate() - 1);
    const yesterday = _dayKey(yd);

    const snap = await db.collection("users").where("fcmToken", "!=", null).get();
    const messages = [];
    snap.forEach((doc) => {
      const u = doc.data() || {};
      const token = u.fcmToken;
      if (!token || u.notifOptOut === true) return;
      if (u.lastActive === today) return; // already practised today

      const streak = u.streak || 0;
      let title;
      let body;
      if (streak >= 1 && u.lastActive === yesterday) {
        title = "Your " + streak + "-day streak is waiting 🔥";
        body = "A quick lesson keeps the fire going. Yɛn kɔ!";
      } else {
        title = "Your tro tro is waiting 🚐🇬🇭";
        body = "Maakye! Learn a little Twi today.";
      }
      messages.push({ token, notification: { title, body } });
    });

    for (let i = 0; i < messages.length; i += 500) {
      const batch = messages.slice(i, i + 500);
      if (batch.length) {
        const res = await admin.messaging().sendEach(batch);
        console.log("Nudge batch sent:", res.successCount, "of", batch.length);
      }
    }
    console.log("Daily nudges queued:", messages.length);
  }
);

/** Throws unless the caller is signed in AND listed in admins/{uid}. */
async function assertAdmin(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  const doc = await admin.firestore().doc(`admins/${uid}`).get();
  if (!doc.exists) {
    throw new HttpsError("permission-denied", "Admins only.");
  }
  return uid;
}

/**
 * Permanently deletes a user: their Auth login + Firestore records.
 * data: { uid: string }
 */
exports.adminDeleteUser = onCall(async (request) => {
  const callerUid = await assertAdmin(request);

  const targetUid = request.data && request.data.uid;
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "A target 'uid' is required.");
  }
  if (targetUid === callerUid) {
    throw new HttpsError(
      "failed-precondition",
      "You can't delete your own account from the admin panel."
    );
  }

  const db = admin.firestore();
  // Remove app data first (best-effort), then the Auth account.
  await db.doc(`users/${targetUid}`).delete().catch(() => {});
  await db.doc(`leaderboard/${targetUid}`).delete().catch(() => {});

  try {
    await admin.auth().deleteUser(targetUid);
  } catch (e) {
    // If the Auth user is already gone, treat as success.
    if (e.code !== "auth/user-not-found") {
      throw new HttpsError("internal", e.message || "Delete failed.");
    }
  }

  return { ok: true, uid: targetUid };
});

// ── Invite & Earn (referrals) ───────────────────────────────────────────────
const REFERRAL_REWARD = 100; // keep in sync with kInviteRewardPedis in the app
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no easily-confused chars

/** Returns the caller's invite code, creating a unique one on first call. */
exports.getInviteCode = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const db = admin.firestore();
  const userRef = db.doc(`users/${uid}`);
  const snap = await userRef.get();
  const existing = snap.exists && snap.data().referralCode;
  if (existing) return { code: existing };

  for (let attempt = 0; attempt < 10; attempt++) {
    let code = "";
    for (let i = 0; i < 6; i++) {
      code += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
    }
    const codeRef = db.doc(`referralCodes/${code}`);
    const taken = await codeRef.get();
    if (!taken.exists) {
      await codeRef.set({
        uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await userRef.set({ referralCode: code }, { merge: true });
      return { code };
    }
  }
  throw new HttpsError("internal", "Could not generate a code — please retry.");
});

/**
 * Redeems a friend's invite code: credits BOTH users pedis (once) and makes
 * them friends. data: { code: string }
 */
exports.redeemReferral = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const code = ((request.data && request.data.code) || "")
    .toString()
    .trim()
    .toUpperCase();
  if (!code) throw new HttpsError("invalid-argument", "Enter an invite code.");

  const db = admin.firestore();
  const meRef = db.doc(`users/${uid}`);
  const meSnap = await meRef.get();
  if (meSnap.exists && meSnap.data().referredBy) {
    throw new HttpsError(
      "failed-precondition",
      "You've already redeemed an invite code."
    );
  }

  const codeSnap = await db.doc(`referralCodes/${code}`).get();
  if (!codeSnap.exists) {
    throw new HttpsError("not-found", "That invite code isn't valid.");
  }
  const inviterUid = codeSnap.data().uid;
  if (inviterUid === uid) {
    throw new HttpsError("failed-precondition", "You can't redeem your own code.");
  }

  const inviterRef = db.doc(`users/${inviterUid}`);
  const inviterSnap = await inviterRef.get();
  const meData = (meSnap.exists && meSnap.data()) || {};
  const invData = (inviterSnap.exists && inviterSnap.data()) || {};
  const myName = meData.name || meData.email || "A friend";
  const inviterName = invData.name || invData.email || "A friend";

  const now = admin.firestore.FieldValue.serverTimestamp();

  const batch = db.batch();
  // Record the pending referral. The pedis reward is granted to BOTH users only
  // once this new user finishes their first lesson — see
  // grantReferralOnFirstLesson below (anti-abuse guardrail).
  batch.set(
    meRef,
    { referredBy: inviterUid, referralRewarded: false },
    { merge: true }
  );
  // Connect them as friends straight away so the friends leaderboard works.
  batch.set(
    db.doc(`users/${uid}/friends/${inviterUid}`),
    { name: inviterName, since: now },
    { merge: true }
  );
  batch.set(
    db.doc(`users/${inviterUid}/friends/${uid}`),
    { name: myName, since: now },
    { merge: true }
  );
  await batch.commit();

  return { ok: true, pending: true, reward: REFERRAL_REWARD, inviterName };
});

/**
 * Grants the referral reward to BOTH users once the invited user completes their
 * first lesson. Triggered by writes to users/{uid}; guarded so it only ever pays
 * out once (referralRewarded flips to true).
 */
exports.grantReferralOnFirstLesson = onDocumentWritten(
  "users/{uid}",
  async (event) => {
    const after = event.data && event.data.after && event.data.after.data();
    if (!after) return; // deleted
    if (!after.referredBy || after.referralRewarded === true) return;

    const lessonCount =
      after.lessonBest && typeof after.lessonBest === "object"
        ? Object.keys(after.lessonBest).length
        : 0;
    const completedALesson = lessonCount > 0 || (after.xp || 0) > 0;
    if (!completedALesson) return;

    const uid = event.params.uid;
    const inviterUid = after.referredBy;
    if (!inviterUid || inviterUid === uid) return;

    const db = admin.firestore();
    const inc = (n) => admin.firestore.FieldValue.increment(n);
    const batch = db.batch();
    batch.set(
      db.doc(`users/${uid}`),
      { pedis: inc(REFERRAL_REWARD), referralRewarded: true },
      { merge: true }
    );
    batch.set(
      db.doc(`users/${inviterUid}`),
      { pedis: inc(REFERRAL_REWARD), invitesCount: inc(1) },
      { merge: true }
    );
    await batch.commit();
  }
);
