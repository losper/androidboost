rem set path=D:/dev/androidsdk/ndk/arm/bin;%PATH%
b2.exe -d+2 -j 2 --reconfigure target-os=android toolset=gcc-arm include=D:/dev/androidsdk/ndk/arm/include/c++/4.9.x link=static variant=release threading=multi threadapi=pthread --without-python --without-context --without-coroutine --prefix=D:/dev/androidsdk/boost/arm64 install
pause