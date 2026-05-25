# LendTracker

A Flutter app for keeping track of money you've lent out. Record borrowers, log loans
and repayments, and see at a glance who still owes you and what's overdue — all stored
locally on your device.

## Features

- **Dashboard** — totals for amount lent, repaid, and outstanding, plus a count of overdue loans.
- **Borrowers** — add people manually or import them from your device contacts.
- **Loans** — record principal, the date lent, an optional due date, notes, and a status.
- **Repayments** — log partial or full repayments against a loan and track the remaining balance.
- **Export** — export your data for backup or sharing.
- **Offline-first** — everything is stored on-device in a local SQLite database; no account or network required.

## Tech stack

- [Flutter](https://flutter.dev/) (Dart SDK `^3.8.1`)
- [`sqflite`](https://pub.dev/packages/sqflite) — local SQLite persistence
- [`flutter_contacts`](https://pub.dev/packages/flutter_contacts) — import borrowers from contacts
- [`intl`](https://pub.dev/packages/intl) — currency and date formatting
- [`path_provider`](https://pub.dev/packages/path_provider) — file locations for the database and exports

## Project structure

```
lib/
  data/      # SQLite database, repository, and export service
  models/    # Borrower, Loan, Repayment, and dashboard/summary models
  screens/   # Dashboard, borrowers, loans, and their detail/form screens
  utils/     # Date helpers and currency formatters
  main.dart  # App entry point
```

> Amounts are stored as integer minor units (e.g. cents) to avoid floating-point rounding errors.

## Getting started

Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed, then:

```bash
flutter pub get        # install dependencies
flutter run            # run on a connected device or emulator
```

To build a release APK:

```bash
flutter build apk --release
```
