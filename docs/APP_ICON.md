# Miro: Last Man Standing app icon

App icon artwork by Lindsey-Anne Rattray.

`assets/icons/miro_app.png` uses the supplied `Untitled 13.png` artwork. The landscape image is cropped to a centered square by removing only the side margins, preserving the character, then resized to 1024 × 1024. No generated artwork is used.

`miro_app.ico` contains 16, 32, 48, 64, 128 and 256 pixel square images, encoded with Pillow. `project.godot` keeps the PNG application icon and ICO Windows native icon paths. Both Windows export presets use the ICO for the executable.

Build with `Build Windows.ps1`; validate with `Check Windows Build.ps1`. The final package is `build/Miro-Playtest-Windows.zip`, containing `Miro.exe` at its root.
