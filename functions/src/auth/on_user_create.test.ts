/**
 * Tests para onUserCreate — SC-H-01, SC-H-02, SC-H-03
 *
 * Estos tests usan Firebase Admin SDK apuntando al Firestore Emulator.
 * Para correr contra emulator: firebase emulators:exec "cd functions && npm test"
 *
 * En entorno sin emulator, usar FIRESTORE_EMULATOR_HOST=localhost:8080
 */

import * as admin from "firebase-admin";
import { onUserCreateHandler } from "./on_user_create";

const PROJECT_ID = "demo-changaya";

beforeAll(() => {
  process.env["FIRESTORE_EMULATOR_HOST"] = "localhost:8080";
  if (!admin.apps.length) {
    admin.initializeApp({ projectId: PROJECT_ID });
  }
});

afterAll(async () => {
  await admin.app().delete();
});

async function clearFirestore(): Promise<void> {
  const db = admin.firestore();
  const collections = ["users", "subscriptions"];
  for (const col of collections) {
    const snapshot = await db.collection(col).get();
    if (!snapshot.empty) {
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  }
}

function makeUserRecord(
  overrides: Partial<admin.auth.UserRecord>,
): admin.auth.UserRecord {
  return {
    uid: "test-uid",
    email: "test@example.com",
    emailVerified: false,
    displayName: undefined,
    photoURL: undefined,
    phoneNumber: undefined,
    disabled: false,
    metadata: {} as admin.auth.UserMetadata,
    providerData: [],
    customClaims: undefined,
    tenantId: undefined,
    tokensValidAfterTime: undefined,
    multiFactor: undefined,
    toJSON: () => ({}),
    ...overrides,
  } as admin.auth.UserRecord;
}

describe("onUserCreate", () => {
  beforeEach(async () => {
    await clearFirestore();
  });

  describe("SC-H-01: Creación exitosa — email/password", () => {
    it("crea users/{uid} con role: client, onboardingComplete: false", async () => {
      const uid = "test-uid-email";
      const email = "test@example.com";

      await onUserCreateHandler(
        makeUserRecord({ uid, email, emailVerified: false }),
      );

      const db = admin.firestore();
      const userDoc = await db.collection("users").doc(uid).get();

      expect(userDoc.exists).toBe(true);
      const data = userDoc.data()!;
      expect(data["uid"]).toBe(uid);
      expect(data["email"]).toBe(email);
      expect(data["role"]).toBe("client");
      expect(data["onboardingComplete"]).toBe(false);
      expect(data["emailVerified"]).toBe(false);
      expect(data["suspendedUntil"]).toBeNull();
      expect(data["createdAt"]).toBeDefined();
    });

    it("crea subscriptions/{uid} con plan: free, activeUntil: null", async () => {
      const uid = "test-uid-sub";

      await onUserCreateHandler(makeUserRecord({ uid }));

      const db = admin.firestore();
      const subDoc = await db.collection("subscriptions").doc(uid).get();

      expect(subDoc.exists).toBe(true);
      const data = subDoc.data()!;
      expect(data["uid"]).toBe(uid);
      expect(data["plan"]).toBe("free");
      expect(data["activeUntil"]).toBeNull();
      expect(data["createdAt"]).toBeDefined();
    });

    it("SC-H-01 Google: emailVerified es true para proveedor Google", async () => {
      const uid = "test-uid-google";

      await onUserCreateHandler(
        makeUserRecord({
          uid,
          email: "google@example.com",
          emailVerified: true,
          photoURL: "https://photo.url",
        }),
      );

      const db = admin.firestore();
      const userDoc = await db.collection("users").doc(uid).get();
      expect(userDoc.data()!["emailVerified"]).toBe(true);
    });
  });

  describe("SC-H-02: Idempotencia — documento ya existe", () => {
    it("no sobreescribe users/{uid} si ya existe", async () => {
      const uid = "test-uid-idempotent";
      const db = admin.firestore();

      // Pre-crear documento con datos distintos
      await db.collection("users").doc(uid).set({
        uid,
        email: "original@example.com",
        role: "admin",
        onboardingComplete: true,
        emailVerified: true,
        suspendedUntil: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Ejecutar función nuevamente para el mismo uid
      await onUserCreateHandler(
        makeUserRecord({
          uid,
          email: "new@example.com",
          emailVerified: false,
        }),
      );

      // El documento original no debe haber cambiado
      const userDoc = await db.collection("users").doc(uid).get();
      const data = userDoc.data()!;
      expect(data["role"]).toBe("admin");
      expect(data["email"]).toBe("original@example.com");
      expect(data["onboardingComplete"]).toBe(true);
    });
  });

  describe("SC-H-03: Atomicidad — fallo en batch", () => {
    it("no escribe ningún documento si el batch falla (atomicidad)", async () => {
      const uid = "test-uid-atomic";
      const db = admin.firestore();

      // Mockear batch.commit para que falle
      const realBatch = db.batch();
      jest.spyOn(db, "batch").mockReturnValueOnce({
        ...realBatch,
        set: jest.fn(),
        commit: jest
          .fn()
          .mockRejectedValueOnce(new Error("Simulated batch failure")),
      } as unknown as admin.firestore.WriteBatch);

      await expect(
        onUserCreateHandler(
          makeUserRecord({ uid, email: "atomic@example.com" }),
        ),
      ).rejects.toThrow("Simulated batch failure");

      // Verificar que ningún documento fue escrito
      const userDoc = await db.collection("users").doc(uid).get();
      const subDoc = await db.collection("subscriptions").doc(uid).get();

      expect(userDoc.exists).toBe(false);
      expect(subDoc.exists).toBe(false);

      jest.restoreAllMocks();
    });
  });
});
