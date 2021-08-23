all: shasums

# List all the supported and built Pi platforms here. They get expanded
# to names like 'raspi_2_buster.yaml' and 'raspi_3_bullseye.img.xz'.
BUILD_FAMILIES := 1 2 3 4
BUILD_RELEASES := buster bullseye

platforms := $(foreach plat, $(BUILD_FAMILIES),$(foreach rel, $(BUILD_RELEASES),  raspi_$(plat)_$(rel)))

shasums: $(addsuffix .sha256,$(platforms)) $(addsuffix .img.xz.sha256,$(platforms))
xzimages: $(addsuffix .img.xz,$(platforms))
images: $(addsuffix .img,$(platforms))
yaml: $(addsuffix .yaml,$(platforms))

ifeq ($(shell id -u),0)
as_root =
else ifneq (,$(wildcard /usr/bin/fakemachine))
$(warning "This should normally be run as root, but found 'fakemachine', so using that.")
as_root = fakemachine -v $(CURDIR) -- env --chdir $(CURDIR)
else
$(error "This must be run as root")
endif

target_platforms:
	@echo $(platforms)

raspi_base_buster.yaml: raspi_master.yaml
	cat raspi_master.yaml | \
	sed "s/__FIRMWARE_PKG__/raspi3-firmware/" | \
	sed "s/__RELEASE__/buster/" |\
	sed "s/__SECURITY_SUITE__/buster\/updates/" |\
	sed "s/__FIX_FIRMWARE_PKG_NAME__/sed -i s\/raspi-firmware\/raspi3-firmware\/ \$${ROOT?}\/etc\/systemd\/system\/rpi-reconfigure-raspi-firmware.service/" |\
	grep -v '__EXTRA_SHELL_CMDS__' > $@

raspi_1_buster.yaml: raspi_base_buster.yaml
	cat raspi_base_buster.yaml | sed "s/__ARCH__/armel/" | \
	sed "s/__LINUX_IMAGE__/linux-image-rpi/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-rpi\\/bcm*rpi-*.dtb/" |\
	sed "s/__SERIAL_CONSOLE__/ttyAMA0,115200/" |\
	grep -v "__OTHER_APT_ENABLE__" |\
	sed "s/__HOST__/rpi1/" |\
	grep -v '__EXTRA_SHELL_CMDS__' > $@

raspi_2_buster.yaml: raspi_base_buster.yaml
	cat raspi_base_buster.yaml | sed "s/__ARCH__/armhf/" | \
	sed "s/__LINUX_IMAGE__/linux-image-armmp/" | \
	grep -v "__EXTRA_PKGS__" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-armmp\\/bcm*rpi*.dtb/" |\
	sed "s/__SERIAL_CONSOLE__/ttyAMA0,115200/" |\
	sed "s/__OTHER_APT_ENABLE__//" |\
	sed "s/__HOST__/rpi2/" |\
	grep -v '__EXTRA_SHELL_CMDS__' > $@

raspi_3_buster.yaml: raspi_base_buster.yaml
	cat raspi_base_buster.yaml | sed "s/__ARCH__/arm64/" | \
	sed "s/__LINUX_IMAGE__/linux-image-arm64/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-arm64\\/broadcom\\/bcm*rpi*.dtb/" |\
	sed "s/__SERIAL_CONSOLE__/ttyS1,115200/" |\
	sed "s/__OTHER_APT_ENABLE__//" |\
	sed "s/__HOST__/rpi3/" |\
	grep -v '__EXTRA_SHELL_CMDS__' > $@

raspi_4_buster.yaml: raspi_base_buster.yaml
	cat raspi_base_buster.yaml | sed "s/__ARCH__/arm64/" | \
	sed "s#raspi3-firmware#raspi-firmware/buster-backports#" | \
	sed "s#apt-get update#echo 'APT::Default-Release \"buster\";' > /etc/apt/apt.conf\n      apt-get update#" | \
	sed "s#\(RASPIROOT.*cmdline.txt\)#\1\n      sed -i 's/cma=64M //' /boot/firmware/cmdline.txt\n      sed -i 's/cma=\\\$$CMA //' /etc/kernel/postinst.d/z50-raspi-firmware#" | \
	sed "s/__LINUX_IMAGE__/linux-image-arm64\/buster-backports/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211\/buster-backports/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-arm64\\/broadcom\\/bcm*rpi*.dtb/" |\
	sed "s/__SERIAL_CONSOLE__/ttyS1,115200/" |\
	sed "s/__OTHER_APT_ENABLE__/deb http:\/\/deb.debian.org\/debian\/ buster-backports main contrib non-free # raspi 4 needs a kernel and raspi-firmware newer than buster's/" |\
	sed "s/__HOST__/rpi4/" |\
	grep -v '__EXTRA_SHELL_CMDS__' > $@

