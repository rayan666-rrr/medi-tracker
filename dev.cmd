@echo off
REM ===========================================================================
REM  Medical Tracker BD - one-click "pull the agent's code and run it" script
REM
REM  HOW TO USE (Windows)
REM    1. Open File Explorer, go into the medi-tracker folder.
REM    2. Click in the address bar at the top, type  cmd  and press Enter.
REM       (or just double-click this dev.cmd file)
REM    3. Type:   dev            <- pulls the branch you are already on
REM       or:    dev arena/01a07170-medi-tracker   <- pulls a specific branch
REM
REM  What it does: fetch -> checkout -> fast-forward pull -> install deps if
REM  node_modules is missing -> start vite -> open http://localhost:3000
REM
REM  It NEVER commits, merges, rebases or pushes. Worst case it stops and tells
REM  you why, leaving your working tree exactly as it was.
REM ===========================================================================
setlocal
cd /d "%~dp0"

set "BRANCH=%~1"

echo.
echo [1/4] git fetch origin
git fetch origin --prune
if errorlevel 1 goto :gitfail

if not "%BRANCH%"=="" (
  echo [2/4] git checkout %BRANCH%
  git checkout "%BRANCH%"
  if errorlevel 1 goto :gitfail
) else (
  for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%b"
  echo [2/4] staying on current branch: %BRANCH%
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
echo  *** git failed - check your internet connection / login. ***
goto :eof

:npmfail
echo.
echo  *** npm install failed. Try:  npm cache clean --force   then re-run dev ***
goto :eof
