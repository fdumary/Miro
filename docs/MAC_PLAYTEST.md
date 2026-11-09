# Mac playtest distribution

The macOS Review preset exports a universal Intel/Apple Silicon Miro.app with the sprite-based icon. macOS uses the Compatibility renderer; other platforms keep their existing renderer. The export preset uses built-in ad-hoc signing as a staging step. Ad-hoc signing is not Apple Developer ID signing or notarization and can still trigger Gatekeeper when downloaded.

For a friend-ready release, copy the exported ZIP to the signing Mac, extract with ditto, sign the app using a Developer ID Application identity with hardened runtime and timestamp, verify the signature, zip with ditto, submit using xcrun notarytool and a locally stored keychain profile, wait for Accepted, staple the ticket, and re-create the final ZIP. Use codesign --verify --deep --strict and spctl --assess --type execute on the final bundle. Never store signing passwords, certificates or notarization credentials in this repository.

The signing Mac's login keychain must be unlocked locally. Set up a notarytool profile using store-credentials on that Mac; keep secrets in its keychain. An Apple Development or Apple Distribution certificate does not replace a Developer ID Application certificate for this distribution method.

The damaged-app message can reflect quarantine/signing checks rather than corrupt game data. Do not tell testers to disable Gatekeeper globally. For an unnotarized trusted playtest, follow the version-appropriate Open Anyway instructions in Godot's guide; notarization is preferred for sharing.

References: [Godot macOS launch guide](https://docs.godotengine.org/en/stable/tutorials/export/running_on_macos.html), [Apple notarization guide](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

Native headless startup checks passed for all five floors on the author's Mac. Visual and friend-machine playtesting remain necessary.

The November 9, 2026 release was signed on the author's Mac using Developer ID Application, accepted by Apple's notary service (submission b0646ecd-f955-4695-a78f-ea885c81bcfa), and stapled. Native validation returned `source=Notarized Developer ID`. The final archive is `C:/Users/ethan/Miro/build/Miro-Playtest-macOS.zip`. Its bundled app requires macOS 13+ on Apple Silicon or macOS 11+ on Intel, as declared by the official export template. The included launch notes are outside the signed .app bundle.
