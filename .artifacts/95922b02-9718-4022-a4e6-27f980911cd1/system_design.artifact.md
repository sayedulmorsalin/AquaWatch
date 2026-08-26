# AquaWatch: System Design

This document outlines the technical architecture, component breakdown, and data flow of the AquaWatch platform.

## 1. High-Level Architecture
AquaWatch follows a standard **Client-Cloud** architecture, leveraging Flutter for cross-platform mobile development and Firebase for backend-as-a-service.

```mermaid
graph TD
    subgraph "Client Side (Flutter Mobile App)"
        Citizen[Citizen Module]
        AuthorityApp[Authority Module]
        UI[Shared UI Components]
    end

    subgraph "Cloud Services (Firebase)"
        Auth[Firebase Auth]
        Firestore[Cloud Firestore - DB]
        Storage[Cloud Storage - Images]
        FCM[Firebase Cloud Messaging]
        AI[Cloud Functions/AI Engine]
    end

    Citizen --> Auth
    Citizen --> Storage
    Citizen --> Firestore
    AuthorityApp --> Firestore
    Firestore --> FCM
    Storage --> AI
    AI --> Firestore
```

## 2. Component Diagram
The internal structure of the Flutter application is modularized by feature.

```mermaid
graph LR
    Main[main.dart] --> AuthSvc[Authentication Module]
    Main --> Home[Home/Map Module]

    Home --> Geo[Geolocation Service]
    Home --> Map[Map Visualization]

    Main --> Report[Water Quality Detection]
    Report --> AI_Svc[AI Parameter Analysis]
    Report --> Sync[Offline Sync Manager]

    Main --> Auth_Panel[Authority Dashboard]
    Auth_Panel --> Verify[Verification Workflow]

    Main --> Profile[User Profile]

    subgraph Shared
        Services[Firebase/API Services]
        Models[Data Models]
    end
```

## 3. Data Flow: Report Submission & Verification
This sequence shows the lifecycle of a water quality report from creation to verification.

```mermaid
sequenceDiagram
    participant C as Citizen
    participant L as Local DB (Offline)
    participant F as Firebase (Storage/Firestore)
    participant AI as AI Engine
    participant A as Authority

    C->>L: Capture Photo & Location
    L->>F: Upload Image (when online)
    F->>AI: Trigger Analysis
    AI-->>F: Save Estimated Parameters (pH, TDS)
    C->>F: Submit Final Report
    F->>A: Push Notification (New Report)
    A->>F: Review & Verify Data
    F->>C: Push Notification (Report Verified)
```

## 4. Database Schema (Firestore Collections)
A simplified view of the primary data entities.

```mermaid
erDiagram
    USERS ||--o{ SUBMISSIONS : "creates"
    USERS {
        string uid
        string name
        string email
        string role "citizen/authority"
    }
    SUBMISSIONS ||--o{ VERIFICATIONS : "reviewed by"
    SUBMISSIONS {
        string id
        string userId
        string imageUrl
        geopoint location
        float pH
        float TDS
        string status "pending/verified/rejected"
        timestamp createdAt
    }
    VERIFICATIONS {
        string id
        string submissionId
        string authorityId
        string comments
        timestamp verifiedAt
    }
```

## 5. Modular Architecture (MVVM Pattern)
The application uses the Model-View-ViewModel (MVVM) pattern to separate concerns and ensure testability.

*   **View Layer**: Flutter Widgets responsible for the UI. They observe ViewModels for state changes.
*   **ViewModel Layer**: Holds the business logic and UI state. It interacts with Repositories to fetch/save data.
*   **Model Layer**: Data entities and business logic models.
*   **Data/Repository Layer**: Handles data source abstraction (Firebase vs. Local Cache).

## 6. Security & Data Integrity
*   **Firebase Security Rules**: Granular access control for Firestore and Storage.
    *   *Citizen*: Can write to their own submissions; can read only verified reports on the public map.
    *   *Authority*: Can read all submissions and write to verification sub-collections.
*   **Authentication**: Multi-factor authentication support via Firebase Auth.
*   **Data Validation**: Strict schema validation via Cloud Functions before final persistence.

## 7. AI Service Integration
*   **Workflow**: Images uploaded to Cloud Storage trigger a Firebase Cloud Function.
*   **Processing**: The function interacts with an AI analysis engine (e.g., Gemini or a custom model) to estimate water parameters.
*   **Persistence**: Results are written directly back to the specific Submission document in Firestore for user review.

## 8. Offline-First Strategy
*   **Local Caching**: Submissions are initially saved to a local SQLite/Hive database.
*   **Synchronization**: A background worker (WorkManager/Cron) monitors connectivity and pushes pending reports to Firebase when online.
*   **Consistency**: Conflict resolution logic ensures that local edits do not overwrite server-verified data.
