# Project Scope: AquaWatch

This document defines the boundaries of the AquaWatch project, outlining what is included (In-Scope), what is excluded (Out-of-Scope), and the key constraints.

## 1. Project In-Scope

### User Interfaces & Roles
*   **Citizen App (Mobile)**:
    *   Authentication (Sign-up/Login).
    *   Submission form for water quality (Image, Location, Notes).
    *   Interactive map viewing (hotspots, verified data).
    *   Personal profile and history of submissions.
*   **Authority Dashboard (Mobile/Web)**:
    *   Review queue of community submissions.
    *   Verification tools (approve, reject, or request more info).
    *   Basic analytics and trend visualization.

### Key Functional Features
*   **AI Parameter Detection**: Estimation of pH, TDS, EC, and Salinity from user-captured photos.
*   **Geospatial Tracking**: Automated tagging of submissions with GPS coordinates.
*   **Data Synchronization**: Background syncing for data captured while offline.
*   **Real-time Alerts**: Push notifications for verification status and local environmental warnings.

### Technical Platforms
*   **Mobile**: Cross-platform support for Android and iOS using Flutter.
*   **Backend**: Cloud-based infrastructure using Firebase (Auth, Firestore, Storage, Messaging).

---

## 2. Project Out-of-Scope (Exclusions)

*   **Chemical Laboratory Testing**: The app does not replace professional lab testing; it provides estimations and community observations.
*   **Physical Sensor Manufacturing**: The project does not include the hardware design or production of physical IoT sensors (unless integrated later via API).
*   **Direct Water Treatment**: AquaWatch monitors quality but does not include features for controlling water treatment hardware or automated filtering.
*   **Desktop App Development**: Currently, the focus is strictly on Mobile (Android/iOS) and basic Web interfaces for authorities.

---

## 3. Constraints & Dependencies

*   **Connectivity**: While offline mode exists, periodic internet access is required for AI processing (if cloud-based) and synchronization.
*   **Hardware Limitations**: Accuracy of AI detection depends on the user's camera quality and ambient lighting conditions.
*   **Legal Compliance**: Data privacy must adhere to local regulations regarding user location and environmental reporting.
*   **API Limits**: Usage is subject to the quotas of free/paid tiers for Google Maps and Firebase.

---

## 4. Target Audience

*   **Primary**: Residents in areas with inconsistent water quality, environmental activists, and citizen scientists.
*   **Secondary**: Local government environmental departments, water utility companies, and NGO workers.
