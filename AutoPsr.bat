@echo off
setlocal enabledelayedexpansion

rem ---定数定義---

rem psr.exeのパス
set PSR_PATH=%systemroot%\system32\psr.exe

rem psr.exeの一時画像保存先
set PSR_TMP_SAVE_PATH=%userprofile%\appdata\local\microsoft\

rem 画像の保存数(min:1 max:100)
set MAX_SAVE_NUM=100

rem 出力ファイル保存先
set SAVE_FILE_PATH=%userprofile%\desktop\

rem 出力ファイル保存名
set SAVE_FILE_NAME=capture.zip

rem 検知間隔
set INTERVAL=3

rem いったん出力を行う画像の枚数の閾値
set OUTPUT_NUM=5

set COPY_IMAGES_FUNC_PATH=%tmp%\copyImagesfunc.bat
set AUTO_PSR_PROCESS_MONITOR_PATH=%tmp%\autoPsrProcessMonitor.bat
rem set FUNC_BAT_PATH=%userprofile%\desktop\func.bat

set EXEC_SLEEP_TIME=3

rem -------------

rem 既存ファイル検索の不具合修正
rem Win8.1環境でのキャプチャ数検知の不具合修正
rem ctrl+cでの強制終了時の出力不具合修正
rem msgの表示先を接続ユーザのみに変更
rem autoPsrProcessMonitorのゴミ削除
rem 
rem 
rem 
rem 
rem 
rem 
rem 
rem 
rem 
rem 
rem 

rem ---本処理---

echo.
echo ******* AutoPsr *********
echo *  Version 0.2.0        *
echo *  Updated 2014/11/19   *
echo *************************
echo.
echo *********************************** CAUTION ************************************
echo * 1. バッチを終了させる際はctrl+cで強制終了させて下さい。                      *
echo * 2. 同時に起動している"AutoPsrProcessMonitor"は絶対に終了させないで下さい。   *
echo * 3. 万が一終了させてしまった場合は、別途"psr /stop"コマンドを実行して下さい。 *
echo ********************************************************************************
echo.

set rand=%random%

set title=AutoPsr_%random%

title %title%

set pipe=^^^|

call :checkOs
call :exportFunc

set /a prefixCnt=1
set lastNum=1
set pid=
set existsZipFileFlag=false
set existsImgFileFlag=false
set /a existsZipFileNum=0


for /F "delims=," %%a in ('dir /B /OD !SAVE_FILE_PATH! ^| findstr .*__!SAVE_FILE_NAME!') do (
		set str=%%~nxa
		set /a existsZipFileNum=!str:__capture.zip=!
		set existsZipFileFlag=true
)

if exist !SAVE_FILE_PATH!images (
	for /F "delims=," %%a in ('dir /B /OD !SAVE_FILE_PATH!images ^| findstr .*\.jpg$') do (
			set str=%%~na
			set /a existsImgFileNum=!str!
			set existsImgFileFlag=true
	)
)

if !existsZipFileFlag! == true set /a prefixCnt=!existsZipFileNum!+1
if !existsImgFileFlag! == true set /a lastNum=!existsImgFileNum!+1

start "AutoPsrProcessMonitor" /min %AUTO_PSR_PROCESS_MONITOR_PATH% !lastNum!

if not "%1" == "" call :searchPid %1
if errorlevel 1 set pid=!errorlevel!

call :startPsrFunc !prefixCnt! !pid!
if errorlevel 1 echo ERROR & pause & exit

for /l %%I in (0, 0, 0) do (
	set cnt=0

	for /F "delims=," %%a in ('dir /B /S !PSR_TMP_SAVE_PATH! ^| findstr screenshot') do (
		set /a cnt+=1
	)
	
	echo Captured Images Count : !cnt!
	
	if !cnt! geq !OUTPUT_NUM! (
		echo 撮影済み画像キャプチャ数が!OUTPUT_NUM!枚を超えました。現在、!cnt!枚撮影済みです。一旦zipファイル出力を行います。数秒作業を停止してください。| msg %username% /time:3

		call %COPY_IMAGES_FUNC_PATH% !lastNum!
		if !errorlevel! neq 2147483647 ( 
			rem echo CopiedImagesCount : !errorlevel!
			set /a lastNum=!errorlevel!
		

			for /F "tokens=2" %%a in ('tasklist /v ^| findstr "AutoPsrProcessMonitor"') do (
				taskkill /PID %%a /F
			)
			
			!PSR_PATH! /stop
			echo Generated File : !SAVE_FILE_PATH!!prefixCnt!__!SAVE_FILE_NAME!
			set /a prefixCnt=prefixCnt+1
			call :startPsrFunc !prefixCnt! !pid!
			if errorlevel 1 echo ERROR & pause & exit
			start "AutoPsrProcessMonitor" /min %AUTO_PSR_PROCESS_MONITOR_PATH% !lastNum!
			
		) else (
			echo ERROR & pause & exit
		)
	)

	timeout /t !INTERVAL! /nobreak > nul
)

