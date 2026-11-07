# PDF Unlock

Tired of typing the same password every time you open a PDF? PDF Unlock saves an unlocked copy of the file, so it opens without asking.

*Formerly called PDF Password Remover.*

Bank statements, payslips, utility bills and other documents often arrive password-protected. If you know the password, this app removes it in a couple of clicks.

- **Simple**: pick the file, type the password, click Decrypt.
- **Private**: everything happens on your computer. Your files and passwords are never uploaded anywhere.
- **Safe**: your original file is left untouched. The app saves a separate unlocked copy.
- **Free and open source.**

> [!NOTE]
> You need to know the PDF's password. This app does not guess or crack passwords.

## Download

Get the latest version from the [Releases page](https://github.com/joaomvfsantos/pdf-password-remover/releases/latest). There are two options:

| File | What it is |
| --- | --- |
| `PdfPasswordRemover-<version>-setup.exe` | **Installer (recommended).** Adds the app to your Start menu and can be removed from Windows Settings like any other app. |
| `PdfPasswordRemover-<version>-portable.zip` | **Portable version.** Nothing to install: unzip it anywhere (even a USB stick) and run `PdfPasswordRemover.exe`. |

Works on Windows 10 and Windows 11 (64-bit). Nothing else needs to be installed.

## Installing

1. Run the `setup.exe` you downloaded.
2. If Windows shows **"Windows protected your PC"**, click **More info**, then **Run anyway**. This appears because the app isn't code-signed, which is common for small free apps.
3. Choose whether to install just for you (no admin rights needed) or for everyone on the computer.
4. Follow the steps to finish. The installer needs an internet connection, because it downloads [qpdf](https://qpdf.sourceforge.io/), the free tool that does the actual decryption.

To uninstall, go to **Settings > Apps > Installed apps**, find **PDF Unlock** and click **Uninstall**.

## How to use it

1. Open **PDF Unlock** from the Start menu.
2. Click **Browse…** and choose the locked PDF. You can also paste the file's path into the box.
3. Type the PDF's password.
4. Click **Decrypt** (or press Enter).
5. Choose where to save the unlocked copy. By default it's saved next to the original as `<name> (unlocked).pdf`.

That's it. The new file opens without a password.

## Troubleshooting

**"invalid password"**
The password is wrong. Check for typos, Caps Lock, and extra spaces. Passwords are case-sensitive.

**"The output file must be different from the input file."**
The app won't overwrite the original. Pick a different name or folder for the unlocked copy.

**"qpdf was not found"**
Part of the app is missing. Reinstall it with the installer, or if you use the portable version, make sure all the files from the zip are kept together in the same folder.

**"qpdf reported warnings"**
The file was still saved. Some PDFs have small errors that qpdf fixes or works around while unlocking. Open the new file to check it looks right.

## Found a bug or have an idea?

[Open an issue](https://github.com/joaomvfsantos/pdf-password-remover/issues) on GitHub.

Want to build the app yourself or help improve it? See [CONTRIBUTING.md](CONTRIBUTING.md).

## Credits

PDF Unlock uses [qpdf](https://qpdf.sourceforge.io/) to decrypt PDFs.
