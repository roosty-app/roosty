# Android Obsidian Vault Discovery Research

## Sources

- Obsidian Help, "Obsidian for Android", read on 2026-06-15:
  https://obsidian.md/help/android
- Android Developers, "Storage updates in Android 11", read on 2026-06-15:
  https://developer.android.com/about/versions/11/privacy/storage

## Findings

Obsidian for Android lets users choose either device storage or app storage for
vault data. The official help page states that device storage is shared and can
be accessed by other apps, while app storage is private to Obsidian.

Android 11 scoped storage blocks apps from reading another app's private data
directory and app-specific external storage directory. Android's Storage Access
Framework also prevents requesting `Android/data/` and its subdirectories as a
document tree target on Android 11+.

## Conclusion

Roosty should not attempt to auto-read Obsidian's Android registry/config files.
There is no stable public Obsidian Android vault registry API that Roosty can
read without broad storage privileges, and app-storage vaults are intentionally
private.

Decision for this task: Android discovery returns an empty candidate list and
keeps the existing SAF manual directory authorization flow. After the user picks
a SAF directory, Roosty should create the `Roosty/` child directory through the
SAF channel so the user gets the same connection confirmation without bypassing
Android storage rules.
