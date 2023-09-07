@echo off

echo.

set id=150455514

echo WORKSHOP ID IS %id%

echo.
echo Creating GMA
"D:\Games_Steam\steamapps\common\GarrysMod\bin\gmad.exe" create -folder %cd% -out %id%.gma

echo.
echo Uploading GMA
"D:\Games_Steam\steamapps\common\GarrysMod\bin\gmpublish.exe" update -addon %id%.gma -id %id%

echo.
echo Deleting GMA
del %id%.gma

pause