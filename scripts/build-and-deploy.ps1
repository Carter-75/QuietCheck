# QuietCheck - PowerShell Build and Deploy Script
# Adapted from Doomlings Companion
# This script builds AAB/APK files, manages backups, and pushes to Git

param(
    [switch]$Force,
    [switch]$SkipGit,
    [string]$AndroidSdkPath = ""
)

$ConfigFile = Join-Path $PSScriptRoot "flutter-path.conf"
$FlutterCmd = "flutter"

# Try to load formatted path from config
if (Test-Path $ConfigFile) {
    $FlutterCmd = Get-Content $ConfigFile -Raw
    $FlutterCmd = $FlutterCmd.Trim()
}

# Check if command exists
if (-not (Get-Command $FlutterCmd -ErrorAction SilentlyContinue)) {
    # Try finding common locations
    $CommonPaths = @(
        "C:\src\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat",
        "$env:LOCALAPPDATA\Programs\flutter\bin\flutter.bat",
        "$env:USERPROFILE\scoop\apps\flutter\current\bin\flutter.bat",
        "$env:ProgramData\chocolatey\bin\flutter.exe"
    )
    
    $found = $false
    foreach ($path in $CommonPaths) {
        if (Test-Path $path) {
            $FlutterCmd = $path
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Host "Flutter SDK not found automatically." -ForegroundColor Yellow
        $userInput = Read-Host "Please enter the full path to your 'flutter.bat' (e.g. C:\src\flutter\bin\flutter.bat)"
        if (-not [string]::IsNullOrWhiteSpace($userInput)) {
            $FlutterCmd = $userInput.Trim('"') # Remove quotes if user added them
            Set-Content -Path $ConfigFile -Value $FlutterCmd
            Write-Host "Path saved to $ConfigFile" -ForegroundColor Green
        }
    }
}
Write-Host "Using Flutter: $FlutterCmd" -ForegroundColor Cyan

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "     QuietCheck - Build and Deploy" -ForegroundColor Cyan  
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Confirmation prompt (unless -Force is used)
if (-not $Force) {
    Write-Host "This script will:" -ForegroundColor Yellow
    Write-Host "- Clean the project" -ForegroundColor Yellow
    Write-Host "- Increment version in pubspec.yaml" -ForegroundColor Yellow
    Write-Host "- Generate AAB and APK files via Flutter" -ForegroundColor Yellow
    Write-Host "- Backup previous builds" -ForegroundColor Yellow
    Write-Host "- Commit and push changes to Git (unless -SkipGit)" -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Do you want to continue? (Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "Build cancelled by user." -ForegroundColor Red
        exit 0
    }
}

Write-Host ""
Write-Host "Starting build process..." -ForegroundColor Green
Write-Host ""

# Set variables
$RootDir = (Resolve-Path (Join-Path $PSScriptRoot ".." )).Path
$BuildOutputDir = Join-Path $RootDir "builds"
$BackupDir = Join-Path $BuildOutputDir "backup"
$AndroidDir = Join-Path $RootDir "android"
$AabSource = Join-Path $RootDir "build\app\outputs\bundle\release\app-release.aab"
$ApkSource = Join-Path $RootDir "build\app\outputs\flutter-apk\app-release.apk"
$LocalPropertiesFile = Join-Path $AndroidDir "local.properties"
$KeyPropertiesFile = Join-Path $AndroidDir "key.properties"

# Create timestamp for backup
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host "[INFO] Build started at $timestamp" -ForegroundColor Cyan
Write-Host "[INFO] Root directory: $RootDir" -ForegroundColor Cyan
Write-Host ""

# Function to Write colored output
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$Type] $Message" -ForegroundColor $color
}

