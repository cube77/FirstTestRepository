# Automotive Voice Defect Reporter – Sprint 1.6

## UI and workflow (confirmed)
- English UI and dark appearance (follows iOS dark mode; use dark mode on device).
- Three tabs: Test Drives, Recorder, Defects.
- Test Drives list: tap a test drive to open its dedicated Test Drive Details screen.
- Test Drive Details: vehicle/software/driver/start time, editable active Trace Session ID, list of recorded defects, **New Defect** button.
- Tap a defect: opens dedicated Defect Details screen with editable title/description, defect timestamp (yyyy-MM-dd, English weekday, HH:mm:ss), defect Trace ID and a list of individual voice recordings, each with timestamp, Trace ID and playback.
- Add Recording navigates to Recorder and selects the same defect. New Defect creates a defect and opens Recorder.
- Original Recorder audio flow retained: start/stop, duration, waveform-style level meter, interruption/resume support, local M4A recording. A defect can have multiple recordings.
- Multiple test drives may remain editable. Creating a new drive never completes another. No Testdrive Complete button. Selecting a drive is not completion.
- Trace ID can be manually updated; voice-based Trace ID entry is planned for Sprint 2.
- PDF/XLSX and AI/transcription are not part of Sprint 1.6.

## Test checklist
1. Build with Cmd+B in Xcode.
2. Open Test Drives, create two drives; neither is completed.
3. Tap an older drive; its details show a New Defect button.
4. Create a defect; Recorder opens with that defect selected.
5. Record twice, returning to the defect via Test Drive Details or Defects tab.
6. Open Defect Details: both recordings should appear independently and play.
7. Change active Trace ID and add another recording: existing recording Trace IDs must not change.

## Notes
- No macOS/Xcode runtime available in this authoring environment; source and project structure checked, actual build requires Xcode.
- Sprint 1.6 is a prototype. Do not use confidential vehicle/test data before app security, backup exclusion and end-to-end validation are complete.
