#!/bin/bash
START=$(date +%s)

echo "Cleaning up..."
rm -rf devkitpro
rm -rf dist
rm -rf build

echo -e "\nGetting dependency files..."
FILES=(
    "devkitPPC-r41-2-linux_x86_64.pkg.tar.xz"
    "devkitppc-rules-1.1.1-1-any.pkg.tar.xz"
    "libogc-2.3.1-1-any.pkg.tar.xz"
    "general-tools-1.2.0-2-linux_x86_64.pkg.tar.xz"
    "gamecube-tools-1.0.3-1-linux_x86_64.pkg.tar.xz"
)
SHA256SUMS=(
    "f8bdbabd7e30ebc87dc129c092d1fa85e38d726de78befad3dc6714568431076"
    "0118f06fff938c3d4913fdc004d5edd2f72e3a16c544fb5699b0e97552529d29"
    "b10553cced35ab8d3d0c48ee44cdb345f46be5e8f82496dd308f699db4f8d490"
    "3348e521e48f27912d0bca05eac73b4365c8c7006b637c95850f4feabe5dd2e9"
    "e7ea6a13ca5a5e9d6a5b8e1616afcc92a81255aa6fee436ed81c812b62e112af"
)

if [ ! -d cache ]; then
    mkdir cache
fi

calculate_sha256() {
    sha256sum "$1" | cut -d' ' -f1
}

for i in "${!FILES[@]}"; do
    FILE_NAME="${FILES[$i]}"
    FILE="cache/$FILE_NAME"
    SHA256="${SHA256SUMS[$i]}"

    if [ ! -f $FILE ]; then
        echo -n "-- Downloading $FILE_NAME... "
        wget -q "https://wii.leseratte10.de/devkitPro/file.php/$FILE_NAME" -O $FILE
        echo "Done!"
    else
        FSHA256=$(calculate_sha256 $FILE)
        if [ $FSHA256 != $SHA256 ]; then
            echo "-- SHA256 mismatch for $FILE, redownloading... "
            rm $FILE
            echo -n "-- Downloading $FILE_NAME... "
            wget -q "https://wii.leseratte10.de/devkitPro/file.php/$FILE_NAME" -O $FILE
            echo "Done!"
        else
            echo "-- Using cached $FILE_NAME"
        fi
    fi
done

echo -e "\nExtracting dependency files..."

mkdir devkitpro
for i in "${!FILES[@]}"; do
    FILE="${FILES[$i]}"
    echo -n "-- Extracting $FILE... "
    tar -xf cache/$FILE --strip-components=1
    echo "Done!"
done

echo -e "\nBuilding USB Loader GX..."

export PATH=$(pwd)/devkitpro/devkitPPC/bin:$PATH
export DEVKITPPC=$(pwd)/devkitpro/devkitPPC
export DEVKITPRO=$(pwd)/devkitpro

echo -n "-- Compiling USB Loader GX... "
make > /dev/null
echo "Done!"

echo -n "-- Creating package... "
mkdir -p dist/apps/usbloader_gx
cp boot.dol dist/apps/usbloader_gx
cp HBC/icon.png dist/apps/usbloader_gx
cp HBC/meta.xml dist/apps/usbloader_gx
echo "Done!"

END=$(date +%s)

echo -e "\nBuild finished in $((END - START)) seconds"
PKG_DIR=$(pwd)
echo "Package can be found in $PKG_DIR/dist"

exit