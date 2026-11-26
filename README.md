# Dokkaebi ASCII — Godot 4.4 মোবাইল গেম

Instagram reel-এর (@ztryfu-র Dokkaebi) মতো ASCII 3D গেমের একটা simple, কাজ করা version।
অন্ধকার মাঠ, লম্বা সবুজ ঘাস, ছোট dokkaebi ক্যারেক্টার (কোরিয়ান টুপি), কমলা জোনাকি —
পুরো দৃশ্য ASCII character দিয়ে render হয়, এটা আসল shader, কোনো static ছবি না।

Mobile Legends-এর মতো control: বামে virtual joystick (গাঢ় গোল base + সবুজ knob),
ডানে বড় গোল ATTACK (কমলা) / DASH (নীল) / BURST (বেগুনি) button — cooldown-এ button
অন্ধকার হয়ে সেকেন্ড দেখায়। উপরে গাঢ় top bar-এ Score, Wave, HP bar।
Camera উপর থেকে ৫৫ ডিগ্রি angle-এ, ক্যারেক্টার পুরো দেখা যায়, camera player-কে follow করে।

## গেমপ্লে

- মাঠে ঘুরে বেড়াও, dark spirit শত্রুরা edge থেকে এসে তোমার দিকে হাঁটবে
- **ATTACK:** কাছের শত্রুকে মারো (range ৩.৬, damage ৩৫)
- **DASH:** ছোট dash + কিছুক্ষণ speed বাড়ে (cooldown ৩ সেকেন্ড)
- **BURST:** চারপাশের সব শত্রুকে একসাথে damage (range ৬, damage ৬০, cooldown ৮ সেকেন্ড)
- কমলা firefly ধরলে **+১০ score, +৫ HP**
- শত্রু গায়ে লাগলে **−১০ HP**। HP ০ হলে Game Over, RESTART button-এ আবার খেলা যায়
- Score বাড়লে wave বাড়ে, শত্রু বেশি আর দ্রুত আসে

PC-তে keyboard: **WASD / Arrow** — চলা, **Space / J** — Attack, **Shift / K** — Dash,
**E / L** — Burst, **T** — ASCII on/off, **R** — Game Over-এর পর Restart।
Joystick আর button-গুলো mouse দিয়েও click করা যায়।

## তোমার PC-তে যা already আছে (আবার install করতে হবে না)

- **JDK 17** — `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot`
- **Android SDK** — `D:\Android\Sdk` (android-34, build-tools 34.0.0, adb)
- **Gradle 8.7** — `D:\gradle-8.7`
- Android Studio **লাগবে না**।

## নতুন যা install করতে হবে (মাত্র ~২.৫-৩ GB)

1. **Godot 4.4** — https://godotengine.org/download/ থেকে **Godot Engine - Windows 64-bit**
   (Standard version, .NET / mono version **না**)। Download প্রায় ৮৩ MB, install লাগে না,
   zip খুলে `Godot_v4.4-stable_win64.exe` চালালেই হয়। D: drive-এ রাখো, C: ফাঁকা থাকুক।
2. **Export Templates** — Godot-এ শুধু Android export-এর সময় একবার লাগবে (নিচে দেখো)।
   Download প্রায় ১.১ GB।

মোট ফাঁকা জায়গা: কমপক্ষে **৫ GB** ফাঁকা রাখো, ভালো হয় ১০ GB।

## PC-তে খেলা / টেস্ট করা

1. Godot খুলে **Import** করো, এই folder-টা (`dokkaebi-ascii-game`) select করো।
2. প্রথমবার Godot project-টা import করবে (`.godot` folder তৈরি হবে — এটা Git-এ যাবে না)।
3. উপরে **Play (F5)** চাপো। 1280x720 landscape window-এ গেম চলবে।
4. WASD দিয়ে চলো, Space দিয়ে attack করো। Joystick-এ mouse দিয়ে drag করলেও চলবে।
5. **T** চাপলে ASCII effect বন্ধ/চালু হয় — এটা debug-এর জন্য।

কোনো error দেখালে: Godot-এর নিচের **Output** panel-এর লাল লাইনটা পুরো copy করে
তোমার AI Agent-কে দাও, ও ঠিক করে দেবে।

## Android APK বানানো (ফোনে খেলার জন্য)

একবারের setup:

1. Godot-তে **Editor > Manage Export Templates > Download and Install** চাপো
   (প্রায় ১.১ GB download হবে, একবারই লাগবে)।
2. **Editor > Editor Settings > Export > Android**-এ যাও:
   - **Android Sdk Path:** `D:\Android\Sdk`
   - **Debug Keystore:** Godot নিজে একটা debug keystore বানিয়ে নেবে, কিছু করতে হবে না।
3. **Project > Export** খুলে **Android** preset select করো।
   - Package: `com.mim.dokkaebi`, Version: `1.0.0`, Min SDK 24, Target SDK 34
   - Orientation: Landscape
