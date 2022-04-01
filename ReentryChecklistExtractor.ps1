#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy ByPass
#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Default

Set-Variable DefaultChecklistPath -value "E:\Steam\steamapps\common\Reentry - An Orbital Simulator\ReEntry_Data\StreamingAssets\DefaultChecklists"

Get-ChildItem -Path "$DefaultChecklistPath\CommandModule" -Directory | ForEach-Object {
    $_.FullName
    Set-Variable ChecklistJsonFile -value (Get-ChildItem -Path $_.FullName -Filter *.json | Select-Object -First 1)   
    Set-Variable ChecklistJson -value $ChecklistJsonFile | Get-Content -Encoding UTF8 | ConvertFrom-Json
    $ChecklistJson.checklistText -replace "<size=21>", "" -replace "</size>", "" | Out-File -FilePath "C:\Users\samth\Desktop\Reentry Checklists\$($ChecklistJson.Group) - $($ChecklistJson.Name).txt"
}