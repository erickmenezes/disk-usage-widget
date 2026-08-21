# Disk Usage Widget

A native macOS **WidgetKit** desktop widget showing used and free space per volume,
plus a host app that warns you when the boot volume runs low.

Built for macOS 14+, developed on macOS 26 with Xcode 26.

---

## What it does

| Family | Shows |
|---|---|
| `systemSmall` | One ring for the volume chosen in the widget's configuration |
| `systemMedium` | A row of rings, one per mounted volume, in the style of the system Batteries widget |
| `systemLarge` | The same volumes as rows, with used / free / total byte counts |

Rings are colour-coded by usage: green below 75%, yellow below 90%, red above.
Capacity is read from `URLResourceValues`, refreshed on a 30-minute timeline.

The host app lists every mounted volume and carries the low-space alert settings:
an on/off toggle, a free-space threshold, and a test button.

---

## Requirements

- macOS 14 or later
- Xcode 26
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- An Apple ID added to Xcode. The App Group entitlement needs real team signing;
  ad-hoc cannot carry it.

---

## Building

```sh
xcodegen generate                    # only needed after editing project.yml
open DiskUsageWidget.xcodeproj       # then ⌘R
```

`project.yml` is the source of truth. **`DiskUsageWidget.xcodeproj` is generated and
gitignored** — anything you set through Xcode's GUI (signing team, capabilities,
build settings) is lost the next time the project is regenerated. Change it in
`project.yml` instead.

Set `DEVELOPMENT_TEAM` in `project.yml` to your own team ID before building.

### Where the widget actually runs

Widgets do not load from DerivedData. `Scripts/install-widget.sh` runs as a **scheme
post-action** to copy the built app to `/Applications` and `lsregister` it. The host
app calls `WidgetCenter.shared.reloadAllTimelines()` on launch, so a rebuild shows up
on the desktop without any manual step.

To place the widget: right-click the desktop → Edit Widgets → Disk Usage.

---

## Layout

```
project.yml                       # XcodeGen spec — edit this, not the .xcodeproj
Scripts/
  install-widget.sh               # post-build: copy to /Applications + lsregister
  make-icon.swift                 # renders the 1024pt app icon master
Shared/
  AppGroup.swift                  # shared UserDefaults suite, compiled into both targets
App/
  DiskUsageApp.swift              # host app UI
  LowSpaceMonitor.swift           # threshold watcher + notifications
DiskUsageWidgetExtension/
  WidgetBundle.swift
  DiskUsage/
    DiskInfo.swift                # model            (also in the host app target)
    DiskReader.swift              # capacity reads   (also in the host app target)
    SelectVolumeIntent.swift      # widget configuration
    DiskProvider.swift            # AppIntentTimelineProvider
    DiskWidgetView.swift          # all three families
    DiskUsageWidget.swift         # widget definition
```

---

## Low-space alerts

`LowSpaceMonitor` checks the boot volume on launch and every 5 minutes, posting a
notification when free space crosses **below** the configured threshold (default 10%).
It is edge-triggered with a 2-point hysteresis, so a volume hovering on the boundary
cannot fire repeatedly.

**It only runs while the host app is open.** Background monitoring would need a
LaunchAgent or login item, which is deliberately not implemented.

Settings live in the App Group suite `group.com.erickmenezes.DiskUsage`, so they are
readable from the widget extension too.

---

## Gotchas

Every one of these fails *silently* — no build error, no runtime message.

- **`GENERATE_INFOPLIST_FILE` must stay `NO` on the extension target.** With `YES`,
  Xcode synthesizes its own `Info.plist` and drops the `NSExtension` key, and the
  widget simply never appears in the gallery. Check with
  `plutil -p <built>.appex/Contents/Info.plist | grep NSExtension`.

- **Install from a scheme post-action, never a target build phase.** Target phases run
  *before* Xcode code-signs, so installing from one copies an unsigned app and launchd
  refuses it with `RBSRequestErrorDomain Code=5 … POSIX 163`. Verify with
  `codesign -v --strict "/Applications/Disk Usage.app"`.

- **Do not use `AppEntity` + `EntityQuery` for the volume picker.** AppIntents could
  not rehydrate the persisted entity — every timeline logged `Failed to build
  EntityIdentifier … is not a registered AppEntity identifier`, handed the provider
  `nil`, and fell through to `defaultResult()`, pinning the widget to the boot volume
  regardless of what was picked. A `DynamicOptionsProvider` over a plain `String`
  avoids EntityIdentifier serialization entirely.

- **A notification posted while your own app is frontmost gets no banner and no
  sound** unless you implement `UNUserNotificationCenterDelegate` and return
  `[.banner, .sound, .list]` from `willPresent`. It still lands in Notification
  Center, so it looks like a Focus or System Settings problem when it is not.

- **Notification authorization is remembered after a single dismissal.** If the
  permission alert is dismissed, `requestAuthorization` fails forever after and never
  re-prompts. Only System Settings → Notifications can undo it.

- **A transparent focused background is not achievable.** The widget container
  composites over an opaque backdrop, so materials resolve to a light panel and
  explicit alpha renders opaque. Verified against `Color.clear` and
  `Color.white.opacity(0.25)`. The translucency Apple's own widgets keep while the
  desktop is focused is not available to third-party widgets.

- **Renaming a configuration parameter orphans placed widgets.** They keep the config
  they were created with; editing in place is not enough, they must be removed and
  re-added.

### Debugging

The provider and the monitor log to the `com.erickmenezes.DiskUsage` subsystem:

```sh
log show --last 5m --predicate 'subsystem == "com.erickmenezes.DiskUsage"' --style compact
```

`resolve()` falling back to the boot volume is silent by design, so the log is the
only way to tell "suppressed correctly" from "never ran".

---

## Verifying the numbers

Compare against `df -H /System/Volumes/Data` or `diskutil info /dev/disk3s1s1` —
**not** `df -H /`, which reports the sealed read-only system snapshot and is not your
disk usage. `diskutil` container free space matches the widget exactly; `df` on the
Data volume differs by a few points in *used* because it excludes other volumes and
snapshots in the APFS container.
