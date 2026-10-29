# School Bell (Apple Watch)

Shows your current period, time left, what's next, and the time.
Buzzes your wrist at 20, 10, and 5 minutes left in each class (not recess or lunch).
Alerts are scheduled on the watch itself, so they work with your phone at home.

To change times or class names, edit `Watch/Schedule.swift`.

## 1. Put it on GitHub

1. On github.com, click **New repository**. Name it `SchoolBell`, set it to **Public**, and click **Create repository**.
2. Click **uploading an existing file**. Drag in everything from this folder **except** the `.github` folder: `project.yml`, `README.md`, and the `Phone`, `Watch`, and `Support` folders. Click **Commit changes**.
3. Click **Add file → Create new file**. For the name, type exactly:
   `.github/workflows/build.yml`
   Open `.github/workflows/build.yml` from this folder in Notepad, copy all of it, paste it in, and click **Commit changes**.

## 2. Get the .ipa

1. Open the **Actions** tab in your repo. A "Build IPA" run starts on its own (takes a few minutes).
2. When it shows a green check, click the run, scroll to **Artifacts**, and download **SchoolBell-ipa**.
3. Unzip it to get `SchoolBell.ipa`.

If it shows a red X instead, click the failed step and send the error text to Claude.

## 3. Install it

1. Plug your iPhone into your PC, open **Sideloadly**, drag in `SchoolBell.ipa`, enter your Apple ID, and click **Start**.
2. On the iPhone: **Settings → General → VPN & Device Management** → tap your Apple ID → **Trust**.
3. If asked, turn on **Developer Mode** (Settings → Privacy & Security → Developer Mode) and restart.
4. Open the **Watch** app on the iPhone, scroll to **Available Apps**, and tap **Install** next to School Bell.
5. Open School Bell on the watch and tap **Allow** for notifications. Without this, no alerts.

The watch may also ask for Developer Mode (watch Settings → Privacy & Security → Developer Mode).

## Good to know

- Apple limits apps to 64 scheduled alerts, so the watch schedules about 3 school days ahead. The bottom of the app shows how far ahead alerts are set, and opening the app tops them up.
- **No school today** switch: turn it on for holidays or days off to silence that day's alerts.
- Free Apple ID signing expires after 7 days. Re-install with Sideloadly (or use its auto-refresh) before then.
