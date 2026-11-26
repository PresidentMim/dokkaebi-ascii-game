# ASCII Hero — Godot 4.4 মোবাইল অ্যাকশন গেম

[ascii-magic.com](https://www.ascii-magic.com)-এর মতো ASCII art style-এ বানানো
অ্যাকশন গেম। একজন caped সুপারহিরো **সাদা ঘোড়ায় চড়ে** তলোয়ার হাতে
ASCII মাঠে ছুটে বেড়ায়, চারপাশ থেকে shadow imp শত্রুরা এসে আক্রমণ করে।
ঘোড়া gallop করে (পা নড়ে, শরীর দোলে), আর ঘোড়া যেখান দিয়ে যায় ঘাস
সেখানটা দুলে সরে যায় — Senje-র (@ansenjeo) "Hair Physics Test" ASCII
MMORPG ভিডিওটার মতো। পুরো দৃশ্য — মাঠ, ঘাস, ঘোড়া, হিরো, শত্রু —
ASCII character দিয়ে render হয়, এটা আসল shader, কোনো static ছবি না।

Mobile Legends-এর মতো control: বামে virtual joystick (গাঢ় গোল base +
সবুজ knob), ডানে বড় গোল কমলা ATTACK button — cooldown-এ button
অন্ধকার হয়ে যায়। উপরে গাঢ় top bar-এ Score, Enemies, HP bar।
Camera উপর থেকে ৫৫ ডিগ্রি angle-এ, ঘোড়া + হিরো পুরো দেখা যায়,
camera হিরোকে follow করে।

## গেমপ্লে

- ঘোড়ায় চড়ে মাঠে ছুটে বেড়াও (WASD-র চেয়ে দ্রুত gallop), shadow imp
  শত্রুরা edge থেকে এসে তোমার দিকে হাঁটবে
- **ATTACK:** ঘোড়ার পিঠ থেকে তলোয়ারের slash — কাছের শত্রু এক আঘাতে
  মরে (range ৪.০, damage ৩৫, শত্রুর HP ৩০), সাথে সোনালি slash ring effect
- শত্রু মারলে **+১ score**; শত্রু গায়ে লাগলে **−১০ HP**
- Score বাড়লে শত্রু বেশি আর দ্রুত আসে (সর্বোচ্চ ১২টা একসাথে)
- HP ০ হলে Game Over, RESTART button-এ আবার খেলা যায়

PC-তে keyboard: **WASD / Arrow** — চলা, **Space / J** — Attack,
**R** — Game Over-এর পর Restart। Joystick আর ATTACK button-এ mouse
দিয়েও click/drag করা যায়।

## তোমার PC-তে যা already আছে (আবার install করতে হবে না)

- **JDK 17** — `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot`
- **Android SDK** — `D:\Android\Sdk` (android-34, build-tools 34.0.0, adb)
- **Gradle 8.7** — `D:\gradle-8.7`
- Android Studio **লাগবে না**।

## নতুন যা install করতে হবে (মাত্র ~২.৫-৩ GB)

1. **Godot 4.7.2** — https://godotengine.org/download/ থেকে **Godot Engine
   - Windows 64-bit** (Standard version, .NET / mono version **না**,
   console exe-ও **না** — শুধু `Godot_v4.7.2-stable_win64.exe`)।
   Download প্রায় ৮৩ MB, install লাগে না, zip খুলে exe চালালেই হয়।
   4.7.2 দিয়ে এই 4.4 project খুললে upgrade prompt আসবে — Yes চাপো।
2. **Export Templates** — Godot-এ শুধু Android export-এর সময় একবার লাগবে
   (নিচে দেখো)। Download প্রায় ১.১ GB।

মোট ফাঁকা জায়গা: কমপক্ষে **৫ GB** ফাঁকা রাখো, ভালো হয় ১০ GB।

## PC-তে খেলা / টেস্ট করা

1. Godot খুলে **Import** করো, এই folder-টা (`ascii-hero-android`) select করো।
2. প্রথমবার Godot project-টা import করবে (`.godot` folder তৈরি হবে — এটা Git-এ যাবে না)।
3. উপরে **Play (F5)** চাপো। 1280x720 landscape window-এ গেম চলবে।
4. WASD দিয়ে চলো, Space দিয়ে attack করো। Joystick-এ mouse দিয়ে drag করলেও চলবে।

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
   - Package: `com.mim.asciihero`, Version: `1.0.0`, Min SDK 24, Target SDK 34
   - Orientation: Landscape
4. **Export Project** চাপো, জায়গা দাও: `exports\android\ascii-hero.apk`
   (প্রথম export-এ কিছু সময় লাগবে, Gradle download হতে পারে।)
5. ফোনে install করা:
   - ফোনে **Settings > About phone > Build number**-এ ৭ বার tap করো
     (Developer options চালু হবে), তারপর **Developer options > USB Debugging** on করো।
   - USB cable দিয়ে ফোন PC-তে লাগাও, ফোনে **Allow USB debugging**-এ OK দাও।
   - APK ফাইলটা ফোনে copy করে tap করে install করো, অথবা PC-তে PowerShell-এ:
     `adb install exports\android\ascii-hero.apk`
   - অথবা Godot-তে **Project > Export > Android > One-Click Deploy**-ও ব্যবহার করা যায়।

> Play Store-এ publish করার জন্য আলাদা release keystore + Play Console লাগবে।
> এটা শুধু নিজের ফোনে টেস্ট করার APK।

## GitHub-এ আপলোড করা

এই folder-এর ভেতরে PowerShell / Git Bash-এ:

```bash
git init
git add .
git commit -m "ASCII Hero - first working Godot game"
git branch -M main
git remote add origin https://github.com/PresidentMim/ascii-hero-android.git
git push -u origin main
```

`.gitignore`-এ `.godot/`, `*.apk`, `*.aab`, `exports/` দেওয়া আছে — তাই
build করা APK আর Godot-এর cache GitHub-এ যাবে না, শুধু source যাবে।

## ফাইল structure

```
project.godot            Godot 4.4, landscape 1280x720, input map, GL Compatibility
main.tscn                3D world + SubViewport + ASCII overlay + HUD
scripts/
  game.gd                Score / health / spawn / slash ring / camera follow / ASCII ground tiles / swaying grass
  player.gd              ASCII superhero on a white horse (gallop legs, rider with sword)
  enemy.gd               Shadow imp, player-এর দিকে হাঁটা, touch damage
  joystick.gd            Virtual joystick (touch + mouse)
  hud.gd                 Score / Enemies / HP bar / ATTACK button / Game Over screen
shaders/
  ascii.gdshader         আসল ASCII shader (cell -> brightness -> character)
assets/
  ascii_atlas.png        ASCII atlas, 240x24, 10টি character: " .:+*o%#M@" (মাপা monotonic ramp)
tools/
  make_atlas.py          Atlas বানানোর script — ramp monotonic কিনা check করে
export_presets.cfg       Android (com.mim.asciihero, SDK 24/34) + Windows Desktop
icon.svg                 Game icon
.gitignore               .godot/, *.apk, *.aab, exports/
```

## ASCII effect যেভাবে কাজ করে

1. 3D world-টা একটা **SubViewport**-এ render হয় (1280x720)।
2. সেই texture-টা একটা full-screen **TextureRect**-এ দেখানো হয়, যার উপরে
   `ascii.gdshader` বসানো।
3. Shader প্রত্যেক ১২x১২ pixel cell-এর brightness মেপে atlas থেকে একটা
   character বেছে নেয় — অন্ধকারে ` ` / `.`, উজ্জ্বল জায়গায় `#` / `@` —
   আর আসল রং (সবুজ ঘাস, নীল suit, লাল cape) দিয়ে tint করে। অন্ধকার
   scene-এও character দেখা যায় বলে shader brightness-কে boost করে
   (`pow(lum, 0.65) * 1.4`), আর glyph-এর background প্রায় কালো রাখে।
4. মাঠটা ২৪x২৪ টাইল (হালকা/গাঢ় সবুজ + ধূসর পাথর) দিয়ে বানানো, যাতে
   মাঠের brightness বদলায় আর ASCII character-ও বদলায় — এক রঙের সমতল
   মাঠ হলে পুরো মাঠ একই character হয়ে যেত।
5. `cell_size_px` বদলালে ASCII-র ঘনত্ব বদলায় (১২ = বর্তমান, ৮ = ঘন, ১৬ = হালকা)।

> Dokkaebi v1-এর শিক্ষা: প্রথম version-এ cell ছিল ৮px, atlas-এর glyph
> পাতলা ছিল, আর scene এত অন্ধকার ছিল যে বেশিরভাগ cell-ই ` ` / `.`-এ
> ম্যাপ হতো — তাই ASCII প্রায় দেখাই যেত না। আরও বড় সমস্যা: পুরনো ramp
> `" .:-=+*#%@"` আসলে monotonic ছিল না (মাপা: `-` < `:`, `%` < `#`),
> তাই উজ্জ্বল cell-ও হালকা glyph পেত। v2 থেকে cell ১২px, atlas ২৪px/cell-এ
> bold glyph, brightness boost, scene-এর আলো বাড়ানো, আর মাপা monotonic
> ramp `" .:+*o%#M@"` ব্যবহার করা হয়েছে — এই গেমে শুরু থেকেই সেটাই আছে।

## Note on ascii_atlas.png
`assets/ascii_atlas.png` is the ASCII character atlas (240x24 px). If it is missing after a Git clone, regenerate it before opening Godot: `python tools/make_atlas.py` (needs Pillow: `pip install pillow`). The script asserts the ramp is strictly increasing.
