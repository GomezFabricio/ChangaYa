// on_user_create.ts — Cloud Function v1 auth trigger (ADR-D01: no-blocking)
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

/**
 * Handler interno exportado para unit tests.
 *
 * SC-H-01: Crea users/{uid} y subscriptions/{uid} con batch atómico.
 * SC-H-02: Idempotente — hace early return si users/{uid} ya existe.
 * SC-H-03: Batch atómico — ambos documentos o ninguno.
 */
export async function onUserCreateHandler(
  user: admin.auth.UserRecord
): Promise<void> {
  const db = admin.firestore();

  // SC-H-02: Idempotencia — si el documento ya existe, no sobreescribir
  const userRef = db.collection("users").doc(user.uid);
  const existingDoc = await userRef.get();
  if (existingDoc.exists) {
    return;
  }

  const subscriptionRef = db.collection("subscriptions").doc(user.uid);

  // SC-H-01: Batch atómico — users/{uid} + subscriptions/{uid}
  const batch = db.batch();

  batch.set(userRef, {
    uid: user.uid,
    email: user.email ?? "",
    displayName: user.displayName ?? null,
    photoURL: user.photoURL ?? null,
    role: "client",
    onboardingComplete: false,
    emailVerified: user.emailVerified,
    suspendedUntil: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  batch.set(subscriptionRef, {
    uid: user.uid,
    plan: "free",
    status: "active",
    activeUntil: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // SC-H-03: Si batch.commit() falla, ningún documento queda escrito
  await batch.commit();
}

export const onUserCreate = functions
  .region("southamerica-east1")
  .auth.user()
  .onCreate(async (user) => {
    await onUserCreateHandler(user);
  });
