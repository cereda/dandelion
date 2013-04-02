@echo off

rem Makefile for LaTeX3 "dandelion" files

  if not [%1] == [] goto init

:help

  echo.
  echo  make clean          - clean out directory
  echo  make doc [show]     - typeset all dtx files
  echo  make localinstall   - locally install package
  echo  make unpack [show]  - extract modules
  echo.
  echo  The "show" option enables display of the output
  echo  of the TeX runs in the terminal.

  goto :EOF
  
:init

  rem Avoid clobbering anyone else's variables

  setlocal

  rem Safety precaution against awkward paths

  cd /d "%~dp0"

  rem The name of the module

  set MODULE=dandelion
  
  rem Unpacking information
 
  set UNPACK=%MODULE%.ins

  rem Clean up settings

  set AUXFILES=aux glo hd idx ilg ind log out
  set CLEAN=gz pdf sty zip

  rem Local installation settings

  set INSTALLDIR=latex\%MODULE%
  set INSTALLFILES=*.lua *.sty
  
  rem Documentation typesetting set up

  set TYPESETEXE=pdflatex -interaction=nonstopmode
  
  rem Set up redirection of output

  set REDIRECT=^> nul
  if not [%2] == [] (
    if /i [%2] == [show] (
      set REDIRECT=
    )
  )
  
:main

  rem Cross-compatibility with *nix
  
  if /i [%1] == [-s] shift

  if /i [%1] == [clean]        goto clean
  if /i [%1] == [doc]          goto doc
  if /i [%1] == [localinstall] goto localinstall
  if /i [%1] == [unpack]       goto unpack

  goto help

:clean

  for %%I in (%CLEAN%) do (
    if exist *.%%I del /q *.%%I
  )
  
:clean-int

  for %%I in (%AUXFILES%) do (
    if exist *.%%I del /q *.%%I
  )

  goto end
  
:doc

  echo.
  echo Typesetting

  for %%I in (*.dtx) do (
    echo   %%I
    %TYPESETEXE% -draftmode %%I %REDIRECT%
    if ERRORLEVEL 1 (
      echo   ! Compilation failed
    ) else (
      if exist %%~nI.idx (
        makeindex -q -s l3doc.ist -o %%~nI.ind %%~nI.idx > nul
      )
      %TYPESETEXE% %%I %REDIRECT%
      %TYPESETEXE% %%I %REDIRECT%
    )
  )

  goto clean-int
  
:localinstall

  call :unpack

  echo.
  echo Installing %MODULE%

  rem Find local root if possible

  if not defined TEXMFHOME (
    for /f "delims=" %%I in ('kpsewhich --var-value=TEXMFHOME') do @set TEXMFHOME=%%I
    if "%TEXMFHOME%" == "" (
      set TEXMFHOME=%USERPROFILE%\texmf
    )
  )

  set INSTALLROOT=%TEXMFHOME%\tex\%INSTALLDIR%

  if exist "%INSTALLROOT%\*.*" rmdir /q /s "%INSTALLROOT%"
  mkdir "%INSTALLROOT%"

  for %%I in (%INSTALLFILES%) do (
    copy /y %%I "%INSTALLROOT%" > nul
  )

  goto clean-int
  
:unpack

  for %%I in (%UNPACK%) do (
    tex %%I %REDIRECT%
  )

  goto end

:end

  rem If something like "make check show" was used, remove the "show"

  if /i [%2] == [show] shift

  shift
  if not [%1] == [] goto main