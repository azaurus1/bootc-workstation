image:
	@echo "Building bootc workstation image..."
	sudo podman build -t localhost/bootc-workstation -f Containerfile

dev:
	@echo "Building bootc workstation image..."
	podman build -t localhost/bootc-workstation -f Containerfile
	@echo "Running bootc workstation image and sshing..."
	bcvk ephemeral run-ssh localhost/bootc-workstation

run: 
	@echo "Running bootc-workstation"
	sudo virt-install \
		--name bootc-workstation \
		--cpu host \
		--vcpus 2 \
		--memory 2096 \
		--import \
		--disk ./output/qcow2/disk.qcow2,format=qcow2 \
		--os-variant fedora-eln \
		--network network=default

build:
	@echo "Building bootc workstation image..."
	sudo podman build -t localhost/bootc-workstation -f Containerfile

	@echo "Creating qcow2 file from bootc workstation image..."
	sudo podman run \
		--rm \
		-it \
		--privileged \
		--pull=never \
		--security-opt label=type:unconfined_t \
		-v ./output:/output \
		-v ./config.toml:/config.toml:ro \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type qcow2 \
		--use-librepo=True \
		--rootfs xfs \
		localhost/bootc-workstation:latest

	@echo "Starting virtual machine..."
	sudo virt-install \
		--name bootc-workstation \
		--cpu host \
		--vcpus 2 \
		--memory 2096 \
		--import \
		--disk ./output/qcow2/disk.qcow2,format=qcow2 \
		--os-variant fedora-eln \
		--network network=default

iso:
	@echo "Creating iso file from bootc workstation image..."
	sudo podman run \
		--rm \
		-it \
		--privileged \
		--pull=never \
		--security-opt label=type:unconfined_t \
		-v ./output:/output \
		-v ./config.toml:/config.toml:ro \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type iso \
		--use-librepo=True \
		--rootfs xfs \
		localhost/bootc-workstation:latest