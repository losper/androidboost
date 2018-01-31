# -h/-help for help
# --outdir
# --boostdir
# --ndkdir
checkRun(){
	command $* || { echo "fatal error:" $*; exit 1; }
}

archs=()
_projdir=$PWD

if [[ "$(uname -o)" == "Msys" ]]; then
	_projdir=${_projdir:1:1}:${_projdir:2}
fi
_outdir=$_projdir

while getopts h-: OPT;do
    case $OPT in
        -)
            case $OPTARG in
                help)
                    echo $OPTARG
                    exit 0
                    ;;
				arm);&
				arm64);&
				x86);&
				x64)
					archs+=($OPTARG)
					;;
                outdir=*)
                    _outdir=${OPTARG#*=}
					echo $_outdir
                    ;;
				ndkdir=*)
                    _ndkdir=${OPTARG#*=}
					echo $_ndkdir
                    ;;
				boostdir=*)
                    _boostdir=${OPTARG#*=}
					echo $_boostdir
                    ;;
            esac
            ;;
        h)
            echo $OPTARG
            exit 0
			;;
    esac
done
command -v py >/dev/null 2>&1 || { echo >&2 "Require python but it's not installed.  Aborting."; exit 1; }
echo "build starting:"
for data in ${archs[@]}  
do  
    echo "arch:" ${data}  
done  
# check ndkdir
echo "NDK_DIR:" $_ndkdir
if [[ ! -f "$_ndkdir/ndk-build" ]] && [[ ! -f "$_ndkdir/ndk-build.cmd" ]]; then
	echo "ERROR: you need to provide a NDK_ROOT"
	exit 2
fi
echo "CHECK: ndkdir is ok"
b2exe=
if [[ -f "$_boostdir/b2.exe" ]]; then
	b2exe=./b2.exe
fi
if [[ -f "$_boostdir/b2" ]]; then
	b2exe=./b2
fi
if [[ ! $b2exe == *b2* ]]; then
	echo "ERROR: you need to build b2 before run this script!!!"
	exit 2
fi
echo "CHECK: boostdir is ok & b2:" $b2exe

num=${#archs[@]}
for ((i=0;i<$num;i++))
do
	echo "make standalone ndk env for" ${archs[i]}
	tmpdir="./tmp/ndk/${archs[i]}"
	if [[ -d $tmpdir ]]; then
		echo "BUILD: skip make standalone ndk env for" ${archs[i]} "!!!"
	else
		#mkdir -p $tmpdir
		py "$_ndkdir/build/tools/make_standalone_toolchain.py" --arch ${archs[i]} --install-dir $tmpdir
	fi
done

mv $_boostdir/project-config.jam $_boostdir/project-config.bak.jam
for ((i=0;i<$num;i++))
do
	echo "build boost for" ${archs[i]}
	tmpdir="$_outdir/${archs[i]}"
	model=
	prefix=
	if [[ -d $tmpdir ]]; then
		echo "BUILD: skip build boost for" ${archs[i]} "!!!"
	else
		#mkdir -p $tmpdir
		case ${archs[i]} in
			arm64)
			model=address-model=64
			prefix=aarch64-linux-android
			;;
			arm)
			prefix=arm-linux-androideabi
			;;
		esac
		echo "address-model:"$model
		echo "build ndk dir:$_projdir/tmp/ndk/${archs[i]}/include/c++/4.9.x"
		echo "build output dir:$_outdir/${archs[i]}"
		
		echo "using gcc : arm : $_projdir/tmp/ndk/${archs[i]}/bin/$prefix-g++ : <archiver>$_projdir/tmp/ndk/${archs[i]}/bin/$prefix-ar <ranlib>$_projdir/tmp/ndk/${archs[i]}/bin/$prefix-ranlib ;" > $_boostdir/project-config.jam
		
		#checkRun cp $_projdir/project-config-${archs[i]}.jam $_boostdir/project-config.jam
		checkRun cd $_boostdir 
		$b2exe $model -d+2 -j 2 --reconfigure target-os=android toolset=gcc-arm include=$_projdir/tmp/ndk/${archs[i]}/include/c++/4.9.x link=static variant=release threading=multi threadapi=pthread --without-python --without-context --without-coroutine --prefix=$_outdir/${archs[i]} install
		echo "end build boost for" ${archs[i]}
	fi
done
