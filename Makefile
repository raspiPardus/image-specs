all: shasums

# List all the supported and built Pi platforms here. They get expanded
# to names like 'raspi_2.yaml' and 'raspi_0w.img.xz'.
BUILD_PLATFORMS := 0w_buster 2_buster 3_buster 4_buster \
		   armel_bullseye armhf_bullseye arm64_bullseye

platforms := $(addprefix raspi_,$(BUILD_PLATFORMS))
shasums: $(addsuffix .sha256,$(platforms)) $(addsuffix .xz.sha256,$(platforms))
xzimages: $(addsuffix .img.xz,$(platforms))
images: $(addsuffix .img,$(platforms))
yaml: $(addsuffix .yaml,$(platforms))

raspi_0w_buster.yaml: raspi_master.yaml
	cat raspi_master.yaml | sed "s/__ARCH__/armel/" | \
	sed "s/__LINUX_IMAGE__/linux-image-rpi/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-rpi\\/bcm*rpi-*.dtb/" |\
	sed "s/__RELEASE__/buster/" |\
	grep -v "__OTHER_APT_ENABLE__" |\
	sed "s/__HOST__/rpi0/" > $@

raspi_2_buster.yaml: raspi_master.yaml
	cat raspi_master.yaml | sed "s/__ARCH__/armhf/" | \
	sed "s/__LINUX_IMAGE__/linux-image-armmp/" | \
	grep -v "__EXTRA_PKGS__" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-armmp\\/bcm*rpi*.dtb/" |\
	sed "s/__OTHER_APT_ENABLE__//" |\
	sed "s/__RELEASE__/buster/" |\
	sed "s/__HOST__/rpi2/" > $@

raspi_3_buster.yaml: raspi_master.yaml
	cat raspi_master.yaml | sed "s/__ARCH__/arm64/" | \
	sed "s/__LINUX_IMAGE__/linux-image-arm64/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-arm64\\/broadcom\\/bcm*rpi*.dtb/" |\
	sed "s/__OTHER_APT_ENABLE__//" |\
	sed "s/__RELEASE__/buster/" |\
	sed "s/__HOST__/rpi3/" > $@

raspi_4_buster.yaml: raspi_master.yaml
	cat raspi_master.yaml | sed "s/__ARCH__/arm64/" | \
	sed "s#raspi3-firmware#raspi-firmware/buster-backports#" | \
	sed "s#apt-get update#echo 'APT::Default-Release \"buster\";' > /etc/apt/apt.conf\n      apt-get update#" | \
	sed "s#cmdline.txt#cmdline.txt\n      sed -i 's/cma=64M //' /boot/firmware/cmdline.txt\n      sed -i 's/cma=\\\$$CMA //' /etc/kernel/postinst.d/z50-raspi-firmware#" | \
	sed "s/__LINUX_IMAGE__/linux-image-arm64\/buster-backports/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211\/buster-backports/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-arm64\\/broadcom\\/bcm*rpi*.dtb/" |\
	sed "s/__RELEASE__/buster/" |\
	sed "s/__OTHER_APT_ENABLE__/deb http:\/\/deb.debian.org\/debian\/ buster-backports main contrib non-free # raspi 4 needs a kernel and raspi-firmware newer than buster's/" |\
	sed "s/__HOST__/rpi4/" > $@

raspi_armel_bullseye.yaml: raspi_master.yaml
	cat raspi_master.yaml | sed "s/__ARCH__/armel/" | \
	sed "s/__LINUX_IMAGE__/linux-image-rpi/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-rpi\\/bcm*rpi-*.dtb/" |\
	sed "s/__RELEASE__/bullseye/" |\
	grep -v "__OTHER_APT_ENABLE__" |\
	sed -e '/debian-security/ s/deb/# Uncomment after Bullseye becomes stable → deb/' |\
	sed "s/__HOST__/rpi-armel/" > $@

raspi_armhf_bullseye.yaml: raspi_master.yaml
	cat raspi_master.yaml | sed "s/__ARCH__/armhf/" | \
	sed "s/__LINUX_IMAGE__/linux-image-armmp/" | \
	grep -v "__EXTRA_PKGS__" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-armmp\\/bcm*rpi*.dtb/" |\
	sed "s/__OTHER_APT_ENABLE__//" |\
	sed "s/__RELEASE__/bullseye/" |\
	sed -e '/debian-security/ s/deb/# Uncomment after Bullseye becomes stable → deb/' |\
	sed "s/__HOST__/rpi-armhf/" > $@

raspi_arm64_bullseye.yaml: raspi_master.yaml
	cat raspi_master.yaml | sed "s/__ARCH__/arm64/" | \
	sed "s/__LINUX_IMAGE__/linux-image-arm64/" | \
	sed "s/__EXTRA_PKGS__/- firmware-brcm80211/" | \
	sed "s/__DTB__/\\/usr\\/lib\\/linux-image-*-arm64\\/broadcom\\/bcm*rpi*.dtb/" |\
	sed "s/__OTHER_APT_ENABLE__//" |\
	sed "s/__RELEASE__/bullseye/" |\
	sed -e '/debian-security/ s/deb/# Uncomment after Bullseye becomes stable → deb/' |\
	sed "s/__HOST__/rpi-arm64/" > $@

%.sha256: %.img.xz
	echo $@
	sha256sum $(@:sha256=img) > $@

%.xz.sha256: %.img.xz
	echo $@
	sha256sum $(@:xz.sha256=img.xz) > $@

%.img.xz: %.img
	xz -f -k -z -9 $(@:.xz=)

%.img: %.yaml
	touch $(@:.img=.log)
	time nice vmdb2 --verbose --rootfs-tarball=$(subst .img,.tar.gz,$@) --output=$@ $(subst .img,.yaml,$@) --log $(subst .img,.log,$@)
	chmod 0644 $@ $(@,.img=.log)

_ck_root:
	[ `whoami` = 'root' ] # Only root can summon vmdb2 ☹

_clean_yaml:
	rm -f $(addsuffix .yaml,$(platforms))
_clean_images:
	rm -f $(addsuffix .img,$(platforms))
_clean_xzimages:
	rm -f $(addsuffix .img.xz,$(platforms))
_clean_shasums:
	rm -f $(addsuffix .sha256,$(platforms)) $(addsuffix .xz.sha256,$(platforms))
_clean_logs:
	rm -f $(addsuffix .log,$(platforms))
_clean_tarballs:
	rm -f $(addsuffix .tar.gz,$(platforms))
clean: _clean_xzimages _clean_images _clean_shasums _clean_yaml _clean_tarballs _clean_logs

.PHONY: _ck_root _build_img clean _clean_images _clean_yaml _clean_tarballs _clean_logs
