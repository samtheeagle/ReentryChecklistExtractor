#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy ByPass
#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Default

# Locate the Steam install folder
$Is64Bit = ($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
$SteamRegistryKey = ("HKLM:\SOFTWARE\Valve\Steam", "HKLM:\SOFTWARE\Wow6432Node\Valve\Steam")[$Is64Bit -eq "True"]
$SteamInstallFolder = (Get-ItemPropertyValue -Path $SteamRegistryKey -Name InstallPath)

# Find the path to the users Desktop
$DesktopPath = [Environment]::GetFolderPath("Desktop")

# Define where the default checklist definitions can be found
$DefaultChecklistPath = "$SteamInstallFolder\steamapps\common\Reentry - An Orbital Simulator\ReEntry_Data\StreamingAssets\DefaultChecklists"

# Helpers to make file paths legal
$InvalidPathChars = [IO.Path]::GetInvalidFileNameChars() -join ''
$InvalidPathCharsRegEx = "[{0}]" -f [RegEx]::Escape($InvalidPathChars)

function ParseJsonChecklists {
    param (
        $Spacecraft
    )

    # Where the generated checklist text documents will be saved
    $OutputPath = "$DesktopPath\Reentry Checklists\$Spacecraft"
    
    # Ensure that the output directory exists
    New-Item -ItemType Directory -Force -Path $OutputPath

    # Delete any previously generated text and csv files
    Get-ChildItem -Path $OutputPath -Include *.txt,*.csv -File -Recurse | foreach { $_.Delete()}

    # Create a simple header for the checklist csv
    "Priority, Group, Name" | Out-File -FilePath "$OutputPath\_Checklists.csv"

    # Locate all the json files in the specified spacecraft folder
    $Files = Get-ChildItem "$DefaultChecklistPath\$Spacecraft\*\*.json"
    foreach ($File in $Files) {
        # Load the json content
        $ChecklistJson = $File | Get-Content -Encoding UTF8 | ConvertFrom-Json

        # Extract and tweak values we care about
        $JsonPriorityValue = $ChecklistJson.SortPriority.ToString().PadLeft(9, "0")
        $JsonGroupValue = $ChecklistJson.Group -replace $InvalidPathCharsRegEx
        $JsonNameValue = $ChecklistJson.Name -replace $InvalidPathCharsRegEx

        # Save the checklist text to a txt file, named using the values tweaked above
        $($ChecklistJson.checklistText -replace "<size=\d+>", "" -replace "</size>", "").TrimEnd() | Out-File -FilePath "$OutputPath\$($JsonPriorityValue) - $($JsonGroupValue) - $($JsonNameValue).txt"
    
        # Record the checklist entry in the csv file
        Add-Content -Path "$OutputPath\_Checklists.csv" -Value "$($JsonPriorityValue), $($JsonGroupValue), $($JsonNameValue)"
    }

    # Load the full checklist log csv data and sort it by priority
    $Csv = Import-Csv -delimiter ',' -Encoding UTF8 "$OutputPath\_Checklists.csv" | Sort-Object { [int]$_.Priority }
    # Save the sorted csv data
    $Csv | Export-Csv -Encoding UTF8 -Path "$OutputPath\_SortedChecklists.csv" -NoTypeInformation

    # Iterate over all the checklist text files and create a combined document, sorted in priority order by the file naming
    $Files = Get-ChildItem $OutputPath -Filter "*.txt"
    # Create an empty file to append all the checklists into
    Out-File -FilePath "$OutputPath\_CombinedChecklists.txt"
    foreach ($File in $Files) {
        Add-Content -Path "$OutputPath\_CombinedChecklists.txt" -Value $($File | Get-Content -Encoding UTF8)
        # Add the formfeed control character to create page breaks between checklists if the document is opened in something like Word
        Add-Content -Path "$OutputPath\_CombinedChecklists.txt" -Value "`f"
    }
}

ParseJsonChecklists("CommandModule")
ParseJsonChecklists("Gemini")
ParseJsonChecklists("LunarModule")
ParseJsonChecklists("Mercury")
ParseJsonChecklists("Vostok")
