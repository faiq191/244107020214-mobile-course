# Flutter Week 5 - Local Storage & Offline-First Architecture

This repository demonstrates local data persistence, caching mechanisms, sync queues, and offline-first design patterns in Flutter.

---

## 1. Lab 1: Key-Value Persistence with SharedPreferences

Demonstrates light data persistence for user settings and lightweight application preferences using `shared_preferences`.

### Project Setup

![Setup](screenshots/setupproject.png)

### Folder Structure

![Structure](screenshots/directory.png)

---

## 2. Lab 2: Relational Local Storage with SQLite

Implements robust local storage using SQLite via `sqflite`. Features structured data management and repository pattern architecture for handling offline note CRUD operations.

### Output

![SQLite Notes Implementation](screenshots/lab2.png)

---

## 3. Lab 3: Cache-First Strategy & Sync Queue

Demonstrates an offline-first architecture using a **Cache-First Strategy** alongside a **Sync Queue mechanism**:

- **Cache-First Reads:** Instantly renders cached API responses locally while refreshing updated data in the background.
- **Dirty State Tracking & Sync Queue:** Tracks unsynced local mutations (marked as dirty) during offline mode (e.g., Airplane Mode) and batches them for server synchronization when network connectivity is restored.

### Output

![Offline Sync Queue Simulation](screenshots/lab3.png)
