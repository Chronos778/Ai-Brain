---
name: firebase
description: Firebase patterns for Firestore, Auth, Cloud Functions, and Storage
---
# Firebase

Full Google Cloud stack. Firestore + Auth + Functions + Storage + Hosting.

## How I Build
- Modular SDK (v9+): `import { getFirestore } from 'firebase/firestore'`.
- Cloud Functions for all backend logic — client stays thin.
- Firestore Security Rules on everything — never trust client-side validation alone.
- Callable functions over HTTP triggers for internal calls.
- Environment variables locally, Firebase config for production.

## My Firebase Project
**techshift-google (Smart City Reporter)**: Firebase Auth (Google Sign-In), Firestore, Storage, Cloud Functions, Vision API, Gemini AI, Google Maps.

## Expert Decisions

**Data modeling**: Denormalize for read performance — reads are cheap, joins don't exist. Subcollections for 1-to-many. Keep documents under 1MB. `serverTimestamp()` always — client clocks lie.

**Functions**: Cold starts are the biggest perf issue — keep bundles small, lazy-load heavy deps inside handlers. `functions.region()` for proximity. Firestore triggers can fire multiple times — always make handlers idempotent. `defineSecret()` for API keys, not env vars.

**Auth**: `onAuthStateChanged()` as single listener, not per-component. ID tokens for authenticated API calls, verify server-side. Custom claims for roles.

**Security rules**: Default deny, open explicitly. Owner check: `request.auth.uid == resource.data.userId`. Validate data shape in rules. Test mode is for development ONLY.

**Real-time**: `onSnapshot()` for live data. Unsubscribe on unmount always. Don't attach per-component — centralize in a service or store.

**Google Cloud AI**: Vision API and Gemini from Cloud Functions only — never expose API keys in client code. Rate limit API calls. Handle `RESOURCE_EXHAUSTED` specifically.

## Mistakes That Cost Hours
- Test mode security rules in production — anyone can read/write everything
- Reading entire collections without filters — unbounded reads, costs spike
- v8 import syntax — use modular v9+ imports
- Heavy deps in Cloud Function global scope — adds seconds to every cold start
- Forgetting `onSnapshot()` cleanup — memory leaks, phantom listeners still firing
- Large blobs in Firestore documents — use Storage for files
