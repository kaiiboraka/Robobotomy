@echo off
echo Deleting Godot editor cache files and mono temp directory...

REM Delete filesystem_cache10 and filesystem_update4 from .godot/editor/
del ".godot\editor\filesystem_cache10" 2>nul
del ".godot\editor\filesystem_update4" 2>nul

REM Delete the .godot/mono/temp directory
rmdir /S /Q ".godot\mono\temp" 2>nul

echo Deletion process complete.
pause