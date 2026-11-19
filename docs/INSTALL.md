# Installing and demoing Thalam

Back to the [main README](../README.md).

## Install on your iPhone + Apple Watch

Apple only allows your own Watch apps through Xcode on a Mac or through TestFlight.
Pick one route.

### Route A: borrow a Mac for ~45 minutes (free Apple ID). Recommended.

**Before you sit down (the 45 minutes only holds if these are done):**

* **Versions match.** Check iPhone **Settings → General → About → iOS Version** and the Watch's
  watchOS version. The Mac's Xcode must be the **same major version or newer** (iOS 26 → Xcode 26;
  iOS 27 → Xcode 27), or Xcode can't install to the phone. Newer Xcode needs a recent macOS, so check
  the Mac can run it.
* **Download ahead.** Have the Mac's owner install/update Xcode **the night before** and open it
  once. It is ~10 GB, and the first launch also downloads iOS and watchOS support (several GB more).
* **Bring:** iPhone cable (USB-C or Lightning to the Mac's port), charged iPhone + Watch, your
  Apple ID password and a second device for its 2-factor code.
* **Update nothing on the day.** Don't let the iPhone or Watch install an iOS/watchOS update
  between now and the demo.
* **Free-team limits:** up to 3 of your apps per device and 10 new bundle IDs per week. Thalam uses
  2 IDs (phone + Watch), so avoid changing `THALAM_BUNDLE_ID` more than needed.
* After installing you can **give the Mac back**. The demo needs no Mac and works for 7 days, so
  installing the evening before is fine.

1. On the Mac: install **Xcode** from the App Store and open it once.
2. Get the code: on github.com/neetii-git/thalam-app click **Code → Download ZIP**, unzip it,
   then in Terminal: `cd ~/Downloads/thalam-app-main && chmod +x build.sh && ./build.sh --open`
3. **Xcode → Settings → Accounts → +** → sign in with your Apple ID.
4. In Xcode, click the blue **Thalam** project icon (top of the left sidebar). Then for **each**
   target, **Thalam** and **Thalam Watch App**: **Signing & Capabilities** tab → tick
   *Automatically manage signing* → **Team: "Your Name (Personal Team)"**.
   *If it says the bundle ID is taken:* change `THALAM_BUNDLE_ID` at the top of `project.yml`
   (e.g. `com.eshan2006.thalam`), run `./build.sh --open` again and repeat this step. (Re-running `build.sh` regenerates the project, so pick the team again.)
5. **iPhone:** plug it in with a cable, unlock it, tap **Trust**. Then on the iPhone go to
   **Settings → Privacy & Security → Developer Mode → On**. It restarts; confirm **Turn On**.
6. In Xcode's toolbar choose scheme **Thalam** and your iPhone, then press **▶ Run**.
   If the iPhone says "Untrusted Developer": **Settings → General → VPN & Device Management
   → Apple Development: you → Trust**, then Run again.
7. **Watch:** keep it on your wrist, unlocked, near the iPhone (same Wi-Fi as the Mac).
   On the Watch: **Settings → Privacy & Security → Developer Mode → On** (it restarts).
   The switch only appears after Xcode has seen the Watch. Opening
   **Window → Devices and Simulators** in Xcode helps.
8. In Xcode choose scheme **Thalam Watch App** and your Apple Watch, press **▶ Run**.
   The first run can take several minutes while Xcode prepares the Watch.
9. Open Thalam on the Watch and tap **Allow** for the Health (workout) permission. Allow it on
   the iPhone too.

Free-team apps keep working for **7 days**. That's fine for the demo.

### Route B: no Mac, paid Apple Developer account ($99/year) + TestFlight

TestFlight installs need no Developer Mode and no Mac. The GitHub workflow builds,
signs in the cloud and uploads.

1. Enrol at developer.apple.com/programs (approval can take up to 48 h).
2. **App Store Connect → Apps → +** → New App, bundle ID `com.eshan.thalam`.
   If the bundle ID is not in the list, register it under
   developer.apple.com → Identifiers, with the HealthKit capability.
3. **App Store Connect → Users and Access → Integrations → App Store Connect API** →
   create a key with **Admin** access. Download the `.p8` file and note the Key ID and Issuer ID.
4. In the GitHub repo: **Settings → Secrets and variables → Actions** → add
   `ASC_KEY_ID`, `ASC_ISSUER_ID`, `TEAM_ID` (Membership page) and `ASC_KEY_P8_BASE64`
   (in PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXX.p8"))`).
5. **Actions → Build → Run workflow** → tick *testflight* → Run.
6. After about 15 minutes of processing, in App Store Connect **TestFlight**, add yourself as an
   internal tester. Install **TestFlight** on the iPhone, install Thalam, then in the iPhone's
   **Watch** app → Thalam → **Show App on Apple Watch**.

### Route C: no Mac, free, iPhone only (no Watch)

Download `Thalam-iphone-only-unsigned.ipa` from the latest Actions run (**Artifacts**),
install it with **Sideloadly** on Windows using your Apple ID, then enable Developer Mode on
the iPhone. Turn on **Also tap on this iPhone** and wear the phone in an armband.
Free sideloading cannot install Watch apps.

## 60-second demo script

1. **(0–10 s) The problem.** "Meera is deaf. In class she can't hear the mridangam, so she
   follows her guru's hands and keeps slipping off the tala."
2. **(10–20 s) Set the tala.** On the iPhone, tap **Adi Talam**. "Big dot is sam, the
   medium dots are claps." Leave **80 BPM**. Point at the status row: **Watch connected**.
3. **(20–35 s) Feel it.** Press **Start feeling the beat**. About 1.5 s later the Watch gives two "get ready"
   taps (**2**, **1** on screen), then sam.
   Hand the Watch to a judge: "Strong tap on sam, medium on the claps (beats 5 and 7), light on
   the counts." The iPhone ring lights up in step.
4. **(35–45 s) Wrist down.** Lower the wrist so the screen goes dark. It keeps tapping.
   "A workout session keeps it running, so she can dance with her arms moving."
5. **(45–55 s) Why it's in sync.** "The phone sends one message, a start time, and both
   devices count beats from it. We schedule, we don't stream, so Bluetooth delay can never
   make a tap late."
6. **(55–60 s) Stop on the Watch.** The phone stops too. "Thalam. Feel the rhythm you can't hear."

**Before the demo:** charge both devices, open Thalam on the Watch first (shows *Start from
your iPhone*), turn on **Do Not Disturb** on the Watch so notifications don't buzz over the
tala, and do one full run-through. If the phone link misbehaves, use **Adi · 80 BPM** on the Watch.

## Troubleshooting

* **"Open Thalam on your watch"** stays on: open the app on the Watch; keep Bluetooth on.
  Start still works: the Watch joins in step when it opens.
* **Stops tapping when the wrist goes down:** the Health permission was denied. On the
  iPhone: **Settings → Health → Data Access & Devices → Thalam → Turn On All**,
  or reinstall.
* **Taps go missing:** disconnect Bluetooth headphones from the Watch (haptics can be routed away).
* **Very fast tempos (140+):** the long sam/clap haptics can crowd the next tap; demo at 80.
* **Taps feel weak:** Watch **Settings → Sounds & Haptics → Haptic Alerts → Prominent**.
