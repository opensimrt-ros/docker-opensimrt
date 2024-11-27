#!/bin/bash
set -e
source options.sh
if [ "$(uname)" == "Darwin" ]; then
	# Do something under Mac OS X platform
	# I can only run in x86_64 systems, so I should also warn the person.
	docker build . -f ros.Dockerfile -t ${USERNAME}/opensim-rt-$ARCH:$BRANCH $@

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	# Do something under GNU/Linux platform
	# I can only run in x86_64 systems, so I should also warn the person.
	
	options=$(getopt -o lc --longoptions username:,user_id:,group_id:,complete_build,build_stages_separately,disable_buildx,single_core -- "$@")
	[ $? -eq 0 ] || { 
	    echo "Incorrect options provided"
	    exit 1
	}
	eval set -- "$options"
	while true; do
	    case "$1" in
	    -l)
		## tag as latest
		BRANCH=latest
		;;
	    -c|--complete_build)
		COMPLETE_BUILD=true
		SUFFIX=_complete
		;;
	    --username)
		shift; # The arg is next in position args
		USERNAME=$1
		#echo  babababababbabab
		#COLOR=$1
		#[[ ! $COLOR =~ BLUE|RED|GREEN ]] && {
		#    echo "Incorrect options provided"
		#    exit 1
		#}
		;;
	    --user_id)
		shift;
		USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER=$1
		;;
	    --group_id)
		shift;
		USER_GID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER=$1
		;;
	    --build_stages_separately)
		BUILD_STAGES=true
		;;
	    --disable_buildx)
		BUILDX=0
		;;
	    --single_core)
		USE_N_CORES=1
		;;
	    --)
		shift
		## after this there will be the options for docker build. the second one
		break
		;;
	    esac
	    shift
	done
	#printf "$USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER" 
	#exit 0;

	if [ "$COMPLETE_BUILD" = true ]; then

		START_WITH_IMAGE=${USERNAME}/osrt-full-$ARCH:$BRANCH 
		#START_WITH_IMAGE=${USERNAME}/osrt-full:latest 
	else
		START_WITH_IMAGE=ros:noetic-ros-base 
	fi
	COMMON_OPTIONS=""
	if [ "$BUILDX" = 1 ]; then
		COMMON_OPTIONS="--progress=tty "
	fi
	COMMON_OPTIONS=${COMMON_OPTIONS}"--network=host \
			--build-arg user=$USERNAME \
			--build-arg group=$USERNAME \
			--build-arg uid=${USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER} \
			--build-arg gid=${USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER} \
			--build-arg IS_ROOTLESS=$IS_ROOTLESS \
			--build-arg USE_N_CORES=$USE_N_CORES \
			$@
	"

	if [ "$COMPLETE_BUILD" = true ]; then
		echo "USING COMPLETE BUILD"
		cd opensim_docker
		if [ "$BUILD_STAGES" = true ]; then
			echo "Building opensim docker by stage"
			DOCKER_BUILDKIT=$BUILDX docker build . -f Dockerfile --target=dependencies -t ${USERNAME}/osrt-1-$ARCH:$BRANCH $COMMON_OPTIONS
			DOCKER_BUILDKIT=$BUILDX docker build . -f Dockerfile --target=stage2 -t ${USERNAME}/osrt-2-$ARCH:$BRANCH $COMMON_OPTIONS
			DOCKER_BUILDKIT=$BUILDX docker build . -f Dockerfile --target=stage3 -t ${USERNAME}/osrt-3-$ARCH:$BRANCH $COMMON_OPTIONS
		fi
			DOCKER_BUILDKIT=$BUILDX docker build . -f Dockerfile -t ${USERNAME}/osrt-full-$ARCH:$BRANCH $COMMON_OPTIONS
		cd ..
	fi
	if [ "$BUILD_STAGES" = true ]; then
		echo "Building opensimrt by stage"
		DOCKER_BUILDKIT=$BUILDX docker build . -f ros.Dockerfile -t ${USERNAME}/opensim-rt1${SUFFIX}-$ARCH:$BRANCH  \
			--target=stage1 \
			--build-arg start_with_image=${START_WITH_IMAGE} \
			--build-arg download_precompiled_opensim=${COMPLETE_BUILD} \
			$COMMON_OPTIONS
		DOCKER_BUILDKIT=$BUILDX docker build . -f ros.Dockerfile -t ${USERNAME}/opensim-rt2${SUFFIX}-$ARCH:$BRANCH  \
			--target=stage2 \
			--build-arg start_with_image=${START_WITH_IMAGE} \
			--build-arg download_precompiled_opensim=${COMPLETE_BUILD} \
			$COMMON_OPTIONS
		DOCKER_BUILDKIT=$BUILDX docker build . -f ros.Dockerfile -t ${USERNAME}/opensim-rt3${SUFFIX}-$ARCH:$BRANCH  \
			--target=stage3 \
			--build-arg start_with_image=${START_WITH_IMAGE} \
			--build-arg download_precompiled_opensim=${COMPLETE_BUILD} \
			$COMMON_OPTIONS
		DOCKER_BUILDKIT=$BUILDX docker build . -f ros.Dockerfile -t ${USERNAME}/opensim-rt4${SUFFIX}-$ARCH:$BRANCH  \
			--target=final \
			--build-arg start_with_image=${START_WITH_IMAGE} \
			--build-arg download_precompiled_opensim=${COMPLETE_BUILD} \
			$COMMON_OPTIONS
	fi
	echo "Building main opensimrt image."
	DOCKER_BUILDKIT=$BUILDX docker build . -f ros.Dockerfile -t ${USERNAME}/opensim-rt${SUFFIX}-$ARCH:$BRANCH  \
		--build-arg start_with_image=${START_WITH_IMAGE} \
		--build-arg download_precompiled_opensim=${COMPLETE_BUILD} \
		$COMMON_OPTIONS

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
	# Do something under 32 bits Windows NT platform
	docker build . -f ros.Dockerfile -t ${USERNAME}/opensim-rt-$ARCH:$BRANCH $@

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
	# Do something under 64 bits Windows NT platform
	docker build . -f ros.Dockerfile -t ${USERNAME}/opensim-rt-$ARCH:$BRANCH $@

fi












