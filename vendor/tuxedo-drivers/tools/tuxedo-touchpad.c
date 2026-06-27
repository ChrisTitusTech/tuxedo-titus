// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Firmware touchpad switch for this TUXEDO InfinityBook Pro Gen7.
 *
 * The UNIW0001 touchpad exposes Microsoft's touchpad selective reporting
 * feature over hidraw. Writing 0x03 enables the touchpad and turns the
 * disable LED off; writing 0x00 disables touch and click reporting and turns
 * the disable LED on.
 */

#include <errno.h>
#include <fcntl.h>
#include <linux/hidraw.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <libudev.h>

static const uint8_t surface_button_switch_marker[] = {
	0x05, 0x0d, 0x09, 0x22, 0xa1, 0x00, 0x09, 0x57, 0x09, 0x58,
};

static void usage(const char *argv0)
{
	fprintf(stderr, "Usage: %s on|off|status [hidraw]\n", argv0);
}

static bool path_contains_uniw_touchpad(const char *syspath)
{
	return syspath && strstr(syspath, "i2c-UNIW0001:00") != NULL;
}

static char *find_touchpad_hidraw(void)
{
	struct udev *udev = udev_new();
	if (!udev)
		return NULL;

	struct udev_enumerate *enumerate = udev_enumerate_new(udev);
	if (!enumerate) {
		udev_unref(udev);
		return NULL;
	}

	char *devnode = NULL;
	udev_enumerate_add_match_subsystem(enumerate, "hidraw");
	if (udev_enumerate_scan_devices(enumerate) == 0) {
		struct udev_list_entry *devices = udev_enumerate_get_list_entry(enumerate);
		struct udev_list_entry *entry;

		udev_list_entry_foreach(entry, devices) {
			const char *syspath = udev_list_entry_get_name(entry);
			if (!path_contains_uniw_touchpad(syspath))
				continue;

			struct udev_device *dev = udev_device_new_from_syspath(udev, syspath);
			if (!dev)
				continue;

			const char *node = udev_device_get_devnode(dev);
			if (node)
				devnode = strdup(node);
			udev_device_unref(dev);
			if (devnode)
				break;
		}
	}

	udev_enumerate_unref(enumerate);
	udev_unref(udev);
	return devnode;
}

static int find_report_id(int fd)
{
	struct hidraw_report_descriptor desc = {0};

	if (ioctl(fd, HIDIOCGRDESCSIZE, &desc.size) < 0)
		return -1;
	if (ioctl(fd, HIDIOCGRDESC, &desc) < 0)
		return -1;

	const uint8_t *start = desc.value;
	const uint8_t *end = desc.value + desc.size;
	size_t marker_len = sizeof(surface_button_switch_marker);

	for (const uint8_t *p = start; p + marker_len < end; ++p) {
		if (memcmp(p, surface_button_switch_marker, marker_len) != 0)
			continue;

		for (const uint8_t *q = p + marker_len; q + 1 < end; ++q) {
			if (*q == 0x85)
				return *(q + 1);
		}
	}

	errno = ENODEV;
	return -1;
}

static int set_touchpad_state(const char *devnode, bool enabled)
{
	int fd = open(devnode, O_WRONLY | O_NONBLOCK);
	if (fd < 0)
		return -1;

	int report_id = find_report_id(fd);
	if (report_id < 0) {
		close(fd);
		return -1;
	}

	uint8_t report[2] = {
		(uint8_t)report_id,
		enabled ? 0x03 : 0x00,
	};
	int ret = ioctl(fd, HIDIOCSFEATURE(sizeof(report)), report);
	close(fd);
	return ret;
}

static int print_status(const char *devnode)
{
	int fd = open(devnode, O_WRONLY | O_NONBLOCK);
	if (fd < 0)
		return -1;

	int report_id = find_report_id(fd);
	close(fd);
	if (report_id < 0)
		return -1;

	printf("device=%s\n", devnode);
	printf("surface_button_switch=present\n");
	printf("feature_report_id=%d\n", report_id);
	return 0;
}

int main(int argc, char **argv)
{
	if (argc < 2 || argc > 3) {
		usage(argv[0]);
		return EXIT_FAILURE;
	}

	char *found = NULL;
	const char *devnode = NULL;
	if (argc == 3) {
		devnode = argv[2];
	} else {
		found = find_touchpad_hidraw();
		devnode = found;
	}

	if (!devnode) {
		fprintf(stderr, "No i2c-UNIW0001:00 hidraw touchpad found\n");
		return EXIT_FAILURE;
	}

	int ret;
	if (strcmp(argv[1], "on") == 0) {
		ret = set_touchpad_state(devnode, true);
	} else if (strcmp(argv[1], "off") == 0) {
		ret = set_touchpad_state(devnode, false);
	} else if (strcmp(argv[1], "status") == 0) {
		ret = print_status(devnode);
	} else {
		usage(argv[0]);
		free(found);
		return EXIT_FAILURE;
	}

	if (ret < 0) {
		fprintf(stderr, "%s: %s\n", devnode, strerror(errno));
		free(found);
		return EXIT_FAILURE;
	}

	free(found);
	return EXIT_SUCCESS;
}
