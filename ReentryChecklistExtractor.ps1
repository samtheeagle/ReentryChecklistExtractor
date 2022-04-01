#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy ByPass
#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Default

$DefaultChecklistPath = "E:\Steam\steamapps\common\Reentry - An Orbital Simulator\ReEntry_Data\StreamingAssets\DefaultChecklists"
$OutputPath = "C:\Users\samth\Desktop\Reentry Checklists"

$InvalidPathChars = [IO.Path]::GetInvalidFileNameChars() -join ''
$InvalidPathCharsRegEx = "[{0}]" -f [RegEx]::Escape($InvalidPathChars)

Get-ChildItem -Path $OutputPath -Include * -File -Recurse | foreach { $_.Delete()}
Out-File -FilePath "$OutputPath\CombinedChecklists.txt"
"Priority, Group, Name" | Out-File -FilePath "$OutputPath\_Checklists.csv"

$Files = Get-ChildItem "$DefaultChecklistPath\CommandModule\*\*.json"
foreach ($File in $Files) {
    $ChecklistJson = $File | Get-Content -Encoding UTF8 | ConvertFrom-Json

    $JsonPriorityValue = $ChecklistJson.SortPriority.ToString().PadLeft(9, "0")
    $JsonGroupValue = $ChecklistJson.Group -replace $InvalidPathCharsRegEx
    $JsonNameValue = $ChecklistJson.Name -replace $InvalidPathCharsRegEx

    $($ChecklistJson.checklistText -replace "<size=21>", "" -replace "</size>", "").TrimEnd() | Out-File -FilePath "$OutputPath\$($JsonPriorityValue) - $($JsonGroupValue) - $($JsonNameValue).txt"
    Add-Content -Path "$OutputPath\_Checklists.csv" -Value "$($JsonPriorityValue), $($JsonGroupValue), $($JsonNameValue)"
}

$Csv = Import-Csv -delimiter ',' -Encoding UTF8 "$OutputPath\_Checklists.csv" | Sort-Object { [int]$_.Priority }
$Csv | Export-Csv -Encoding UTF8 -Path "$OutputPath\_SortedChecklists.csv" -NoTypeInformation

$Files = Get-ChildItem $OutputPath -Filter "*.txt"
foreach ($File in $Files) {
    Add-Content -Path "$OutputPath\CombinedChecklists.txt" -Value $($File | Get-Content -Encoding UTF8)
    Add-Content -Path "$OutputPath\CombinedChecklists.txt" -Value "`f"
}
