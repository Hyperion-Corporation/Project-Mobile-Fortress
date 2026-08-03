# Fonts

Drop custom `.ttf`/`.otf` game fonts in this directory, then:

1. Add each font file to the `MyGame` Xcode target (Target Membership checkbox
   in the File Inspector) so it's copied into the app bundle.
2. Register the filenames under `Fonts provided by application` (`UIAppFonts`)
   in `Info.plist`.
3. Reference them in SwiftUI via `Font.custom("Font Name", size: ...)`, or
   add a `Theme.swift` token (see `UI/Theme/Theme.swift`) so screens don't
   hardcode font names directly.

No binary font files are bundled with the template — ship your own or use a
system font (`.rounded` design, as `Theme`/the menu screens currently do) until
you add one.
