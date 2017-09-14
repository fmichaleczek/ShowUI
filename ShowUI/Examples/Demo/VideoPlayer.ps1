New-Window -AllowDrop -On_Drop {
    $videoPlayer.Source = @($_.Data.GetFileDropList())[0]
    $videoPlayer.Play()
} -On_Loaded {
    $videoPlayer.Source = Get-ChildItem -Path "$env:Public\Videos\Sample Videos" -Filter *.wmv | 
        Get-Random | Select-Object -ExpandProperty Fullname
    $videoPlayer.Play()
} -On_Closing {
    $videoPlayer.Stop()
} -Content {
    New-MediaElement -Name VideoPlayer -LoadedBehavior Manual
} -asjob
