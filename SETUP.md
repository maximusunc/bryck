# Brick — MVP1 setup

A MagicBand-toggled app shield. Four files, one Xcode project, a free developer account.

**Requirements:** Xcode 15+, a physical iPhone on iOS 16+, an Apple ID. FamilyControls
does essentially nothing in the Simulator, so don't bother testing there.

---

## 1. Create the project

Xcode → **File → New → Project → iOS → App**

- Product Name: `Brick`
- Interface: **SwiftUI**
- Language: **Swift**
- Storage: **None**

Xcode generates `BrickApp.swift` and `ContentView.swift`. Replace both with the versions
in `Sources/`, and drag in `ShieldController.swift` (check "Copy items if needed").

---

## 2. Signing with a free account

Select the **Brick** target → **Signing & Capabilities**.

- Check **Automatically manage signing**
- Team: click the dropdown → **Add an Account…** → sign in with your Apple ID →
  a team called *"Your Name (Personal Team)"* appears. Pick it.
- Bundle Identifier: change it to something globally unique, e.g.
  `com.yourname.brick`. Xcode will reject a duplicate.

---

## 3. Add the Family Controls capability

Still in **Signing & Capabilities** → **+ Capability** → search **Family Controls** →
double-click. That's the development entitlement, which is self-serve — you only need
Apple's approval for App Store distribution, which you don't want.

If Xcode adds it cleanly, you're done with this step. If it refuses, or you get a build
error like *"Provisioning profile doesn't include the com.apple.developer.family-controls
entitlement"*, see **Troubleshooting** below — this is the step most likely to bite on a
personal team.

`Sources/Brick.entitlements` is included in case you'd rather add the file manually
(drag it in, then set **Build Settings → Code Signing Entitlements** to `Brick/Brick.entitlements`).

---

## 4. Register the URL scheme

Target → **Info** tab → scroll to **URL Types** → **+**

- Identifier: `com.yourname.brick`
- URL Schemes: `brick`
- Role: Editor

This is what lets the Shortcuts automation reach the app.

---

## 5. Build to the phone

1. Plug in the iPhone, select it as the run destination, press **⌘R**.
2. First run fails with *"Untrusted Developer."* On the phone:
   **Settings → General → VPN & Device Management → [your Apple ID] → Trust**.
3. Run again.
4. The app asks for Screen Time access on launch. Approve it. (If you miss the prompt,
   the "Grant Screen Time access" button re-triggers it.)

The app deliberately has no Brick/Unbrick button — the band is the only switch, and the
app list locks itself while you're bricked. To test before the band is wired up, pick a
couple of apps, then make a throwaway shortcut with the **Brick › Toggle Brick** action
and the key from **Band setup**. Run it, and go try to open one of the blocked apps: you
should get Apple's shield screen. Run it again to confirm it lifts.

---

## 6. Wire up the MagicBand

Shortcuts → **Automation** → **+** → **NFC** → **Scan** → tap the band → name it "Brick".

Then for the action: **Brick › Toggle Brick**, and paste the key from the app's
**Band setup** screen into the action's **Key** field.

The key is generated once, on first launch, and lives only on the phone. Without it the
action does nothing, so a shortcut you throw together later won't toggle until you go and
look the key up.

Critically, turn **Run Immediately** ON and **Notify When Run** OFF. Otherwise every tap
makes you confirm a banner, which ruins the whole point.

Tap the band. Nothing should visibly happen — the intent runs in the background and the
app never comes to the foreground. Try opening a blocked app to confirm.

**Band setup hides itself once you're bricked**, so the key can't be read at the moment
you'd most want to cheat. The one exception is before the automation has ever fired
successfully — until then the screen stays available even while bricked, so updating the
app mid-brick can't strand you with a stale automation and no way to read the new key.

Note the ceiling: the key is still sitting in the automation, readable in Shortcuts. This
buys you friction against impulse, not a lock.

---

## Living with the 7-day limit

Free-account provisioning profiles expire after 7 days and the app stops launching.
A few consequences worth knowing before you rely on this:

- **You can't be bricked when it expires.** The shield lives in `ManagedSettingsStore`,
  which survives independently of your app. If the profile dies while the shield is up,
  the apps stay blocked and the toggle is unreachable.
- **The escape hatch is deleting the app.** That tears down the store and clears the
  shield immediately. Remember this before you go setting a Screen Time passcode that
  blocks app deletion — for MVP1, leave that off.
- **Re-signing is just ⌘R.** Plug in, rebuild, and the 7 days reset. Do it on a day you're
  unbricked to keep things simple.
- Free accounts cap you at 3 sideloaded apps at a time.

---

## Troubleshooting

**Family Controls capability won't add, or the build fails on the entitlement.**
Personal teams support a reduced set of capabilities, and Family Controls may be among
the ones Apple gates behind a paid membership. If you hit this wall, the $99/yr Developer
Program is the only way past it — there's no workaround. Everything else here works
unchanged once you switch the team.

**"Publishing changes from background threads" purple warnings.**
Add `@MainActor` to the `BrickApp` struct.

**Shield doesn't lift after Unbrick.** Force-quit and reopen the shielded app. iOS
sometimes keeps the shield view alive in a suspended app.

**Picker shows nothing.** Authorization didn't go through. Check
Settings → Screen Time → the app should be listed under apps with access.

**Tag toggles twice.** You made two automations for the same band. Delete one.
