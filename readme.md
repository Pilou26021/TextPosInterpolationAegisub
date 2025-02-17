# Text & Position Interpolation for Aegisub

## PLEASE REPORT BUGS YOU ENCOUNTER
### Version : v1.0

What do I need to use this?
Was made on Aegisub 3.2.x, may work on different versions.

How do I install it?
The recommended method is to use DependencyControl.

Installing with DependencyControl
1. Download the latest version of DependencyControl
2. Download the lua file from the releases page
3. Open Aegisub and go to `Automation -> Automation -> Add` and select the downloaded file
4. Click `Apply`
5. You're done!

How do I use this?
1. Select the two lines (start and end) you want to interpolate
2. Go to `Automation -> Text & Position Interpolation`
3. Select the interpolation type (for now only `Linear` is available) 
4. Choose the number of frames (steps) you want to interpolate
5. Click `OK` and you're done!
6. You can undo the interpolation with `Ctrl + Z`

What does it do?
It interpolates the text and position of the selected lines. The interpolation is done in a linear way, meaning that the text and position will change gradually over the number of frames you choose.


## Changelog
### v1.0
- Initial release
- Linear interpolation