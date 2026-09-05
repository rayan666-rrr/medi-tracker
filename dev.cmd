@echo off
REM ===========================================================================
REM  Medical Tracker BD - one-click "pull the agent's code and run it" script
REM
REM  HOW TO USE (Windows)
REM    1. Open File Explorer, go into the medi-tracker folder.
REM    2. Click in the address bar at the top, type  cmd  and press Enter.
REM       (or just double-click this dev.cmd file)
REM    3. Type:   dev arena/01a07170-medi-tracker   <- first run only
REM       then:  dev                                <- after that, always enough
REM
REM  What it does: fetch -> checkout/create branch -> fast-forward pull ->
REM  npm install if node_modules is missing -> start vite -> open :3000.
REM
REM  It handles the single-branch clone case (clone made with --single-branch,
REM  whose remote.origin.fetch only maps refs/heads/main) by fetching the branch
REM  you name explicitly. That is the #1 reason "git checkout <branch>" fails
REM  with "pathspec did not match" on AI-Studio-made clones.
REM
REM  It NEVER commits, merges, rebases or pushes. Worst case it stops and tells
REM  you why, leaving your working tree exactly as it was.
REM ===========================================================================
setlocal
cd /d "%~dp0"

set "BRANCH=%~1"
if "%BRANCH%"=="" (
  for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%b"
)
echo.
echo  branch: %BRANCH%
echo.

echo [1/4] git fetch origin %BRANCH%
git fetch origin "+refs/heads/%BRANCH%:refs/remotes/origin/%BRANCH%"
if errorlevel 1 goto :gitfail
git fetch origin --prune >nul 2>nul

echo [2/4] checkout
git rev-parse --verify --quiet "refs/heads/%BRANCH%" >nul
if errorlevel 1 (
  git checkout -b "%BRANCH%" "origin/%BRANCH%"
  if errorlevel 1 goto :gitfail
) else (
  for /f "delims=" %%c in ('git rev-parse --abbrev-ref HEAD') do set "CURRENT=%%c"
  if not "%CURRENT%"=="%BRANCH%" (
    git checkout "%BRANCH%"
    if errorlevel 1 goto :gitfail
  ) else (
    echo   already on %BRANCH%
  )
)

echo [3/4] git pull --ff-only origin %BRANCH%
git pull --ff-only origin "%BRANCH%"
if errorlevel 1 goto :pullfail

if not exist "node_modules\" (
  echo [4/4] first run - npm install (this takes a minute)
  call npm install
  if errorlevel 1 goto :npmfail
) else (
  echo [4/4] dependencies already installed, skipping
)

echo.
echo  ============================================
echo   Medical Tracker BD  ^>  http://localhost:3000
echo   stop with  Ctrl+C
echo  ============================================
echo.
start "" http://localhost:3000
call npm run dev
goto :eof

:pullfail
echo.
echo  *** Local edits conflict with the repo, so nothing was changed. ***
echo      see them:   git status
echo      keep them:  git stash
echo      discard:    git checkout -- .
echo  then run "dev" again.
goto :eof

:gitfail
echo.
echo  *** git failed. Check: network, and whether you are still logged in ***
echo      test with:  gh auth status
echo      or:         git ls-remote origin
goto :eof

:npmfail
echo.
echo  *** npm install failed. Try:  npm cache clean --force   then re-run dev ***
goto :eof
