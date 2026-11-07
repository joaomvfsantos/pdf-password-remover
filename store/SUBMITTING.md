# Publishing to the Microsoft Store

The Store version is the same app as the GitHub release, packaged as an MSIX with qpdf included (the Store doesn't allow installers that download parts at install time). The Store signs the package and keeps it updated, so Store users never see the SmartScreen warning.

How the files fit together:

| File | What it does |
| --- | --- |
| [AppxManifest.xml](AppxManifest.xml) | The package manifest: name, Store identity, icons. |
| [Assets/](Assets) | Icons, generated from `app.ico` by [make-assets.ps1](make-assets.ps1). |
| [../build-store.ps1](../build-store.ps1) | Builds `installer\output\PdfPasswordRemover-<version>-x64.msix`. |
| [../.github/workflows/release.yml](../.github/workflows/release.yml) | On every version tag, also builds the `.msix` and saves it as the `store-package` artifact of the workflow run. |

GitHub Actions builds the Store package; you upload it in Partner Center by hand. (Automatic uploads need a Microsoft Entra application linked to Partner Center, which only company accounts can add.)

## One-time setup

1. **Create a Partner Center developer account** at <https://storedeveloper.microsoft.com>. Choose an *individual* account (free for individual developers). Identity verification can take a few days.
2. **Reserve the app name.** In [Partner Center](https://partner.microsoft.com/dashboard/apps-and-games/overview), go to **Apps and games > New product > MSIX or PWA app** and reserve the name. The Store version is called `PDF Unlock`, because `PDF Password Remover` was taken.

   The app name in [AppxManifest.xml](AppxManifest.xml) (both `DisplayName` values) must match the reserved name exactly. It's set to `PDF Unlock`; change it there if you ever reserve a different name.
3. **Check the package identity.** [AppxManifest.xml](AppxManifest.xml) already has the values from **Product management > Product identity** (`Identity Name`, `Identity Publisher` and `PublisherDisplayName`). If Partner Center ever shows different ones, update them there. They aren't secret: every installed copy of the app shows them.
4. **Take screenshots.** At least one is required, 1366×768 or larger (PNG). A screenshot of the main window, plus one of the "Saved to…" message, is enough.

## Each release

1. Push a version tag as usual (`git tag v1.2.0 && git push origin v1.2.0`). GitHub Actions creates the GitHub release and builds the Store package.
2. Open the workflow run under the repository's **Actions** tab and download the **store-package** artifact (it's kept for 30 days). Unzip it to get `PdfPasswordRemover-1.2.0-x64.msix`.

   To build it on your PC instead (for example, if the artifact has expired), run `build-installer.ps1` and then `build-store.ps1` with `-Version 1.2.0`.
3. In Partner Center, open the app and click **Start submission** the first time, or **Start update** afterwards.
4. **Packages**: upload the `.msix`. Partner Center checks that the identity matches. On updates, remove the previous version's package so only the new one is offered.
5. The first time, fill in the other sections (see below). On updates they're copied from the last submission, so you only need to review them. Then **Submit for certification**. Certification usually takes 1–3 business days, and Partner Center emails you the result.

Every Store submission needs a higher version than the last one, which version tags already guarantee.

## First submission: what to fill in

**Pricing and availability**: Free. Markets: all, or the ones you want. Visibility: public.

**Properties**
- Category: *Productivity* (subcategory if offered: none needed).
- Privacy policy URL: `https://github.com/joaomvfsantos/pdf-password-remover/blob/main/PRIVACY.md`
- Website: `https://github.com/joaomvfsantos/pdf-password-remover`
- Support contact: `https://github.com/joaomvfsantos/pdf-password-remover/issues`
- Product declarations: leave defaults. The app doesn't collect data.

**Age ratings**: answer the questionnaire. No user-generated content, no communication, no purchases, so it comes out as rated for everyone.

**Submission options > restricted capabilities**: the package uses `runFullTrust`. Explain it like this:

> This is a desktop (Win32/.NET WinForms) app packaged as MSIX. runFullTrust is required for every desktop app in an MSIX package. The app runs the bundled qpdf command-line tool to decrypt the PDF the user picks.

**Store listing (English)**: copy the texts from [LISTING.md](LISTING.md). Upload the screenshots and use `store\Assets\Square150x150Logo.scale-200.png` as the logo if a 300×300 one is asked for.

## After it's live

Add the Store link to the Download section of the [README](../README.md), so non-technical users go there first. Microsoft provides an official "Get it from Microsoft" badge at <https://apps.microsoft.com/badge>.
