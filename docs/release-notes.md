First packaged release.

A macOS app and widget showing how full your drives are, with a low-space
alert.

**Installing.** Open the `.dmg` and drag Disk Usage to Applications. The build
is ad-hoc signed rather than notarized, so macOS will refuse it on first
launch: open **System Settings → Privacy & Security** and press **Open
Anyway**, or run `xattr -d com.apple.quarantine "/Applications/Disk Usage.app"`.
The warning is accurate — nobody has vouched for this binary. Building from
source takes a couple of minutes and signs it locally with your own Apple ID.

**What's in it**

- Every mounted volume, internal and external, as a ring gauge
- Small, medium and large widgets; medium and large pick their volume
- A notification when free space crosses your threshold, once per crossing
- No background process: the widget reads the volumes itself

**Note.** Released builds are signed without the App Group entitlement, which
is restricted and cannot travel in an ad-hoc signature. Low-space settings are
stored in the app's own defaults instead, so they do not carry across between a
downloaded copy and one you built yourself.
