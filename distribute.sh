# rm -rf distribute

NAME="pickle"

# Source
rm -f distribute/source/*.love
zip -9 -r -v distribute/source/$NAME.love . -x *.git* *.sh "distribute/*"
cd distribute/source
rm -f ../*_source.zip
zip -9 -r -v ../$NAME"_source.zip" .
cd ../..

# Windows
rm -f distribute/windows/*.exe
cat distribute/windows/love.exe distribute/source/$NAME.love > distribute/windows/$NAME.exe
cd distribute/windows
rm -f ../*_windows.zip
zip -9 -r -v ../$NAME"_windows.zip" . -x love.exe love.ico
cd ../..

# Linux
rm -f distribute/linux/*.love
cp distribute/source/$NAME.love distribute/linux/
cd distribute/linux
rm -f ../*_linux.zip
zip -9 -r -v ../$NAME"_linux.zip" .
cd ../..

# OSX
rm -f distribute/osx/$NAME.app/Contents/Resources/$NAME.love
cp distribute/source/$NAME.love distribute/osx/$NAME.app/Contents/Resources/
cd distribute/osx
rm -f ../*_osx.zip
zip -9 -r -v ../$NAME"_osx.zip" .
cd ../..
