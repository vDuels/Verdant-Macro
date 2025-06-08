@echo off
color 0A
title Verdant Macro - Smart Launcher

echo.
echo  ########################################
echo  #     🌿 VERDANT MACRO LAUNCHER       #
echo  #    "One-Click Setup and Launch"     #
echo  ########################################
echo.

cd /d "%~dp0"

echo 📁 Setting up directories...
if not exist "lib" mkdir lib
if not exist "downloads" mkdir downloads
if not exist "config" mkdir config
if not exist "dist" mkdir dist

echo 🔍 Moving any downloaded files to correct locations...
if exist "tesseract*.exe" (
    for %%F in (tesseract*.exe) do (
        echo Moving %%F to downloads folder...
        move "%%F" "downloads\tesseract_ocr_installer.exe" >nul 2>&1
    )
)
if exist "Gdip_All.ahk" move "Gdip_All.ahk" "lib\Gdip_All.ahk" >nul 2>&1
if exist "JSON.ahk" move "JSON.ahk" "lib\JSON.ahk" >nul 2>&1

echo.
echo 🔍 Checking what's installed...

if exist "C:\Program Files\AutoHotkey\AutoHotkey.exe" (
    echo ✅ AutoHotkey: Installed
) else (
    echo ❌ AutoHotkey: Missing
)

if exist "C:\Program Files\Tesseract-OCR\tesseract.exe" (
    echo ✅ Tesseract OCR: Installed
) else (
    echo ❌ Tesseract OCR: Missing
)

if exist "lib\Gdip_All.ahk" (
    echo ✅ Gdip_All.ahk: Found
) else (
    echo ❌ Gdip_All.ahk: Missing
)

if exist "lib\JSON.ahk" (
    echo ✅ JSON.ahk: Found
) else (
    echo ❌ JSON.ahk: Missing
)

if exist "VerdantMacro.ahk" (
    echo ✅ VerdantMacro.ahk: Found
) else (
    echo ❌ VerdantMacro.ahk: Missing
)

echo.
echo ================================================================

REM Check if everything is ready
if exist "C:\Program Files\AutoHotkey\AutoHotkey.exe" (
    if exist "C:\Program Files\Tesseract-OCR\tesseract.exe" (
        if exist "lib\Gdip_All.ahk" (
            if exist "lib\JSON.ahk" (
                if exist "VerdantMacro.ahk" (
                    echo 🎉 ALL READY! Launching Verdant Macro...
                    if exist "VerdantMacro.exe" (
                        start "" "VerdantMacro.exe"
                    ) else (
                        start "" "C:\Program Files\AutoHotkey\AutoHotkey.exe" "VerdantMacro.ahk"
                    )
                    echo ✅ Verdant Macro launched!
                    timeout /t 3 >nul
                    exit
                )
            )
        )
    )
)

echo ⚠️  Some components are missing. Attempting downloads...
echo.

REM Download Tesseract
if not exist "C:\Program Files\Tesseract-OCR\tesseract.exe" (
    if not exist "downloads\tesseract_ocr_installer.exe" (
        echo 📥 Downloading Tesseract OCR...
        powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://github.com/UB-Mannheim/tesseract/releases/download/v5.3.3.20231005/tesseract-ocr-w64-setup-5.3.3.20231005.exe', 'downloads\tesseract_ocr_installer.exe') } catch { Write-Host 'Primary download failed' }"
        
        if exist "downloads\tesseract_ocr_installer.exe" (
            echo ✅ Tesseract installer downloaded
        ) else (
            echo Trying alternative mirror...
            powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $wc = New-Object System.Net.WebClient; $wc.Headers.Add('User-Agent', 'Mozilla/5.0'); $wc.DownloadFile('https://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-w64-setup-5.3.3.20231005.exe', 'downloads\tesseract_ocr_installer.exe') } catch { Write-Host 'Alternative download failed' }"
            
            if exist "downloads\tesseract_ocr_installer.exe" (
                echo ✅ Tesseract downloaded via alternative mirror
            ) else (
                echo ❌ Tesseract download failed from all sources
            )
        )
    )
)

