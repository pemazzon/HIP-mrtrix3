export ANTSPATH="/opt/ants/bin"
export ARTHOME="/opt/art"
export FREESURFER_HOME="/opt/freesurfer"
export FSLDIR="/opt/fsl"
export FSLOUTPUTTYPE="NIFTI_GZ"
export FSLMULTIFILEQUIT="TRUE"
export FSLTCLSH="/opt/fsl/bin/fsltclsh"
export FSLWISH="/opt/fsl/bin/fslwish"
export LD_LIBRARY_PATH="/opt/fsl/lib:$LD_LIBRARY_PATH"
export PATH="/opt/mrtrix3/bin:/opt/ants/bin:/opt/art/bin:/opt/fsl/bin:$PATH"
# the below to silence the warning upon running mrview
export XDG_RUNTIME_DIR=/tmp/runtime-${USER}

# Load the default .profile
[[ -s "$HOME/.profile" ]] && source "$HOME/.profile"
