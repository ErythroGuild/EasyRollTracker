# Remove old packages
Remove-Item "EasyRollTracker-v*.zip"
Remove-Item "EasyRollTracker-v*.7z"

# Fetch version number
$VERSION = "X.X"
foreach ($line in Get-Content "EasyRollTracker/EasyRollTracker.toc") {
	if ($line -match "^## Version: (\d+\.\d+\.\d+)") {
		$VERSION = $Matches[1]
		break
	}
}

# Trim patch number
if ($VERSION -match "(\d+\.\d+)\.0") {
	$VERSION = $Matches[1]
}

# Copy license file into package
Copy-Item "License.md" -Destination "EasyRollTracker/License.md"

# Copy acknowledgements into package
Copy-Item "Acknowledgements.md" -Destination "EasyRollTracker/Acknowledgements.md"

# Create new packages
$PATH_7Z = "C:/Program Files/7-Zip"
&"$PATH_7Z/7z.exe" a -tzip -mmt -mx9 -r "EasyRollTracker-v$VERSION.zip" "EasyRollTracker/"
&"$PATH_7Z/7z.exe" a -t7z -mmt -mx9 -r "EasyRollTracker-v$VERSION.7z" "EasyRollTracker/"

# Cleanup license file
Remove-Item "EasyRollTracker/License.md"

# Cleanup acknowledgements file
Remove-Item "EasyRollTracker/Acknowledgements.md"