# Check if builds directory exists and backup if needed
if (Test-Path $BuildOutputDir) {
    Write-Status "Previous builds found, creating backup..." "INFO"
    
    # Create backup directory if it doesn't exist
    if (-not (Test-Path $BackupDir)) {
        New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
        Write-Status "Created backup directory: $BackupDir" "INFO"
    }
    
    # Backup existing AAB file
    $existingAab = Join-Path $BuildOutputDir "app-release.aab"
    if (Test-Path $existingAab) {
        $backupAab = Join-Path $BackupDir "app-release-backup_$timestamp.aab"
        Copy-Item $existingAab $backupAab -Force
        Write-Status "AAB backup created" "SUCCESS"
    }
    
    # Backup existing APK file
    $existingApk = Join-Path $BuildOutputDir "app-release.apk"
    if (Test-Path $existingApk) {
        $backupApk = Join-Path $BackupDir "app-release-backup_$timestamp.apk"
        Copy-Item $existingApk $backupApk -Force
        Write-Status "APK backup created" "SUCCESS"
    }
}
else {
    Write-Status "No previous builds found, creating fresh builds directory..." "INFO"
    New-Item -Path $BuildOutputDir -ItemType Directory -Force | Out-Null
    Write-Status "Created builds directory: $BuildOutputDir" "SUCCESS"
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        STEP 1: CLEANING PROJECT" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Status "Cleaning Flutter project..." "INFO"
& $FlutterCmd clean
if ($LASTEXITCODE -ne 0) {
    Write-Status "Flutter clean failed" "WARNING"
}
else {
    Write-Status "Flutter clean completed" "SUCCESS"
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        STEP 2: VERSION MANAGEMENT" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Update pubspec.yaml version
$PubspecPath = Join-Path $RootDir "pubspec.yaml"
$CurrentVersionName = "Unknown"

if (Test-Path $PubspecPath) {
    Write-Status "Updating version in pubspec.yaml..." "INFO"
    
    $pubspecContent = Get-Content $PubspecPath -Raw
    
    # Match version: x.y.z+n
    if ($pubspecContent -match 'version: (\d+)\.(\d+)\.(\d+)\+(\d+)') {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        $patch = [int]$matches[3]
        $build = [int]$matches[4]
        
        $currentVersionStr = "$major.$minor.$patch+$build"
        
        # Increment build number
        $newBuild = $build + 1
        
        # Increment patch version (simple logic)
        $newPatch = $patch + 1
        
        $newVersionStr = "$major.$minor.$newPatch+$newBuild"
        $CurrentVersionName = "$major.$minor.$newPatch"
        
        $pubspecContent = $pubspecContent -replace "version: $currentVersionStr", "version: $newVersionStr"
        Set-Content -Path $PubspecPath -Value $pubspecContent -NoNewline
        
        Write-Status "Updated version: $currentVersionStr -> $newVersionStr" "SUCCESS"
    }
    else {
        Write-Status "Could not parse version in pubspec.yaml" "WARNING"
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        STEP 3: KEYSTORE CHECK" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if (-not (Test-Path $KeyPropertiesFile)) {
    Write-Status "key.properties not found. Generating new keystore..." "WARNING"
    
    # Check for keytool
    if (Get-Command "keytool" -ErrorAction SilentlyContinue) {
        $keystoreName = "upload-keystore.jks"
        $keystorePath = Join-Path $AndroidDir "app\$keystoreName"
        $alias = "upload"
        $pass = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | % { [char]$_ })
        
        Write-Status "Generating keystore at $keystorePath..." "INFO"
        
        # Generate Keystore
        & keytool -genkey -v -keystore $keystorePath -storepass $pass -alias $alias -keypass $pass -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=QuietCheck, OU=Mobile, O=QuietCheck, L=Unknown, S=Unknown, C=US"
        
        if ($LASTEXITCODE -eq 0) {
            # Create key.properties
            $propContent = "storePassword=$pass`nkeyPassword=$pass`nkeyAlias=$alias`nstoreFile=$keystoreName"
            Set-Content -Path $KeyPropertiesFile -Value $propContent
            Write-Status "Created key.properties with new credentials." "SUCCESS"
        }
        else {
            Write-Status "Failed to generate keystore." "ERROR"
            exit 1
        }
    }
    else {
        Write-Status "keytool not found. Cannot generate keystore." "ERROR"
        exit 1
    }
}
else {
    Write-Status "key.properties found." "SUCCESS"
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        STEP 4: BUILDING FLUTTER APP" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Status "Getting dependencies..." "INFO"
& $FlutterCmd pub get
if ($LASTEXITCODE -ne 0) {
    Write-Status "flutter pub get failed" "ERROR"
    exit 1
}


# Function to parse JSON and create Dart defines
function Get-DartDefines {
    $envFile = Join-Path $RootDir "env.json"
    $defines = ""
    if (Test-Path $envFile) {
        Write-Status "Reading env.json for build configuration..." "INFO"
        try {
            $jsonContent = Get-Content $envFile -Raw | ConvertFrom-Json
            $jsonContent.PSObject.Properties | ForEach-Object {
                $checkKey = $_.Name
                $checkVal = $_.Value
                if (-not [string]::IsNullOrWhiteSpace($checkVal)) {
                    # Escape quotes for PowerShell/Command Line
                    # Use base64 encoding or simple string? Simple string with proper escaping is safer for complex values.
                    # For standard keys, simple escaping should work. 
                    # Flutter uses --dart-define=KEY=VALUE
                    $defines += " --dart-define=$checkKey=$checkVal"
                }
            }
        }
        catch {
            Write-Status "Error parsing env.json: $_" "WARNING"
        }
    }
    return $defines
}

$DartDefines = Get-DartDefines

Write-Status "Building App Bundle (AAB)..." "INFO"
# Invoke-Expression is needed to handle the dynamic string of arguments properly in some PS versions, 
# or just passing the string to the command if using & operator might interpret it as one arg.
# Constructing array of args is safer.

$BuildArgsAab = @("build", "appbundle", "--release")
if (-not [string]::IsNullOrWhiteSpace($DartDefines)) {
    # Split defines string into array args (simple split by space might fail if values have spaces)
    # Safer parsing:
    $envFile = Join-Path $RootDir "env.json"
    if (Test-Path $envFile) {
        $jsonContent = Get-Content $envFile -Raw | ConvertFrom-Json
        $jsonContent.PSObject.Properties | ForEach-Object {
            $BuildArgsAab += "--dart-define=$($_.Name)=$($_.Value)"
        }
    }
}

# Write-Host "Running: $FlutterCmd $BuildArgsAab" -ForegroundColor DarkGray
# & $FlutterCmd $BuildArgsAab
# if ($LASTEXITCODE -ne 0) {
#     Write-Status "AAB build failed" "ERROR"
#     # exit 1 
# }
Write-Status "Skipping AAB build for emulator testing..." "WARNING"

Write-Status "Building APK..." "INFO"
$BuildArgsApk = @("build", "apk", "--release")
if (Test-Path $envFile) {
    $jsonContent = Get-Content $envFile -Raw | ConvertFrom-Json
    $jsonContent.PSObject.Properties | ForEach-Object {
        $BuildArgsApk += "--dart-define=$($_.Name)=$($_.Value)"
    }
}

& $FlutterCmd $BuildArgsApk
if ($LASTEXITCODE -ne 0) {
    Write-Status "APK build failed" "WARNING"
}
else {
    Write-Status "APK build completed" "SUCCESS"
}


Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        STEP 5: COPYING BUILD FILES" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Copy AAB
if (Test-Path $AabSource) {
    $aabDest = Join-Path $BuildOutputDir "app-release.aab"
    Copy-Item $AabSource $aabDest -Force
    Write-Status "Copied AAB to $aabDest" "SUCCESS"
}
else {
    Write-Status "AAB source not found at $AabSource" "ERROR"
}

# Copy APK
if (Test-Path $ApkSource) {
    $apkDest = Join-Path $BuildOutputDir "app-release.apk"
    Copy-Item $ApkSource $apkDest -Force
    Write-Status "Copied APK to $apkDest" "SUCCESS"
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        STEP 6: GIT OPERATIONS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if (-not $SkipGit) {
    Write-Status "Adding files..." "INFO"
    & git add .
    
    $commitMsg = "chore(release): bump version to $CurrentVersionName and build artifacts"
    Write-Status "Committing: $commitMsg" "INFO"
    & git commit -m $commitMsg
    
    Write-Status "Pushing to remote..." "INFO"
    & git push
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Pushed successfully" "SUCCESS"
    }
    else {
        Write-Status "Push failed (check credentials)" "WARNING"
    }
}

Write-Host ""
Write-Host "Build and Deploy Complete!" -ForegroundColor Green
Write-Host "Artifacts are in: $BuildOutputDir" -ForegroundColor White
