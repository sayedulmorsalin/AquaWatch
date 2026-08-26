# AquaWatch: Use Case Analysis

This document describes the primary interactions between stakeholders (Actors) and the AquaWatch system.

## 1. Actors
*   **Citizen**: Primary contributor who reports water quality.
*   **Authority**: Government official or NGO lead who verifies data.
*   **Researcher/Analyst**: Specialist who uses the data for scientific study.
*   **System (AI Engine)**: Automated component that processes images.

## 2. Use Case Diagram

```mermaid
useCaseDiagram
    actor Citizen
    actor Authority
    actor Researcher
    actor "System (AI)" as AI

    package AquaWatch {
        usecase "Report Water Quality" as UC1
        usecase "View Water Quality Map" as UC2
        usecase "Manage User Profile" as UC3
        usecase "Analyze Image (AI)" as UC4
        usecase "Verify Submission" as UC5
        usecase "Manage Hotspots" as UC6
        usecase "Export Data Analytics" as UC7
        usecase "Receive Emergency Alerts" as UC8
    }

    Citizen --> UC1
    Citizen --> UC2
    Citizen --> UC3
    Citizen --> UC8

    AI --> UC4
    UC4 ..> UC1 : <<include>>

    Authority --> UC5
    Authority --> UC6
    Authority --> UC2
    Authority --> UC8

    Researcher --> UC7
    Researcher --> UC2
```

## 3. Detailed Use Case Descriptions

### UC1: Report Water Quality
*   **Actor**: Citizen
*   **Goal**: Submit local water quality data for monitoring.
*   **Pre-condition**: User is logged in and GPS is enabled.
*   **Main Flow**:
    1.  User opens "Report" screen.
    2.  User takes/uploads a photo of the water source.
    3.  System (AI) processes the photo for parameter estimation.
    4.  System automatically attaches GPS coordinates and timestamp.
    5.  User adds optional notes and submits the report.
*   **Post-condition**: Report is saved as "Pending" in the database.

### UC5: Verify Submission
*   **Actor**: Authority
*   **Goal**: Ensure the accuracy of community-submitted data.
*   **Main Flow**:
    1.  Authority logs into the Dashboard.
    2.  Authority selects a pending report from the queue.
    3.  Authority reviews the photo, AI estimates, and location.
    4.  Authority approves or rejects the submission.
*   **Post-condition**: Report status is updated; Public map is refreshed if approved.

### UC7: Export Data Analytics
*   **Actor**: Researcher
*   **Goal**: Obtain structured data for external scientific analysis.
*   **Main Flow**:
    1.  Researcher filters data by date, location, or parameter range.
    2.  Researcher selects export format (CSV/JSON/PDF).
    3.  System generates and provides the download link.
