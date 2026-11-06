# Automotive Voice Defect Reporter — Sprint 1.5

## Confirmed decisions

- Native Swift / SwiftUI iPhone app; English UI, dark mode supported.
- A test drive is a persistent container for defect reports. Creating a new test drive **never** automatically completes or closes an existing one.
- No **Testdrive Complete** action, and no Completed / Active lifecycle distinction in the UI. Any drive may be selected and revisited to add reports or recordings.
- Exactly one test drive is **Selected** at a time for new defects/recordings. Selection is not a completion state. Switching drives is disabled during an ongoing or paused recording.
- Selecting a different drive must not change existing defect/recording associations.
- New defect report is separate from recording. A defect may have any number of recordings. A user can return to any defect to add more recordings.
- Manually set the active Trace Session ID; a new defect snapshots it at creation. Each recording snapshots the Trace ID at the moment recording begins, so later Trace changes do not rewrite history.
- Store defect creation date (yyyy-MM-dd), English weekday, and time (HH:mm:ss); every recording has its own timestamp and Trace ID.
- Existing Sprint 1.2 SwiftData records should remain accessible. The old `endedAt` property is retained for schema compatibility but ignored in Sprint 1.5.
- Reports can eventually be generated at any time without closing a drive; PDF and Excel export are NOT part of Sprint 1.5.

## Implemented in Sprint 1.5

- English-language drive list with total count, selected drive, and defect count.
- Create multiple test drives and select any existing drive.
- Store selection across app launches via AppStorage.
- New defect and Start/Stop Recording are separate actions.
- Locally store AAC/M4A audio and display associated recordings.
- Show and manually edit current Trace ID; capture per-defect and per-recording Trace ID and timestamps.
- Corrected recording-completion Trace-ID callback to use the saved value rather than clearing it before persistence.
- English UI labels in the principal screens.

## Deferred

- Spoken Trace-ID commands; local transcription and AI-generated defect report updates after each recording.
- PDF, Excel, ZIP, images, sharing, Face ID, complete confidentiality controls, robust recording recovery and automated tests.
- A future optional Trash/restore policy may be specified separately; no automatic drive deletion is performed.

## Test checklist

1. Create drive A and one defect, record clip A1 with Trace 01.
2. Create drive B. Verify A still appears and can be selected.
3. Select drive A; add a second recording to the original defect with Trace 02.
4. Verify both recordings retain their own Trace IDs, timestamps and drive/defect association.
5. Restart app; verify drives, selection and recordings remain visible.
6. Verify no Complete button or Completed badge is displayed, including for previously completed Sprint 1.2 drives.
7. Verify drive switching is disabled while a recording is running or paused.
8. Test on physical iPhone; simulator audio is not a substitute for device testing.
