# PDF Password Remover

A small Windows app that removes the password from a PDF. It is a GUI wrapper around [qpdf](https://qpdf.sourceforge.io/) and runs:

```
qpdf --password=<password> --decrypt input.pdf output.pdf
```

Pick a PDF, enter its password, click **Decrypt**, and choose where to save the unlocked copy.

## Requirements

- Windows 10 or 11
- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) (to build)
- [qpdf](https://github.com/qpdf/qpdf/releases) (to run)

Install both with winget:

```
winget install Microsoft.DotNet.SDK.10
winget install QPDF.QPDF
```

## Build

From the project folder:

```
dotnet build -c Release
```

The app is written to `bin\Release\net10.0-windows\PdfPasswordRemover.exe`.

To run it straight from source during development:

```
dotnet run
```

## Publish a single .exe

```
dotnet publish -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true
```

The output is `bin\Release\net10.0-windows\win-x64\publish\PdfPasswordRemover.exe`. It needs the .NET 10 Desktop Runtime on the target machine.

If the target machine shouldn't need the runtime installed, use `--self-contained true` instead. The .exe gets much larger.

## Build the installer

The installer is built with [Inno Setup](https://jrsoftware.org/isinfo.php) 6.5 or later:

```
winget install JRSoftware.InnoSetup
```

Then, from the project folder:

```
powershell -ExecutionPolicy Bypass -File build-installer.ps1
```

This publishes the app as a self-contained `.exe` into `installer\publish\` and compiles [installer\PdfPasswordRemover.iss](installer/PdfPasswordRemover.iss). The output is `installer\output\PdfPasswordRemover-<version>-setup.exe`. The version comes from `<Version>` in `PdfPasswordRemover.csproj`, or from `-Version 1.2.0` if given.

What the installer does:

- Includes the .NET runtime, so end users don't need to install .NET.
- Asks whether to install for the current user only (no admin prompt) or for all users (admin, Program Files).
- Downloads qpdf from its official GitHub release, checks the zip's SHA-256, and installs qpdf's `bin` files to `<install folder>\qpdf\`. This step needs an internet connection.
- Adds a Start menu shortcut, and optionally a desktop shortcut.
- Removes everything, including qpdf, when the app is uninstalled.

To use a newer qpdf, edit `QpdfVersion`, `QpdfSha256` and `QpdfZipSize` at the top of the `.iss` file. Get the values for the `qpdf-<version>-msvc64.zip` asset from the [qpdf releases page](https://github.com/qpdf/qpdf/releases).

The installer isn't code-signed, so Windows SmartScreen will warn users about an unrecognized app the first time they run it.

To also build a portable zip (the `.exe` plus qpdf's `bin` files, no install needed), run `build-portable.ps1` after `build-installer.ps1`. It downloads the qpdf version set in the `.iss` file and checks its SHA-256. The output is `installer\output\PdfPasswordRemover-<version>-portable.zip`.

## Releasing

Push a version tag and [.github/workflows/release.yml](.github/workflows/release.yml) builds the installer and the portable zip on GitHub Actions and publishes them as a GitHub Release:

```
git tag v1.2.0
git push origin v1.2.0
```

The version comes from the tag, so there's no need to edit the `.csproj` (its `<Version>` is only used for local builds). Use plain `vMAJOR.MINOR.PATCH` tags.

## Finding qpdf

The app looks for qpdf in this order:

1. `qpdf.exe` in the same folder as `PdfPasswordRemover.exe`
2. `qpdf\qpdf.exe` under that folder (where the installer puts it)
3. `qpdf` on the `PATH`

To ship the app to a machine without qpdf installed, copy `qpdf.exe` and the `.dll` files from qpdf's `bin` folder (for example `C:\Program Files\qpdf 12.4.2\bin`) next to `PdfPasswordRemover.exe`.
