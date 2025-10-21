@echo off
REM mySahara Flutter Web Deployment Script for Windows

echo.
echo ============================================
echo     mySahara Flutter Web Deployment
echo ============================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    pause
    exit /b 1
)

echo [OK] Flutter found
flutter --version | findstr /C:"Flutter"
echo.

REM Clean previous build
echo [INFO] Cleaning previous build...
flutter clean
echo.

REM Get dependencies
echo [INFO] Getting dependencies...
flutter pub get
echo.

REM Build for web
echo [INFO] Building Flutter web in release mode...
flutter build web --release
echo.

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Build successful!
    echo.
    echo Build output: build\web\
    echo.
    
    REM Check if Vercel CLI is installed
    where vercel >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo [INFO] Vercel CLI found!
        echo.
        set /p DEPLOY="Do you want to deploy to Vercel now? (Y/N): "
        if /i "%DEPLOY%"=="Y" (
            echo [INFO] Deploying to Vercel...
            cd build\web
            vercel --prod
            cd ..\..
        ) else (
            echo [INFO] To deploy later, run: cd build\web ^&^& vercel --prod
        )
    ) else (
        echo [INFO] Vercel CLI not found
        echo [INFO] Install with: npm install -g vercel
        echo [INFO] Then deploy with: cd build\web ^&^& vercel --prod
    )
    
    echo.
    echo ============================================
    echo [SUCCESS] Deployment ready!
    echo See FLUTTER_WEB_DEPLOYMENT.md for details
    echo ============================================
) else (
    echo [ERROR] Build failed! Check errors above.
    pause
    exit /b 1
)

echo.
pause
