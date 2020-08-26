Remove-Item EasyRollTracker-v*.zip
Remove-Item EasyRollTracker-v*.7z
$PATH_7Z = "C:/Program Files/7-Zip"
&"$PATH_7Z/7z.exe" a -tzip -mmt -mx9 -r EasyRollTracker-vX.X.zip EasyRollTracker\
&"$PATH_7Z/7z.exe" a -t7z -mmt -mx9 -r EasyRollTracker-vX.X.7z EasyRollTracker\
