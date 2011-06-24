﻿New-Canvas -Width 400 -Height 400 -Background {
    New-LinearGradientBrush -SpreadMethod Pad -StartPoint "0,0" -EndPoint "0,.9" { 
        New-GradientStop -Color "Red" -Offset .1
        New-GradientStop -Color "White" -Offset .4
        New-GradientStop -Color "Green" -Offset .9
    }
} -show