4. **Export Project** চাপো, জায়গা দাও: `exports\android\dokkaebi-ascii.apk`
   (প্রথম export-এ কিছু সময় লাগবে, Gradle download হতে পারে।)
5. ফোনে install করা:
   - ফোনে **Settings > About phone > Build number**-এ ৭ বার tap করো
     (Developer options চালু হবে), তারপর **Developer options > USB Debugging** on করো।
   - USB cable দিয়ে ফোন PC-তে লাগাও, ফোনে **Allow USB debugging**-এ OK দাও।
   - APK ফাইলটা ফোনে copy করে tap করে install করো, অথবা PC-তে PowerShell-এ:
     `adb install exports\android\dokkaebi-ascii.apk`
   - অথবা Godot-তে **Project > Export > Android > One-Click Deploy**-ও ব্যবহার করা যায়।

> Play Store-এ publish করার জন্য আলাদা release keystore + Play Console লাগবে।
> এটা শুধু নিজের ফোনে টেস্ট করার APK।

## GitHub-এ আপলোড করা

এই folder-এর ভেতরে PowerShell / Git Bash-এ:

```bash
git init
git add .
git commit -m "Dokkaebi ASCII - first working Godot game"
git branch -M main
git remote add origin https://github.com/PresidentMim/dokkaebi-ascii-game.git
git push -u origin main
```

(নিজের repo নাম আলাদা হলে `PresidentMim/dokkaebi-ascii-game.git`-এর জায়গায় সেটা দাও।)
`.gitignore`-এ `.godot/`, `*.apk`, `*.aab`, `exports/` দেওয়া আছে — তাই
build করা APK আর Godot-এর cache GitHub-এ যাবে না, শুধু source যাবে।

## ফাইল structure

```
project.godot            Godot 4.4, landscape 1280x720, input map, GL Compatibility
main.tscn                3D world + SubViewport + ASCII overlay + HUD
scripts/
  game.gd                Score / health / wave / spawn / firefly / camera follow
  player.gd              Dokkaebi character, movement, dash, staff swing
  enemy.gd               Dark spirit, player-এর দিকে হাঁটা, touch damage
  joystick.gd            Virtual joystick (touch + mouse)
  hud.gd                 Score / HP bar / button / Game Over screen
shaders/
  ascii.gdshader         আসল ASCII shader (cell -> brightness -> character)
assets/
  ascii_atlas.png        ASCII atlas, 240x24, 10টি character: " .:+*o%#M@" (মাপা monotonic ramp)
tools/
  make_atlas.py          Atlas বানানোর script — ramp monotonic কিনা check করে
export_presets.cfg       Android (com.mim.dokkaebi, SDK 24/34) + Windows Desktop
icon.svg                 Game icon
.gitignore               .godot/, *.apk, *.aab, exports/
```

## ASCII effect যেভাবে কাজ করে

1. 3D world-টা একটা **SubViewport**-এ render হয় (1280x720)।
2. সেই texture-টা একটা full-screen **TextureRect**-এ দেখানো হয়, যার উপরে
   `ascii.gdshader` বসানো।
3. Shader প্রত্যেক ১২x১২ pixel cell-এর brightness মেপে atlas থেকে একটা
   character বেছে নেয় — অন্ধকারে ` ` / `.`, উজ্জ্বল জায়গায় `#` / `@` —
   আর আসল রং (সবুজ ঘাস, কমলা আলো) দিয়ে tint করে। অন্ধকার scene-এও
   character দেখা যায় বলে shader brightness-কে boost করে
   (`pow(lum, 0.65) * 1.4`), আর glyph-এর background প্রায় কালো রাখে।
4. `cell_size_px` বদলালে ASCII-র ঘনত্ব বদলায় (১২ = বর্তমান, ৮ = ঘন, ১৬ = হালকা)।

> v2 fix: প্রথম version-এ cell ছিল ৮px, atlas-এর glyph পাতলা ছিল, আর
> scene এত অন্ধকার ছিল যে বেশিরভাগ cell-ই ` ` / `.`-এ ম্যাপ হতো — তাই
> ASCII প্রায় দেখাই যেত না। আরও বড় সমস্যা: পুরনো ramp `" .:-=+*#%@"`
> আসলে monotonic ছিল না (মাপা: `-` < `:`, `%` < `#`), তাই উজ্জ্বল cell-ও
> হালকা glyph পেত। v2-তে cell ১২px, atlas ২৪px/cell-এ bold glyph,
> brightness boost, scene-এর আলো বাড়ানো, আর মাপা monotonic ramp
> `" .:+*o%#M@"` ব্যবহার করা হয়েছে।

## Note on ascii_atlas.png
`assets/ascii_atlas.png` is the ASCII character atlas (240x24 px). If it is missing after a Git clone, regenerate it before opening Godot: `python tools/make_atlas.py` (needs Pillow: `pip install pillow`). The script asserts the ramp is strictly increasing.
