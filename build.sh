PS3="Architecture: >"
options=(
	"armv32 (armv6 armv7)"
	"arm64"
)
echo ''

select option in "${options[@]}"; do
	case "$REPLY" in
		1)
            arch=arm32v6
            pkg_arch=armv6
			qemu=arm
			folder=arm32
			break
			;;
		2)
            arch=arm64v8
            pkg_arch=arm64
			qemu=aarch64
			folder=arm64
			break
			;;
		*)
			echo '####################'
			echo '## Invalid option ##'
			echo '####################'
			exit
	esac
done

PS3="NodeJS version: >"
options=(
	"8.11.3"
	"10.4.1"
	"12.2.0"
)
echo ''

select option in "${options[@]}"; do
	case "$REPLY" in
		1)
            node_version=8.11.3
			pkg_node=node8
			break
			;;
		2)
            node_version=10.4.1
			pkg_node=node10
			break
			;;
		*)
			echo '####################'
			echo '## Invalid option ##'
			echo '####################'
			exit
	esac
done

PS3="OS version: >"
options=(
	"linux"
	"alpine"
)
echo ''

select option in "${options[@]}"; do
	case "$REPLY" in
		1)
			pkg_os=linux
			if [ "$arch" == "arm32v6" ] # arm32v6 images are just for alpine
			then
				arch=arm32v7
				pkg_arch=armv7
			fi
			tag="node:latest"
			dependencies="apt-get update \&\& apt-get install -y --no-install-recommends wget build-essential git"
			break
			;;
		2)
			pkg_os=alpine
            tag="node:alpine"
			dependencies="apk update \&\& apk --no-cache add git wget build-base python paxctl linux-headers"
			break
			;;
		*)
			echo '####################'
			echo '## Invalid option ##'
			echo '####################'
			exit
	esac
done

sudo docker run --rm --privileged multiarch/qemu-user-static:register
cp Dockerfile.cross Dockerfile.build

sed -i "s|__ARCH__|${arch}|g" Dockerfile.build
sed -i "s|__NODE_VERSION__|${node_version}|g" Dockerfile.build
sed -i "s|__TAG__|${tag}|g" Dockerfile.build
sed -i "s|__QEMU__|${qemu}|g" Dockerfile.build
sed -i "s|__DEPENDENCIES__|${dependencies}|g" Dockerfile.build

sed -i "s|__NODE_PKG__|${pkg_node}|g" Dockerfile.build
sed -i "s|__PKG_OS__|${pkg_os}|g" Dockerfile.build
sed -i "s|__PKG_ARCH__|${pkg_arch}|g" Dockerfile.build

docker build -f Dockerfile.build -t ${arch}/pkgbinaries:${pkg_os}-${pkg_node} .
docker run -it --rm -v ${pwd}/${folder}:/fetched ${arch}/pkgbinaries:${pkg_os}-${pkg_node}

rm Dockerfile.build
