; Inno Setup 6.5+ script for PDF Password Remover.
; Build with build-installer.ps1, which publishes the app into installer\publish first.

#define AppName "PDF Password Remover"
#define AppExe "PdfPasswordRemover.exe"
; The exe's file version is 4-part (1.2.0.0); RemoveFileExt drops the last ".0" to give 1.2.0.
#define AppVersion RemoveFileExt(GetVersionNumbersString(AddBackslash(SourcePath) + "publish\" + AppExe))

; qpdf is downloaded from its official GitHub release during installation.
; When updating, change the version and paste the SHA-256 from the release page.
#define QpdfVersion "12.4.2"
#define QpdfFolder "qpdf-" + QpdfVersion + "-msvc64"
#define QpdfUrl "https://github.com/qpdf/qpdf/releases/download/v" + QpdfVersion + "/" + QpdfFolder + ".zip"
#define QpdfSha256 "db87077e683630c1217e0e8f9a20a9749d952ab676e881c3689187763a5de25d"
#define QpdfZipSize "28_183_147"

[Setup]
AppId={{4275C89E-5136-4226-A48D-F7DD41356FC6}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#AppExe}
; Asks "install for me only" (no admin) or "for all users" (admin).
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
ArchiveExtraction=full
OutputDir=output
OutputBaseFilename=PdfPasswordRemover-{#AppVersion}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "publish\{#AppExe}"; DestDir: "{app}"; Flags: ignoreversion

; Download qpdf (SHA-256 checked) and unpack it to a temp folder...
Source: "{#QpdfUrl}"; DestName: "qpdf.zip"; DestDir: "{tmp}\qpdf"; \
  Hash: "{#QpdfSha256}"; ExternalSize: {#QpdfZipSize}; \
  Flags: external download extractarchive recursesubdirs createallsubdirs ignoreversion
; ...then install only its bin folder next to the app, where the app looks for it.
Source: "{tmp}\qpdf\{#QpdfFolder}\bin\*"; DestDir: "{app}\qpdf"; Flags: external ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
