param(
    [Alias('hosting')][switch]$HostingOnly,
    [switch]$force,
    [switch]$confirm
)

# Helper: Prompt for version bump
function Prompt-VersionBump {
    $choices = @("major", "minor", "patch")
    $choice = Read-Host "Which version do you want to bump? (major/minor/patch)"
    if ($choices -notcontains $choice) {
        Write-Host "Invalid choice. Please enter major, minor, or patch."
        exit 1
    }
    return $choice
}

# Helper: Get current version from pubspec.yaml
function Get-CurrentVersion {
    $pubspec = Get-Content "pubspec.yaml"
    $versionLine = $pubspec | Where-Object { $_ -match "^version:" }
    if ($versionLine) {
        $currentVersion = $versionLine -replace "version:\s*", ""
    } else {
        Write-Host "No version found in pubspec.yaml. Please add a version line."
        param(
            [switch]$force
        )
    }
}

#region Helper Functions
function Write-Section {
    param([string]$Title, [int]$Step, [int]$Total)
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ("Step $($Step) of $($Total): $Title") -ForegroundColor Yellow
            Write-Host "================================" -ForegroundColor Cyan
        }

        function Write-ErrorAndExit {
            param(
                [string]$Message,
                [scriptblock]$BeforeExit = $null
            )
            Write-Host "[ERROR] $Message" -ForegroundColor Red
            if ($BeforeExit) { & $BeforeExit }
            exit 1
        }

        function Get-Pubspec-Version {
            param([string]$Path)
            $content = Get-Content -Path $Path -ErrorAction Stop
            $regex = '^\s*version\s*:\s*([0-9]+)\.([0-9]+)\.([0-9]+)(\+[0-9]+)?\s*$'
            foreach ($line in $content) {
                $m = [regex]::Match($line, $regex)
                if ($m.Success) {
                    return [pscustomobject]@{
                        Major = [int]$m.Groups[1].Value
                        Minor = [int]$m.Groups[2].Value
                        Patch = [int]$m.Groups[3].Value
                        Build = $m.Groups[4].Value # e.g. "+1" or empty
                    }
                }
            }
            Write-ErrorAndExit "Could not find a valid 'version:' line in pubspec.yaml."
        }

        function Set-Pubspec-Version {
            param(
                [string]$Path,
                [int]$Major,
                [int]$Minor,
                [int]$Patch,
                [string]$BuildSuffix
            )
            $lines = Get-Content -Path $Path -ErrorAction Stop
            $regex = '^\s*version\s*:\s*([0-9]+)\.([0-9]+)\.([0-9]+)(\+[0-9]+)?\s*$'
            $newVersion = "$Major.$Minor.$Patch"
            $replacement = "version: $newVersion$BuildSuffix"
            $updated = $false
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match $regex) {
                    $lines[$i] = $replacement
                    $updated = $true
                    break
                }
            }
            if (-not $updated) { Write-ErrorAndExit "Failed to update version in pubspec.yaml." }
            Set-Content -Path $Path -Value $lines -Encoding UTF8
            return $newVersion
        }
        #endregion Helper Functions

        #region Globals
                $ErrorActionPreference = 'Stop'
                $startTime = Get-Date
                $totalSteps = 10
                $pubspecPath = "./pubspec.yaml"
                $changelogPath = "./CHANGELOG.md"
        # If hosting flag is passed, run a local hosting-only flow and exit.
                if ($HostingOnly) {
                    Write-Host "[HOSTING ONLY] Cleaning build folder..." -ForegroundColor Cyan
                    try {
                        if (Test-Path "./build") {
                            Remove-Item -Path "./build" -Recurse -Force -ErrorAction Stop
                            Write-Host "Removed ./build" -ForegroundColor Green
                        } else {
                            Write-Host "No ./build folder found, skipping removal." -ForegroundColor Yellow
                        }

                        Write-Host "Running 'flutter pub get'..." -ForegroundColor Cyan
                        & flutter pub get
                        if ($LASTEXITCODE -ne 0) { Write-Host "flutter pub get failed (exit $LASTEXITCODE)" -ForegroundColor Red; exit 1 }

                        Write-Host "Running 'flutter build web'..." -ForegroundColor Cyan
                        & flutter build web
                        if ($LASTEXITCODE -ne 0) { Write-Host "flutter build web failed (exit $LASTEXITCODE)" -ForegroundColor Red; exit 1 }

                        Write-Host "Running 'firebase deploy --only hosting'..." -ForegroundColor Cyan
                        & firebase deploy --only hosting
                        if ($LASTEXITCODE -ne 0) { Write-Host "firebase deploy failed (exit $LASTEXITCODE)" -ForegroundColor Red; exit 1 }

                        Write-Host "Hosting deploy completed successfully." -ForegroundColor Green
                        exit 0
                    }
                    catch {
                        Write-Host "[ERROR] $_" -ForegroundColor Red
                        exit 1
                    }
                }
                #endregion Globals

        #region Pre-checks
        if (-not (Test-Path $pubspecPath)) { Write-ErrorAndExit "pubspec.yaml not found at $pubspecPath" }
        if (-not (Test-Path $changelogPath)) { Write-ErrorAndExit "CHANGELOG.md not found at $changelogPath" }

        # Check for uncommitted changes before starting (unless --force is set)
        # If running hosting-only, skip this check so local deploys work with dirty tree.
        if (-not $force -and -not $HostingOnly) {
            $gitStatus = git status --porcelain
            if ($gitStatus) {
                Write-ErrorAndExit "There are uncommitted changes in the repository. Please commit or stash them before running the release script." { Write-Host $gitStatus }
            }
        }
        #endregion Pre-checks

        try {
            #region Step 1: Version Increment (pubspec.yaml)
            Write-Section "Version Increment" 1 $totalSteps
            $v = Get-Pubspec-Version -Path $pubspecPath
            $currentVersion = "$($v.Major).$($v.Minor).$($v.Patch)$($v.Build)"
            Write-Host "Current version: $currentVersion" -ForegroundColor Green
            Write-Host "Which version do you want to increment?" -ForegroundColor Magenta
            Write-Host "1. Major"
            Write-Host "2. Minor"
            Write-Host "3. Patch"
            $choice = Read-Host "Enter 1, 2, or 3 (or q to quit)"
            $major = [int]$v.Major
            $minor = [int]$v.Minor
            $patch = [int]$v.Patch
            switch ($choice) {
                '1' { $major++; $minor=0; $patch=0 }
                '2' { $minor++; $patch=0 }
                '3' { $patch++ }
                'q' { exit 0 }
                default { Write-ErrorAndExit "Invalid choice. Exiting." }
            }
            # Preserve existing build suffix if present
            $buildSuffix = $v.Build
            $newVersion = Set-Pubspec-Version -Path $pubspecPath -Major $major -Minor $minor -Patch $patch -BuildSuffix $buildSuffix
            Write-Host "Updated version to $newVersion$buildSuffix in pubspec.yaml" -ForegroundColor Green
            #endregion Step 1

            #region Step 4: Resolve last tag (for reliability use HEAD^ like the model)
            Write-Section "Resolve last tag" 2 $totalSteps
            $lastTag = git describe --tags --abbrev=0 HEAD^
            if (-not $lastTag) { Write-ErrorAndExit "No git tag found. Create an initial tag to start changelog ranges." }
            Write-Host "Last tag: $lastTag" -ForegroundColor Green
            #endregion Step 4

            #region Step 5: Collect commit messages since last tag
            Write-Section "Collect commits" 3 $totalSteps
            $commitBodies = git log "$lastTag..HEAD" --pretty=format:"%B" | Out-String
            $commitLines = $commitBodies -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
            if (-not $commitLines -or $commitLines.Count -eq 0) {
                Write-Host "No commits found since $lastTag. Nothing to add to changelog." -ForegroundColor Yellow
            }
            #endregion Step 5

            #region Step 6: Group commits by type tags
            Write-Section "Group commits" 4 $totalSteps
            $typeMap = @{
                "feat" = "Added"
                "fix" = "Fixed"
                "change" = "Changed"
                "chore" = "Changed"
            }
            $grouped = @{
                "Added" = @()
                "Changed" = @()
                "Fixed" = @()
            }
            $globalNotes = @()

            foreach ($line in $commitLines) {
                if ($line -match "--global") {
                    $desc = $line -replace "--global", "" -replace "--(feat|fix|change|chore)", "" -replace "^\s*-*\s*", "" -replace "\s+$", ""
                    if ($desc) { $globalNotes += ("- " + ($desc.Substring(0,1).ToUpper() + $desc.Substring(1))) }
                    continue
                }

                # Use the exact expression requested
                $typeTags = [regex]::Matches($line, "--(feat|fix|change|chore)") | ForEach-Object { $_.Groups[1].Value }

                if ($typeTags.Count -gt 0) {
                    $desc = $line -replace "--(feat|fix|change|chore)", "" -replace "^\s*-*\s*", "" -replace "\s+$", ""
                    if (-not [string]::IsNullOrWhiteSpace($desc)) {
                        $desc = $desc.Substring(0,1).ToUpper() + $desc.Substring(1)
                        foreach ($type in $typeTags) {
                            $key = $typeMap[$type]
                            if ($key) { $grouped[$key] += "- $desc" }
                        }
                    }
                }
            }
            #endregion Step 6

            #region Step 7: Prepare release notes text
            Write-Section "Prepare release notes" 5 $totalSteps
            $newDate = Get-Date -Format "dd-MM-yyyy"
            $changelogSection = "## [$newVersion] - $newDate`n"
            if ($globalNotes.Count -gt 0) {
                $changelogSection += "### Global`n" + (($globalNotes | Sort-Object -Unique) -join "`n") + "`n`n"
            }
            foreach ($type in @("Added", "Changed", "Fixed")) {
                $items = $grouped[$type] | Where-Object { $_ } | Sort-Object -Unique
                if ($items -and $items.Count -gt 0) {
                    $changelogSection += "### $type`n" + ($items -join "`n") + "`n"
                }
            }
            # Capitalize the first letter of each bullet point
            $changelogSection = ($changelogSection -split "`n") | ForEach-Object {
                if ($_ -match '^\s*- ') {
                    $bullet = $_.Substring(0, $_.IndexOf('-')+2)
                    $rest = $_.Substring($_.IndexOf('-')+2).TrimStart()
                    $capitalized = if ($rest.Length -gt 0) { $rest.Substring(0,1).ToUpper() + $rest.Substring(1) } else { $rest }
                    "$bullet$capitalized"
                } else { $_ }
            } | Out-String
            #endregion Step 7

            #region Step 8: Update CHANGELOG.md
            Write-Section "Update CHANGELOG.md" 6 $totalSteps
            $existing = Get-Content $changelogPath -ErrorAction Stop
            if ($existing.Count -ge 1) {
                $final = @($existing[0], "", $changelogSection) + $existing[1..($existing.Count-1)]
            } else {
                $final = @("# Changelog", "", $changelogSection)
            }
            Set-Content -Path $changelogPath -Value $final -Encoding UTF8
            #endregion Step 8

            if ($confirm) {
                #region Confirmation before continuing
                $confirmation = Read-Host "Version bumped to $newVersion$buildSuffix and changelog updated. Continue with release? (y/n)"
                if ($confirmation -notmatch '^(y|yes)$') {
                    Write-Host "Release aborted by user." -ForegroundColor Yellow
                    exit 0
                }
                #endregion Confirmation before continuing
            }

            #region Step 9: Commit and push
            Write-Section "Commit and push" 7 $totalSteps
            git add $pubspecPath $changelogPath
            git commit -m "chore: prepare release $newVersion"
            git push
            if ($LASTEXITCODE -ne 0) { Write-ErrorAndExit "Git push failed." }
            #endregion Step 9

            #region Step 10: Trigger GitHub Workflows
            Write-Section "Trigger GitHub Workflows" 8 $totalSteps

            # Trigger release.yml workflow
            Write-Host "Triggering release.yml workflow..." -ForegroundColor Magenta
            gh workflow run release.yml

            # Trigger release_hosting.yml workflow
            Write-Host "Triggering release_hosting.yml workflow..." -ForegroundColor Magenta
            gh workflow run release_hosting.yml
            #endregion Step 10

            #region Final Output
            $endTime = Get-Date
            $duration = $endTime - $startTime
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host ("All done! Total time: {0:mm\:ss} (mm:ss)" -f $duration) -ForegroundColor Green
            Write-Host "================================" -ForegroundColor Cyan
            #endregion Final Output
        }
        catch {
            Write-Host "[FATAL ERROR] $_" -ForegroundColor Red
            exit 1
        }
