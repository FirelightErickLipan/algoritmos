@echo off
REM ============================================================
REM  Inicia el componente local que abre MATLAB y luego la app.
REM  Haz doble clic en este archivo (o ejecutalo desde la carpeta
REM  del proyecto). Al cerrar la app, el componente se detiene solo.
REM ============================================================
cd /d "%~dp0"

echo Iniciando componente MATLAB...
start "Puente MATLAB" /min cmd /c "dart run tool\matlab_helper.dart"

echo Iniciando la aplicacion en Chrome...
flutter run -d chrome

echo Cerrando componente MATLAB...
taskkill /FI "WINDOWTITLE eq Puente MATLAB*" /T /F >nul 2>&1
