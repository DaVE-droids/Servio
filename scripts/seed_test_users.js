// Local-only admin tooling for seeding test accounts into the live Servio
// Firebase project. Requires scripts/servio-account.json (a service account
// key — never commit it; it is gitignored, as are seed-output.json and
// node_modules/. This script itself IS committed, so it must never contain
// a password).
//
// Usage:
//   cd scripts && npm install
//   SEED_PASSWORD='...' SEED_COORDINATOR_PASSWORD='...' node seed_test_users.js
//
// Passwords come from the environment rather than this file because the
// file is in git: a committed password would let anyone who can see the
// repository sign in to the live project. The coordinator gets its own
// password because a coordinator account can read every student's record.
//
// Uses the Firebase Admin SDK, which bypasses Firestore security rules —
// this is intentional and required, since the rules only allow a client to
// self-register with role 'student' (see firestore.rules,
// isValidStudentProfileCreate). Lecturers can now self-register in the app
// (and wait for approval); coordinators still can't, by design.

const admin = require('firebase-admin');
const serviceAccount = require('./servio-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

const PASSWORD = process.env.SEED_PASSWORD;
const COORDINATOR_PASSWORD = process.env.SEED_COORDINATOR_PASSWORD;
if (!PASSWORD || !COORDINATOR_PASSWORD) {
  console.error(
    'Set SEED_PASSWORD (students and lecturers) and SEED_COORDINATOR_PASSWORD ' +
      'in the environment. Passwords are deliberately not stored in this file.',
  );
  process.exit(1);
}

// A test coordinator, so the admin screens can be exercised end to end
// without using the real coordinator's personal account.
const coordinators = [
  {
    firstName: 'Grace',
    lastName: 'Okon',
    email: 'coordinator.okon@servio.test',
    department: 'Computer Science',
    faculty: 'Natural Sciences',
    staffId: 'CSC/COORD/001',
    phoneNumber: '+2348012340100',
  },
];

const lecturers = [
  {
    firstName: 'Samuel',
    lastName: 'Johnson',
    email: 'lecturer.johnson@servio.test',
    department: 'Computer Science',
    faculty: 'Natural Sciences',
    staffId: 'CSC/STAFF/001',
    phoneNumber: '+2348012340001',
  },
  {
    firstName: 'Ngozi',
    lastName: 'Eze',
    email: 'lecturer.eze@servio.test',
    department: 'Computer Science',
    faculty: 'Natural Sciences',
    staffId: 'CSC/STAFF/002',
    phoneNumber: '+2348012340002',
  },
  {
    firstName: 'Chinedu',
    lastName: 'Okafor',
    email: 'lecturer.okafor@servio.test',
    department: 'Electrical Engineering',
    faculty: 'Engineering',
    staffId: 'EEE/STAFF/001',
    phoneNumber: '+2348012340003',
  },
];

const students = [
  {
    firstName: 'Amaka',
    lastName: 'Nwosu',
    email: 'student.nwosu@servio.test',
    department: 'Computer Science',
    faculty: 'Natural Sciences',
    matricNumber: 'CSC/2022/014',
    phoneNumber: '+2348023450001',
  },
  {
    firstName: 'Tunde',
    lastName: 'Bakare',
    email: 'student.bakare@servio.test',
    department: 'Computer Science',
    faculty: 'Natural Sciences',
    matricNumber: 'CSC/2022/027',
    phoneNumber: '+2348023450002',
  },
  {
    firstName: 'Fatima',
    lastName: 'Bello',
    email: 'student.bello@servio.test',
    department: 'Electrical Engineering',
    faculty: 'Engineering',
    matricNumber: 'EEE/2022/009',
    phoneNumber: '+2348023450003',
  },
];

async function upsertAccount({ role, firstName, lastName, email, department, faculty, staffId, matricNumber, phoneNumber }) {
  const password = role === 'coordinator' ? COORDINATOR_PASSWORD : PASSWORD;
  let userRecord;
  try {
    userRecord = await auth.createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`,
      emailVerified: true,
    });
    console.log(`created auth user: ${email} (${userRecord.uid})`);
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      userRecord = await auth.getUserByEmail(email);
      console.log(`auth user already exists: ${email} (${userRecord.uid}) — reusing`);
    } else {
      throw error;
    }
  }

  const now = admin.firestore.Timestamp.now();
  await db.collection('users').doc(userRecord.uid).set(
    {
      uid: userRecord.uid,
      firstName,
      lastName,
      email,
      phoneNumber: phoneNumber ?? null,
      role,
      department,
      faculty: faculty ?? null,
      matricNumber: matricNumber ?? null,
      staffId: staffId ?? null,
      profilePhotoUrl: '',
      isEmailVerified: true,
      isActive: true,
      institutionId: null,
      createdAt: now,
      updatedAt: now,
    },
    { merge: true },
  );
  console.log(`  -> wrote users/${userRecord.uid} (role: ${role})`);

  return { role, email, password, uid: userRecord.uid };
}

async function main() {
  const created = [];

  for (const coordinator of coordinators) {
    created.push(await upsertAccount({ role: 'coordinator', ...coordinator }));
  }
  for (const lecturer of lecturers) {
    created.push(await upsertAccount({ role: 'lecturer', ...lecturer }));
  }
  for (const student of students) {
    created.push(await upsertAccount({ role: 'student', ...student }));
  }

  const fs = require('fs');
  fs.writeFileSync('./seed-output.json', JSON.stringify(created, null, 2));

  console.log('\nDone. Emails and passwords saved to scripts/seed-output.json (gitignored).');
}

main().catch((error) => {
  console.error('Seed script failed:', error);
  process.exitCode = 1;
});
