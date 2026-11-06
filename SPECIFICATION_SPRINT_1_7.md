# Sprint 1.7 – iPhone navigation and layout correction

Based directly on Sprint 1.6. No changes to SwiftData model schemas, audio recording engine, audio storage or playback logic.

- Test Drives screen uses an explicit dark ScrollView/VStack layout, avoiding large-title/List positioning issues on physical iPhones.
- Tapping anywhere on a test-drive card selects the drive **before** pushing its details through a stable NavigationStack path.
- The Test Drives tab owns its NavigationStack rather than wrapping it in a second NavigationStack.
- Initial tab is Test Drives; explicit navigation to Recorder remains available.
- Test Drive Details retain Trace Session ID, Defect list and New Defect.
- Defect Details retain metadata, recording list, playback and Add Recording.
- Multiple drives remain editable, with no automatic completion.
- English labels on Defects overview; app dark mode enforced.
- Version/build metadata updated to 1.7 / 17; existing Bundle Identifier preserved to support in-place upgrade and retain local data.

## Verification on Mac
1. Open AutomotiveVoiceDefectReporter.xcodeproj in Xcode.
2. Select physical iPhone, ensure Personal Team signing is selected, Build (Cmd+B).
3. Run (Cmd+R), open an existing drive by tapping card or chevron.
4. Check Test Drive Details > New Defect, then Recorder > Start/Stop, then Defect Details > playback.
5. Verify existing local drives and recordings are present before deleting any app.

This package was checked for archive integrity and source-level consistency. Xcode is not available in this environment, so an actual iOS build and device run could not be verified.
