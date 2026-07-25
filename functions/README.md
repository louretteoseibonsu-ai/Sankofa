# Sankofa Twi — Admin Cloud Functions

Server-side functions that run with Admin SDK privileges. Right now there is one:

- **`adminDeleteUser`** — permanently deletes a user's Auth login **and** their
  Firestore records (`users/{uid}`, `leaderboard/{uid}`). Called from the in-app
  Admin panel (Profile → Team → Admin panel → Delete).

Every function re-checks, server-side, that the caller is listed in
`admins/{uid}` before doing anything. The client/Firestore rules can't be
trusted on their own for destructive actions, so this check is the real gate.

---

## One-time setup

1. **Blaze plan required.** Callable Cloud Functions don't run on the free Spark
   plan. Upgrade the project (`sankofa-twi`) to Blaze in the Firebase console →
   *Settings → Usage and billing*. It still has a generous free tier.

2. **Install the Firebase CLI** (if you haven't):

   ```bash
   npm install -g firebase-tools
   firebase login
   ```

3. **Install function dependencies:**

   ```bash
   cd ~/SankofaTwi.0.v.0.2/functions
   npm install
   ```

---

## Deploy

From the repo root (`~/SankofaTwi.0.v.0.2`):

```bash
# Functions only
firebase deploy --only functions

# Or functions + Firestore rules together
firebase deploy --only functions,firestore:rules
```

The first deploy will ask to enable the Cloud Functions, Cloud Build, and
Artifact Registry APIs — say yes. The function deploys to the default region
`us-central1`, which matches the Flutter `cloud_functions` SDK default, so no
region config is needed.

To watch logs after deploy:

```bash
firebase functions:log
```

---

## Making someone an admin

Admin membership is an allow-list in Firestore. There is **no** UI or function to
grant it — it's done by hand on purpose, so a compromised app account can never
escalate itself.

1. Find the person's **Auth UID**: Firebase console → *Authentication → Users* →
   copy the User UID for their email.
2. Go to *Firestore Database → Data*.
3. Create (or open) the **`admins`** collection.
4. Add a document whose **Document ID is exactly that UID**.
5. Give it any field for your own reference, e.g.:

   | Field   | Type   | Value                          |
   | ------- | ------ | ------------------------------ |
   | `email` | string | `teammate@example.com`         |
   | `addedBy` | string | `lourette`                   |
   | `addedAt` | timestamp | (now)                     |

That's it — next time they open Profile, the **Admin panel** card appears, and
the Firestore rules + `adminDeleteUser` will accept their requests.

**To revoke admin:** delete that document from `admins`. Access is removed the
next time their app re-checks (on app relaunch).

---

## What the admin panel can do

| Action          | Mechanism            | Reversible? |
| --------------- | -------------------- | ----------- |
| Make/Remove premium | Firestore write  | Yes         |
| Grant +50 pedis | Firestore write      | n/a         |
| Suspend / Restore | `disabled` flag, enforced at the app gate | Yes |
| **Delete**      | `adminDeleteUser` Cloud Function | **No — permanent** |

Prefer **Suspend** for anything you might want to undo. **Delete** removes the
Auth login and cannot be reversed.

---

## Safety notes

- The function refuses to delete the **caller's own** account (use Profile →
  Delete account for that, or another admin).
- Deleting an already-removed Auth user is treated as success (idempotent).
- `admins/{uid}` is **read-own, write-denied** in `firestore.rules` — clients can
  never add themselves; only the console (or a backend with Admin SDK) can.
