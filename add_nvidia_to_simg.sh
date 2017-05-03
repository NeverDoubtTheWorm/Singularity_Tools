function usage
{
    me=$(basename $0)
    # TODO: Finish this
    echo "usage: $me [-h | -help | --help] | [-f <nvid_run>] [-d <tmp>] [-c] [-v <version>] singularity.img"
}


##### Main

nvid_run=
nvid_ver=
create_only=
tmp=
if [ $# -lt 1 -o "$1" = "-help" -o "$1" = "--help" -o "$1" = "-h"  ]; then
    usage
    exit 1
fi
while [ $# -gt 1 ]; do
    case $1 in
        -f | --file )           shift
                                nvid_run=$(readlink -f $1)
                                ;;
        -d | --dir )            shift
                                tmp=$(readlink -f $1)
                                ;;
        -v | --version )        nvid_ver=$1
                                ;;
        -c | --create-only )    create_only=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ -d $1 -o -f $1 ]; then
    simg=$(readlink -f $1)
else
    echo "Failed: exiting..."
    exit 1
fi
echo "using $simg"

if [ "$tmp" = "" ]; then
    tmp=$(mktemp -d)
    mkdir -p $tmp
    if [ "$create_only" = "1" ]; then
        cleanup() {
            rm -rf $tmp
        }
        trap cleanup 0
    fi
fi

pushd $(pwd)

if [ "$nvid_run" = "" ]; then
    if [ "$nvid_ver" = "" ]; then
        echo "Detecting nvidia driver version ..."
        nvid_ver=$(nvidia-smi --query-gpu=driver_version --format=csv | tail -1)
        if [ "$nvid_ver" = "" ]; then
            echo "Failed to detect driver version, using 375.39"
            nvid_ver=375.39
        else
            echo "Detected driver version $nvid_ver"
        fi
    fi
    echo "No Nvidia .run file provided, attempting to download v$nvid_ver..."
    nvid_run=NVIDIA-Linux-x86_64-$nvid_ver.run
    url=http://us.download.nvidia.com/XFree86/Linux-x86_64/$nvid_ver/$nvid_run
    wget -P $tmp $url
    nvid_run=$tmp/$nvid_run
else
    nvid_ver=`echo $nvid_run | sed "s/.*\-\([0-9]*\.[0-9]*\)\.run/\1/"`
fi

if [ "$nvid_ver" = "" ]; then
    echo "failed to parse command"
    exit 1
fi

cd $tmp
bash $nvid_run --extract-only
nfile=`echo $nvid_run | sed "s/.*\/\(.*\)\.run/\1/"`
nfile=$tmp/$nfile

bindir=$tmp/nvidia/bin
mkdir -p $bindir
cd $nfile
cp nvidia-cuda-mps-control $bindir # Multi process service CLI
cp nvidia-cuda-mps-server $bindir  # Multi process service server
cp nvidia-debugdump $bindir        # GPU coredump utility
cp nvidia-persistenced $bindir     # Persistence mode utility
cp nvidia-smi $bindir              # System management interface


libdir=$tmp/nvidia/lib
mkdir -p $libdir
cd $nfile/32
cp libEGL_nvidia.so.$nvid_ver $libdir
cp libEGL.so.1 $libdir
cp libGLdispatch.so.0 $libdir
cp libGLESv1_CM_nvidia.so.$nvid_ver $libdir
cp libGLESv1_CM.so.1 $libdir
cp libGLESv2_nvidia.so.$nvid_ver $libdir
cp libGLESv2.so.2 $libdir
cp libGL.so.1.0.0 $libdir
cp libGLX_nvidia.so.$nvid_ver $libdir
cp libGLX.so.0 $libdir
cp libnvcuvid.so.$nvid_ver $libdir
cp libnvidia-compiler.so.$nvid_ver $libdir
cp libnvidia-eglcore.so.$nvid_ver $libdir
cp libnvidia-egl-wayland.so.$nvid_ver $libdir
cp libnvidia-encode.so.$nvid_ver $libdir
cp libnvidia-fatbinaryloader.so.$nvid_ver $libdir
cp libnvidia-fbc.so.$nvid_ver $libdir
cp libnvidia-glcore.so.$nvid_ver $libdir
cp libnvidia-glsi.so.$nvid_ver $libdir
cp libnvidia-ifr.so.$nvid_ver $libdir
cp libnvidia-ml.so.$nvid_ver $libdir
cp libnvidia-ptxjitcompiler.so.$nvid_ver $libdir
cp tls/libnvidia-tls.so.$nvid_ver $libdir
cp libvdpau_nvidia.so.$nvid_ver $libdir

