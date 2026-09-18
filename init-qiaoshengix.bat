@echo off
setlocal
pushd "%~dp0" || exit /b 1
where git >nul 2>&1 || goto :fail
if not exist "pubspec.yaml" goto :fail
if not exist "lib\main.dart" goto :fail
if not exist ".git" (
    git init -b main || goto :fail
)
git config --local user.name "qiaoshengix" || goto :fail
git config --local user.email "qiaoshengix@outlook.com" || goto :fail
set "GIT_AUTHOR_NAME=qiaoshengix"
set "GIT_AUTHOR_EMAIL=qiaoshengix@outlook.com"
set "GIT_COMMITTER_NAME=qiaoshengix"
set "GIT_COMMITTER_EMAIL=qiaoshengix@outlook.com"
git rev-parse --verify HEAD >nul 2>&1
if not errorlevel 1 goto :verify
git status --short || goto :fail
git diff || goto :fail
git add -- .gitattributes .gitignore .metadata README.md analysis_options.yaml devtools_options.yaml pubspec.yaml pubspec.lock android assets config lib test docs init-qiaoshengix.bat || goto :fail
git diff --cached --stat || goto :fail
git commit -m "feat: initialize LumiTrail standalone app" || goto :fail
:verify
powershell -NoProfile -Command "$expected = 'qiaoshengix|qiaoshengix@outlook.com|qiaoshengix|qiaoshengix@outlook.com'; $rows = @(git log --all '--format=%%an|%%ae|%%cn|%%ce'); if ($LASTEXITCODE -ne 0 -or $rows.Count -eq 0) { exit 1 }; foreach ($row in $rows) { if ($row -cne $expected) { Write-Error 'Unexpected commit identity; history was not rewritten.'; exit 1 } }" || goto :fail
git log --oneline -10 || goto :fail
echo Ready. All current commits belong to qiaoshengix. Nothing was pushed.
popd
exit /b 0
:fail
echo Initialization or identity verification failed. Nothing was pushed.
popd
exit /b 1