raspi_base_bullseye.yaml: raspi_master.yaml
	cat raspi_master.yaml | \
	sed "s/__RELEASE__/bullseye/" |\
	sed "s/__FIRMWARE_PKG__/raspi-firmware/" | \
	grep -v "__OTHER_APT_ENABLE__" |\
	grep -v "__FIX_FIRMWARE_PKG_NAME__" |\
	sed "s/__SECURITY_SUITE__/bullseye-security/" > $@

raspi_1_bullseye.yaml: raspi_base_bullseye.yaml
	cat raspi_base_bullseye.yaml | sed "s/__ARCH__/armel/" | \
	sed "s/__LINUX_IMAGE__/linux-image-rpi/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-rpi\\/bcm*rpi-*.dtb/" |\
	sed "s/__SERIAL_CONSOLE__/ttyAMA0,115200/" |\
	sed "s/__HOST__/rpi_1/" |\
	grep -v '__EXTRA_SHELL_CMDS__' > $@

raspi_2_bullseye.yaml: raspi_base_bullseye.yaml
	cat raspi_base_bullseye.yaml | sed "s/__ARCH__/armhf/" | \
	sed "s/__LINUX_IMAGE__/linux-image-armmp/" | \
	grep -v "__EXTRA_PKGS__" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-armmp\\/bcm*rpi*.dtb/" |\
	sed "s/__SERIAL_CONSOLE__/ttyAMA0,115200/" |\
	sed "s/__HOST__/rpi_2/" |\
	grep -v '__EXTRA_SHELL_CMDS__' > $@

raspi_3_bullseye.yaml: raspi_base_bullseye.yaml
	cat raspi_base_bullseye.yaml | sed "s/__ARCH__/arm64/" | \
	sed "s/__LINUX_IMAGE__/linux-image-arm64/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-arm64\\/broadcom\\/bcm*rpi*.dtb/" |\
	sed "s/__SERIAL_CONSOLE__/ttyS1,115200/" |\
	sed "s/__HOST__/rpi_3/" |\
	grep -v '__EXTRA_SHELL_CMDS__' > $@

raspi_4_bullseye.yaml: raspi_base_bullseye.yaml
	cat raspi_base_bullseye.yaml | sed "s/__ARCH__/arm64/" | \
	sed "s#\(RASPIROOT.*cmdline.txt\)#\1\n      sed -i 's/cma=64M //' /boot/firmware/cmdline.txt\n      sed -i 's/cma=\\\$$CMA //' /etc/kernel/postinst.d/z50-raspi-firmware#" | \
	sed "s/__LINUX_IMAGE__/linux-image-arm64/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-arm64\\/broadcom\\/bcm*rpi*.dtb/" |\
	sed "s/__SERIAL_CONSOLE__/ttyS1,115200/" |\
	sed "s/__HOST__/rpi_4/" |\
	grep -v '__EXTRA_SHELL_CMDS__' > $@

%.sha256: %.img
	echo $@
	sha256sum $(@:sha256=img) > $@

%.img.xz.sha256: %.img.xz
	echo $@
	sha256sum $(@:img.xz.sha256=img.xz) > $@

%.img.xz: %.img
	xz -f -k -z -9 $(@:.xz=)

%.img.bmap: %.img
	bmaptool create -o $@ $<

%.img: %.yaml
	touch $(@:.img=.log)
	time nice $(as_root) vmdb2 --verbose --rootfs-tarball=$(subst .img,.tar.gz,$@) --output=$@ $(subst .img,.yaml,$@) --log $(subst .img,.log,$@)
	chmod 0644 $@ $(@,.img=.log)

_ck_root:
	[ `whoami` = 'root' ] # Only root can summon vmdb2 ☹

_clean_yaml:
	rm -f $(addsuffix .yaml,$(platforms)) raspi_base_buster.yaml raspi_base_bullseye.yaml
_clean_images:
	rm -f $(addsuffix .img,$(platforms))
_clean_xzimages:
	rm -f $(addsuffix .img.xz,$(platforms))
_clean_bmaps:
	rm -f $(addsuffix .img.bmap,$(platforms))
_clean_shasums:
	rm -f $(addsuffix .sha256,$(platforms)) $(addsuffix .img.xz.sha256,$(platforms))
_clean_logs:
	rm -f $(addsuffix .log,$(platforms))
_clean_tarballs:
	rm -f $(addsuffix .tar.gz,$(platforms))
clean: _clean_xzimages _clean_images _clean_shasums _clean_yaml _clean_tarballs _clean_logs _clean_bmaps

.PHONY: _ck_root _build_img clean _clean_images _clean_yaml _clean_tarballs _clean_logs