endlocal

exit

rem -----------


rem ---サブルーチン---

:checkOs
	ver | find "Version 6.1." > nul
	if not errorlevel 1 set PSR_TMP_SAVE_PATH=%PSR_TMP_SAVE_PATH%uar

	ver | find "Version 6.2." > nul
	IF not errorlevel 1 set PSR_TMP_SAVE_PATH=%PSR_TMP_SAVE_PATH%uir

	ver | find "Version 6.3." > nul
	IF not errorlevel 1 set PSR_TMP_SAVE_PATH=%PSR_TMP_SAVE_PATH%uir

	ver | find "Version 10.0." > nul
	IF not errorlevel 1 set PSR_TMP_SAVE_PATH=%PSR_TMP_SAVE_PATH%uir

	exit /b 0

:searchPid
	echo Arg 1. %1
	echo Exec to %1...
	echo.
	start "" %1
	timeout %EXEC_SLEEP_TIME%
	
	set name=%~n1

	for /F "tokens=2" %%a in ('tasklist /v ^| findstr /i !name!') do (
		echo Execed App PID is %%a
		exit /b %%a
	)
)

:startPsrFunc
	if not "%1" == "" (
		set /a numChk=%1*1
		if "%1" == "!numChk!" (
			if not "%2" == "" (
				set /a numChk=%2*1
				if "%2" == "!numChk!" (
					start "" !PSR_PATH! /start /output !SAVE_FILE_PATH!%1__!SAVE_FILE_NAME! /maxsc !MAX_SAVE_NUM! /gui 0 /recordpid %2
				) else ( exit /b 1 )
			) else (
				start "" !PSR_PATH! /start /output !SAVE_FILE_PATH!%1__!SAVE_FILE_NAME! /maxsc !MAX_SAVE_NUM! /gui 0
			)
			exit /b 0
		) else (
			echo Argument is wrong.
			exit /b 1
		)
	)
	echo There is no argument.
	exit /b 1

:exportFunc

(
	echo @echo off
	echo for /l %%%%I in ^(0, 0, 0^) do ^(
	echo 	tasklist /v ^| findstr %title% ^> nul ^& if errorlevel 1 (
	echo 		call %COPY_IMAGES_FUNC_PATH% %%1 ^& %PSR_PATH% /stop ^&^& del %COPY_IMAGES_FUNC_PATH% ^& start ^"^" cmd /c timeout 1 ^& del %AUTO_PSR_PROCESS_MONITOR_PATH% ^& exit
	echo 	^) else ^(
	echo 		echo Process : %title% is Exists. ^& timeout /t 1 /nobreak ^> nul
	echo 	^)
	echo ^)
) > %AUTO_PSR_PROCESS_MONITOR_PATH%

(
	echo @echo off
	echo setlocal enabledelayedexpansion
	echo set cnt=%%1
	echo echo ^^!cnt^^!

	echo if not exist !SAVE_FILE_PATH!images ^(
	echo mkdir !SAVE_FILE_PATH!images
	echo ^)

	echo for /F ^"delims=,^" %%%%a in ^('dir /B /S !PSR_TMP_SAVE_PATH! !pipe! findstr /i screenshot*.*^\.jpeg$'^) do ^(
	echo echo ^^!cnt^^!
	echo copy %%%%a !SAVE_FILE_PATH!images\^^!cnt^^!.jpg ^> nul
	echo set /a cnt+=1
	echo ^)
	
	echo exit /b ^^!cnt^^!

	echo endlocal


) > %COPY_IMAGES_FUNC_PATH%

exit /b 0


rem ----------- 
