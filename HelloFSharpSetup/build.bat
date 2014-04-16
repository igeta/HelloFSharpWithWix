cd /d %~dp0

set wix=C:\Program Files (x86)\WiX Toolset v3.8\bin

"%wix%\candle.exe" Product.wxs -out obj\Release\Product.wixobj -arch x86
"%wix%\light.exe" obj\Release\Product.wixobj -out bin\Release\HelloFSharpSetup.msi -pdbout bin\Release\HelloFSharpSetup.wixpdb