cd $libdir
# -- Compute --
# Management library
ln -s libnvidia-ml.so.$nvid_ver libnvidia-ml.so.1
# -- Video --
# NVIDIA VDPAU ICD
ln -s libvdpau_nvidia.so.$nvid_ver libvdpau_nvidia.so.1
# Video encoder
ln -s libnvidia-encode.so.$nvid_ver libnvidia-encode.so.1
# Video decoder
ln -s libnvcuvid.so.$nvid_ver libnvcuvid.so.1
# Framebuffer Capture
ln -s libnvidia-fbc.so.$nvid_ver libnvidia-fbc.so.1
# OpenGL framebuffer capture
ln -s libnvidia-ifr.so.$nvid_ver libnvidia-ifr.so.1
# -- Graphic --
# OpenGL/GLX legacy _or_ compatibility wrapper (GLVND)
ln -s libGL.so.1.0.0 libGL.so.1
# EGL ICD (GLVND)
ln -s libEGL_nvidia.so.$nvid_ver libEGL_nvidia.so.0
# OpenGL/GLX ICD (GLVND)
ln -s libGLX_nvidia.so.$nvid_ver libGLX_nvidia.so.0
ln -s libGLX_nvidia.so.$nvid_ver libGLX_indirect.so.0
# OpenGL ES v1 common profile ICD (GLVND)
ln -s libGLESv1_CM_nvidia.so.$nvid_ver libGLESv1_CM_nvidia.so.1
# OpenGL ES v2 ICD (GLVND)
ln -s libGLESv2_nvidia.so.$nvid_ver libGLESv2_nvidia.so.2


lib64dir=$tmp/nvidia/lib64
mkdir -p $lib64dir
cd $nfile
cp libcuda.so.$nvid_ver $lib64dir
cp libEGL_nvidia.so.$nvid_ver $lib64dir
cp libEGL.so.1 $lib64dir
cp libGLdispatch.so.0 $lib64dir
cp libGLESv1_CM_nvidia.so.$nvid_ver $lib64dir
cp libGLESv1_CM.so.1 $lib64dir
cp libGLESv2_nvidia.so.$nvid_ver $lib64dir
cp libGLESv2.so.2 $lib64dir
cp libGL.so.1.0.0 $lib64dir
cp libGLX_nvidia.so.$nvid_ver $lib64dir
cp libGLX.so.0 $lib64dir
cp libnvcuvid.so.$nvid_ver $lib64dir
cp libnvidia-compiler.so.$nvid_ver $lib64dir
cp libnvidia-eglcore.so.$nvid_ver $lib64dir
cp libnvidia-egl-wayland.so.$nvid_ver $lib64dir
cp libnvidia-encode.so.$nvid_ver $lib64dir
cp libnvidia-fatbinaryloader.so.$nvid_ver $lib64dir
cp libnvidia-fbc.so.$nvid_ver $lib64dir
cp libnvidia-glcore.so.$nvid_ver $lib64dir
cp libnvidia-glsi.so.$nvid_ver $lib64dir
cp libnvidia-ifr.so.$nvid_ver $lib64dir
cp libnvidia-ml.so.$nvid_ver $lib64dir
cp libnvidia-opencl.so.$nvid_ver $lib64dir
cp libnvidia-ptxjitcompiler.so.$nvid_ver $lib64dir
cp tls/libnvidia-tls.so.$nvid_ver $lib64dir
cp libOpenGL.so.0 $lib64dir
cp libvdpau_nvidia.so.$nvid_ver $lib64dir

cd $lib64dir
# -- Compute --
# Management library
ln -s libnvidia-ml.so.$nvid_ver libnvidia-ml.so.1
# CUDA driver library
ln -s libcuda.so.$nvid_ver libcuda.so
ln -s libcuda.so.$nvid_ver libcuda.so.1
# NVIDIA OpenCL ICD
ln -s libnvidia-opencl.so.$nvid_ver libnvidia-opencl.so.1
# -- Video --
# NVIDIA VDPAU ICD
ln -s libvdpau_nvidia.so.$nvid_ver libvdpau_nvidia.so.1
# Video encoder
ln -s libnvidia-encode.so.$nvid_ver libnvidia-encode.so.1
# Video decoder
ln -s libnvcuvid.so.$nvid_ver libnvcuvid.so.1
# Framebuffer Capture
ln -s libnvidia-fbc.so.$nvid_ver libnvidia-fbc.so.1
# OpenGL framebuffer capture
ln -s libnvidia-ifr.so.$nvid_ver libnvidia-ifr.so.1
# -- Graphic --
# OpenGL/GLX legacy _or_ compatibility wrapper (GLVND)
ln -s libGL.so.1.0.0 libGL.so.1
# EGL ICD (GLVND)
ln -s libEGL_nvidia.so.$nvid_ver libEGL_nvidia.so.0
# OpenGL/GLX ICD (GLVND)
ln -s libGLX_nvidia.so.$nvid_ver libGLX_nvidia.so.0
ln -s libGLX_nvidia.so.$nvid_ver libGLX_indirect.so.0
# OpenGL ES v1 common profile ICD (GLVND)
ln -s libGLESv1_CM_nvidia.so.$nvid_ver libGLESv1_CM_nvidia.so.1
# OpenGL ES v2 ICD (GLVND)
ln -s libGLESv2_nvidia.so.$nvid_ver libGLESv2_nvidia.so.2


if [ "$create_only" != "1" ]; then
    sudo singularity copy $simg -r $tmp/nvidia /usr/local/
else
    echo "nvidia file at $tmp/nvidia"
fi

popd
