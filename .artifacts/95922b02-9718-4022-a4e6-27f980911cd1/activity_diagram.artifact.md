# AquaWatch: Activity Diagram

This diagram illustrates the operational flow of the AquaWatch system, specifically focusing on the lifecycle of a water quality report.

## Core Process: Water Quality Reporting & Verification

The activity diagram below shows the interaction between the Citizen (User), the Automated AI System, and the Authority (Admin).

```mermaid
activityDiagram
    state "Start Application" as Start
    state "User Logs In" as Login
    state "Select 'Report Water Quality'" as SelectReport
    state "Capture Photo & Location" as Capture
    state "Is Device Online?" as CheckOnline <<choice>>
    state "Save to Local DB (Queue)" as LocalSave
    state "Upload to Cloud Storage" as CloudUpload
    state "AI: Analyze Image & Estimate Parameters" as AIProcess
    state "Review & Submit Metadata" as UserSubmit
    state "Status: Pending Verification" as Pending
    state "Authority Reviews Report" as AuthorityReview
    state "Valid Data?" as CheckValid <<choice>>
    state "Approve & Mark Verified" as Approve
    state "Reject & Provide Feedback" as Reject
    state "Notify Citizen" as Notify
    state "Update Public Hotspot Map" as UpdateMap
    state "End" as End

    [*] --> Start
    Start --> Login
    Login --> SelectReport
    SelectReport --> Capture
    Capture --> CheckOnline

    CheckOnline --> LocalSave : No
    LocalSave --> CheckOnline : Wait for connection
    CheckOnline --> CloudUpload : Yes

    CloudUpload --> AIProcess
    AIProcess --> UserSubmit
    UserSubmit --> Pending

    Pending --> AuthorityReview
    AuthorityReview --> CheckValid

    CheckValid --> Approve : Yes
    CheckValid --> Reject : No

    Approve --> UpdateMap
    Reject --> Notify
    UpdateMap --> Notify

    Notify --> End
    End --> [*]
```

## Key Activity Nodes Explained:
*   **Capture Photo & Location**: The system automatically pulls GPS data while the user takes a photo of the water source.
*   **Offline Queue**: If no internet is detected, the report is cached locally to prevent data loss.
*   **AI Analysis**: The system performs initial processing (pH/TDS estimation) before the user even hits submit, providing immediate (though unverified) feedback.
*   **Authority Review**: A human-in-the-loop step ensures the crowdsourced data is accurate before it becomes public on the hotspot map.
*   **Map Update**: Only verified reports contribute to the global water quality visualization.