REM Download Gdip_All.ahk
if not exist "lib\Gdip_All.ahk" (
    echo 📥 Downloading Gdip_All.ahk...
    powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/mmikeww/AHKv1-Gdip/master/Gdip_All.ahk', 'lib\Gdip_All.ahk') } catch { Write-Host 'Primary download failed' }"
    
    if exist "lib\Gdip_All.ahk" (
        echo ✅ Gdip_All.ahk downloaded
    ) else (
        echo Trying CDN mirror...
        powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $wc = New-Object System.Net.WebClient; $wc.Headers.Add('User-Agent', 'Mozilla/5.0'); $wc.DownloadFile('https://cdn.jsdelivr.net/gh/mmikeww/AHKv1-Gdip@master/Gdip_All.ahk', 'lib\Gdip_All.ahk') } catch { Write-Host 'CDN download failed' }"
        
        if exist "lib\Gdip_All.ahk" (
            echo ✅ Gdip_All.ahk downloaded via CDN
        ) else (
            echo ❌ Gdip_All.ahk download failed from all sources
        )
    )
)

REM Download JSON.ahk
if not exist "lib\JSON.ahk" (
    echo 📥 Downloading JSON.ahk...
    powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/cocobelgica/AutoHotkey-JSON/master/JSON.ahk', 'lib\JSON.ahk') } catch { Write-Host 'JSON download failed' }"
    if exist "lib\JSON.ahk" (
        echo ✅ JSON.ahk downloaded
    ) else (
        echo ❌ JSON.ahk download failed
    )
)

echo.
echo 🔧 Installing downloaded components...

REM Install Tesseract
if exist "downloads\tesseract_ocr_installer.exe" (
    if not exist "C:\Program Files\Tesseract-OCR\tesseract.exe" (
        echo Installing Tesseract OCR...
        start /wait "downloads\tesseract_ocr_installer.exe"
        echo ✅ Tesseract installation finished
        
        REM Check if it installed successfully and everything is ready
        if exist "C:\Program Files\Tesseract-OCR\tesseract.exe" (
            if exist "C:\Program Files\AutoHotkey\AutoHotkey.exe" (
                if exist "lib\Gdip_All.ahk" (
                    if exist "lib\JSON.ahk" (
                        if exist "VerdantMacro.ahk" (
                            echo.
                            echo 🎉 ALL COMPONENTS NOW READY! Auto-launching...
                            if exist "VerdantMacro.exe" (
                                start "" "VerdantMacro.exe"
                            ) else (
                                start "" "C:\Program Files\AutoHotkey\AutoHotkey.exe" "VerdantMacro.ahk"
                            )
                            echo ✅ Verdant Macro launched!
                            timeout /t 3 >nul
                            exit
                        )
                    )
                )
            )
        )
    )
)

echo.
echo ================================================================
echo                    MANUAL DOWNLOAD LINKS
echo ================================================================
echo.

if not exist "C:\Program Files\Tesseract-OCR\tesseract.exe" (
    echo ❌ Tesseract OCR:
    echo    https://github.com/UB-Mannheim/tesseract/releases/tag/v5.3.3.20231005
    echo    Download: tesseract-ocr-w64-setup-5.3.3.20231005.exe
    echo    Save to: downloads folder
    echo.
)

if not exist "lib\Gdip_All.ahk" (
    echo ❌ Gdip_All.ahk:
    echo    https://raw.githubusercontent.com/mmikeww/AHKv1-Gdip/master/Gdip_All.ahk
    echo    Save to: lib folder
    echo.
)

if not exist "lib\JSON.ahk" (
    echo ❌ JSON.ahk:
    echo    https://raw.githubusercontent.com/cocobelgica/AutoHotkey-JSON/master/JSON.ahk
    echo    Save to: lib folder
    echo.
)

echo 🔄 Run this script again after downloading missing files
echo 🌿 Ready to cultivate success automatically!
echo.

pause