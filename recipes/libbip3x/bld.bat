@echo off

set "build_dir=%SRC_DIR%\build-release"
set "pre_install_dir=%SRC_DIR%\pre-install"
set "test_release_dir=%SRC_DIR%\test-release"

:: Build and install
mkdir %build_dir%
mkdir %pre_install_dir%

cd %build_dir%
  set "_install_dir=%pre_install_dir:\=\\%"
  cmake %CMAKE_ARGS% ^
    -G "Ninja" ^
    -D CMAKE_BUILD_TYPE=Release ^
    -D CMAKE_INSTALL_PREFIX="%_install_dir%" ^
    -D CMAKE_VERBOSE_MAKEFILE=ON ^
    -D bip3x_BUILD_SHARED_LIBS=ON ^
    -D bip3x_BUILD_JNI_BINDINGS=ON ^
    -D bip3x_BUILD_C_BINDINGS=ON ^
    -D bip3x_USE_OPENSSL_RANDOM=ON ^
    -D bip3x_BUILD_TESTS=ON ^
    %SRC_DIR%
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

  cmake --build . --config Release
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

  cmake --install . --config Release
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
cd %SRC_DIR%

:: Remove 'toolbox' files
powershell -Command "& { Get-ChildItem -Path '%pre_install_dir%' -Recurse -Filter '*toolbox*' | Remove-Item -Force -Recurse }"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Prepare test area
powershell -Command "& { New-Item -Path '%test_release_dir%' -ItemType Directory -Force | Out-Null }"
powershell -Command "& { Copy-Item -Path (Join-Path '%build_dir%' 'bin') -Destination '%test_release_dir%' -Recurse }"
powershell -Command "& {
    Get-ChildItem -Path '.\*' -Recurse |
    Where-Object {
        -not ($_.FullName -match 'GTest' -or $_.FullName -match 'gtest')
    } |
    Copy-Item -Destination $ENV:PREFIX -Recurse -Force -PassThru |
    Select-Object -ExpandProperty FullName
}"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: CMake was patched to create versionned windows DLLs, but the side-effect is that it creates bip3x.3.lib as well
:: Converting bip3x.3.lib to bip3x.lib. It will still refer to bip3x.3.dll, but that should be fine.
powershell -Command "& { Get-ChildItem -Path '%pre_install_dir%' -Recurse -Filter 'bip3x.3.lib' | Rename-Item -NewName { $_.Name -replace 'bip3x.3.lib', 'bip3x.lib' } }"

:: Transfer pre-install to PREFIX
cd "%pre_install_dir%"
powershell -Command "& { Copy-Item -Path '.\*' -Destination $ENV:PREFIX -Recurse -Force -PassThru | Select-Object -ExpandProperty FullName }"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

cd "%SRC_DIR%"
