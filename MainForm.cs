using System.ComponentModel;
using System.Diagnostics;

namespace PdfPasswordRemover;

public class MainForm : Form
{
    private readonly TextBox _pathBox = new() { Dock = DockStyle.Fill };
    private readonly TextBox _passwordBox = new() { Dock = DockStyle.Fill, UseSystemPasswordChar = true };
    private readonly Button _browseButton = new() { Text = "Browse…", AutoSize = true };
    private readonly Button _decryptButton = new() { Text = "Decrypt", AutoSize = true, Anchor = AnchorStyles.Right };

    public MainForm()
    {
        Text = "PDF Password Remover";
        // Load every size in app.ico so the title bar and taskbar stay sharp at any DPI
        // (Icon.ExtractAssociatedIcon would give only a single 32px image).
        using (var iconStream = typeof(MainForm).Assembly.GetManifestResourceStream("app.ico")!)
            Icon = new Icon(iconStream);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        AutoScaleMode = AutoScaleMode.Dpi;
        AutoSize = true;
        AutoSizeMode = AutoSizeMode.GrowAndShrink;
        Padding = new Padding(10);

        var layout = new TableLayoutPanel
        {
            ColumnCount = 3,
            RowCount = 3,
            AutoSize = true,
            Dock = DockStyle.Fill,
        };
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 320));
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));

        layout.Controls.Add(new Label { Text = "PDF file", AutoSize = true, Anchor = AnchorStyles.Left }, 0, 0);
        layout.Controls.Add(_pathBox, 1, 0);
        layout.Controls.Add(_browseButton, 2, 0);

        layout.Controls.Add(new Label { Text = "Password", AutoSize = true, Anchor = AnchorStyles.Left }, 0, 1);
        layout.Controls.Add(_passwordBox, 1, 1);

        layout.Controls.Add(_decryptButton, 1, 2);
        layout.SetColumnSpan(_decryptButton, 2);

        Controls.Add(layout);
        AcceptButton = _decryptButton;

        _browseButton.Click += (_, _) => Browse();
        _decryptButton.Click += async (_, _) => await DecryptAsync();
    }

    private void Browse()
    {
        using var dialog = new OpenFileDialog { Filter = "PDF files (*.pdf)|*.pdf|All files (*.*)|*.*" };
        if (dialog.ShowDialog(this) == DialogResult.OK)
            _pathBox.Text = dialog.FileName;
    }

    private async Task DecryptAsync()
    {
        var input = _pathBox.Text.Trim().Trim('"');
        if (!File.Exists(input))
        {
            ShowError("Choose an existing PDF file first.");
            return;
        }

        using var saveDialog = new SaveFileDialog
        {
            Filter = "PDF files (*.pdf)|*.pdf",
            InitialDirectory = Path.GetDirectoryName(Path.GetFullPath(input)),
            FileName = Path.GetFileNameWithoutExtension(input) + " (unlocked).pdf",
            OverwritePrompt = true,
        };
        if (saveDialog.ShowDialog(this) != DialogResult.OK)
            return;

        var output = saveDialog.FileName;
        if (string.Equals(Path.GetFullPath(output), Path.GetFullPath(input), StringComparison.OrdinalIgnoreCase))
        {
            ShowError("The output file must be different from the input file.");
            return;
        }

        var startInfo = new ProcessStartInfo(FindQpdf())
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        };
        startInfo.ArgumentList.Add("--password=" + _passwordBox.Text);
        startInfo.ArgumentList.Add("--decrypt");
        startInfo.ArgumentList.Add(input);
        startInfo.ArgumentList.Add(output);

        _decryptButton.Enabled = false;
        UseWaitCursor = true;
        try
        {
            using var process = Process.Start(startInfo)!;
            var stdoutTask = process.StandardOutput.ReadToEndAsync();
            var stderrTask = process.StandardError.ReadToEndAsync();
            await process.WaitForExitAsync();
            var messages = ((await stderrTask) + (await stdoutTask)).Trim();

            // qpdf exit codes: 0 = success, 3 = success with warnings, 2 = error.
            if (process.ExitCode == 0)
                ShowInfo($"Saved to {output}");
            else if (process.ExitCode == 3)
                ShowInfo($"Saved to {output}\n\nqpdf reported warnings:\n{messages}");
            else
                ShowError(string.IsNullOrEmpty(messages) ? $"qpdf failed with exit code {process.ExitCode}." : messages);
        }
        catch (Win32Exception)
        {
            ShowError("qpdf was not found. Install qpdf (and add it to PATH) or put qpdf.exe next to this app.");
        }
        finally
        {
            UseWaitCursor = false;
            _decryptButton.Enabled = true;
        }
    }

    // Prefer a copy shipped with the app (the installer puts it in a qpdf subfolder), then PATH.
    private static string FindQpdf()
    {
        foreach (var candidate in new[] { "qpdf.exe", Path.Combine("qpdf", "qpdf.exe") })
        {
            var path = Path.Combine(AppContext.BaseDirectory, candidate);
            if (File.Exists(path))
                return path;
        }
        return "qpdf";
    }

    private void ShowInfo(string message) =>
        MessageBox.Show(this, message, Text, MessageBoxButtons.OK, MessageBoxIcon.Information);

    private void ShowError(string message) =>
        MessageBox.Show(this, message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
}
