#
# Copyright (c) 2018-2025 TUXEDO Computers GmbH <tux@tuxedocomputers.com>
#
# This file is part of tuxedo-drivers.
#
# tuxedo-drivers is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2
# of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

.PHONY: all module-build touchpad-tool install install-dkms install-assets clean dkms-build dkms-clean package package-rpm

PACKAGE_NAME := tuxedo-ibp-gen7-drivers
PACKAGE_VERSION := 4.22.2-fedora-ibp7.1
KERNELRELEASE ?= $(shell uname -r)
KDIR := /lib/modules/$(KERNELRELEASE)/build
KBUILD_DIR := $(CURDIR)
DKMS_SOURCE_DIR := /usr/src/$(PACKAGE_NAME)-$(PACKAGE_VERSION)
PKG_CONFIG ?= pkg-config
CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra

all: touchpad-tool module-build

module-build:
	$(MAKE) -C $(KDIR) M=$(KBUILD_DIR) modules

touchpad-tool:
	mkdir -p build
	$(CC) $(CFLAGS) $(shell $(PKG_CONFIG) --cflags libudev) \
		-o build/tuxedo-touchpad tools/tuxedo-touchpad.c \
		$(shell $(PKG_CONFIG) --libs libudev)

install: install-assets install-dkms

install-assets: touchpad-tool
	cp -r --no-preserve=ownership files/usr/. /usr/
	install -Dm755 build/tuxedo-touchpad /usr/local/bin/tuxedo-touchpad

install-dkms:
	rm -rf $(DKMS_SOURCE_DIR)
	install -d $(DKMS_SOURCE_DIR)
	cp -r --no-preserve=ownership Kbuild Makefile dkms.conf src $(DKMS_SOURCE_DIR)/
	dkms add -m $(PACKAGE_NAME) -v $(PACKAGE_VERSION) || true
	dkms build --force -m $(PACKAGE_NAME) -v $(PACKAGE_VERSION) -k $(KERNELRELEASE)
	dkms install --force -m $(PACKAGE_NAME) -v $(PACKAGE_VERSION) -k $(KERNELRELEASE)
	rm -rf /lib/modules/$(KERNELRELEASE)/updates/src
	depmod -a $(KERNELRELEASE)

dkms-build:
	$(MAKE) -C $(KDIR) M=$(KBUILD_DIR) modules

dkms-clean:
	$(MAKE) -C $(KDIR) M=$(KBUILD_DIR) clean

clean:
	$(MAKE) -C $(KDIR) M=$(KBUILD_DIR) clean
	rm -rf build/

package: package-rpm

package-rpm:
	simple-package-creator --output-dir build-rpm --formats RPM DKMS
	simple-package-tools build rpm --dir build-rpm --no-build-deps
