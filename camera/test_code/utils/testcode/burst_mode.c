/* =========================================================================
*             Texas Instruments OMAP(TM) Platform Software
*  (c) Copyright Texas Instruments, Incorporated.  All Rights Reserved.
*
*  Use of this software is controlled by the terms and conditions found
*  in the license agreement under which this software has been supplied.
* ========================================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <linux/videodev2.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <string.h>
#include "mach/isp_user.h"
#include <errno.h>

#define VIDEO_DEVICE1 "/dev/video1"
#define VIDEO_DEVICE2 "/dev/video2"

#define DEFAULT_PIXEL_FMT "YUYV"
#define DEFAULT_VIDEO_SIZE "QCIF"
#define DEFAULT_FILE_NAME "output.yuv"
#define DEFAULT_FRAMERATE 30

/* have to align at 32 bytes */
static void usage(void)
{
	printf("Burst Mode Test Case\n");
	printf("Usage: burst_mode [camDevice] [pixelFormat] [<sizeW> <sizeH>]"
		" [<numberOfFrames>] [<file>] [framerate] [<colorEffect>]\n");
	printf("   [camDevice] Camera device to be open\n\t 1:Micron sensor "
					"2:OV sensor 3:IMX046\n");
	printf("   [pixelFormat] set the pixelFormat to use. \n\tSupported: "
		"YUYV, UYVY, RGB565, RGB555, RGB565X, RGB555X, SGRBG10,"
		" SRGGB10, SBGGR10, SGBRG10 \n");
	printf("   [sizeW] Set the video width\n");
	printf("   [sizeH] Set the video heigth\n");
	printf("\tOptionally size can be specified using standard name sizes"
							"(VGA,PAL,etc)\n");
	printf("\tIf size is NOT specified QCIF used as default\n");
	printf("   [numberOfFrames] Number of Frames to be captured\n");
	printf("   [file] Optionally captured image can be saved to file "
								"<file>\n");
	printf("    If no file is specified output.yuv file is the default\n");
	printf("   [framerate] is the framerate to be used, if no value"
			" is given \n\t      %d fps is default\n",
			DEFAULT_FRAMERATE);
	printf("   [colorEffect] COLOR The image captured with "
						"no color effect\n");

	printf("		 BW	 The image captured with "
						"Black & White effect\n");
	printf("                 SEPIA   The image captured with Sepia "
								"effect\n");
	printf("                 If not specified COLOR effect is the "
							"default Option\n");
}

struct {
	void *start;
	size_t length;
} *cbuffers;

int main(int argc, char *argv[])
{
	struct v4l2_capability capability;
	struct v4l2_format cformat;
	struct v4l2_requestbuffers creqbuf;
	struct v4l2_buffer cfilledbuffer;
	struct v4l2_queryctrl queryctrl;
	struct v4l2_control control;
	struct omap34xxcam_sensor_info sens_info;
	int fd, i, j, ret, count = 1, memtype = V4L2_MEMORY_USERPTR;
	int fd_save = 0;
	int index = 1;
	int device = 1, framerate = DEFAULT_FRAMERATE;
	int colorLevel = V4L2_COLORFX_NONE;
	char *pixelFmt;
	char *fileName;
	__u32 total_w, pad_w;

	if ((argc > 1) && (!strcmp(argv[1], "?"))) {
		usage();
		return -EINVAL;
	}

	if (argc > index) {
		device = atoi(argv[index]);
		index++;
	}

	fd = open_cam_device(O_RDWR, device);
	if (fd <= 0) {
		printf("Could not open the cam device\n");
		return fd;
	}

	ret = ioctl(fd, VIDIOC_QUERYCAP, &capability);
	if (ret) {
		perror("VIDIOC_QUERYCAP");
		return ret;
	}
	if (capability.capabilities & V4L2_CAP_STREAMING)
		printf("The driver is capable of Streaming!\n");
	else {
		printf("The driver is not capable of Streaming!\n");
		return -EINVAL;
	}

	if (capability.capabilities & V4L2_CAP_VIDEO_CAPTURE)
		printf("The driver is capable of capturing!\n");
	else {
		printf("The driver is not capable of capturing!\n");
		return -EINVAL;
	}

	if (argc > index) {
		pixelFmt = argv[index];
		index++;
		if (argc > index) {
			ret = validateSize(argv[index]);
			if (ret == 0) {
				ret = cam_ioctl(fd, pixelFmt, argv[index]);
				if (ret < 0) {
					usage();
					return ret;
				}
			} else {
				index++;
				if (argc > (index)) {
					ret = cam_ioctl(fd, pixelFmt,
						argv[index-1], argv[index]);
					if (ret < 0) {
						usage();
						return ret;
					}
				} else {
					printf("Invalid size\n");
					usage();
					return ret;
				}
			}
			index++;
		} else {
			printf("Setting QCIF as video size, default value\n");
			ret = cam_ioctl(fd, pixelFmt, DEFAULT_VIDEO_SIZE);
			if (ret < 0)
				return ret;
		}
	} else {
		printf("Setting pixel format and video size with default"
								" values\n");
		ret = cam_ioctl(fd, DEFAULT_PIXEL_FMT, DEFAULT_VIDEO_SIZE);
		if (ret < 0)
			return ret;
	}


	if (argc > index)
		count = atoi(argv[index]);

	printf("Frames: %d\n", count);
	index++;

	if (count >= 32 || count <= 0) {
		printf("Camera driver only support max 32 buffers, "
			"you request %d\n", count);
		return -EINVAL;
	}

	if (argc > index)
		fileName = argv[index];
	else
		fileName = DEFAULT_FILE_NAME;

	fd_save = creat(fileName,
			O_RDWR | S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
	if (fd_save <= 0) {
		printf("Can't create file %s\n", fileName);
		fd_save = 0;
	} else {
		printf("The captured frames will be saved into: %s\n",
		       fileName);
	}

	index++;
	if (argc > index) {
		framerate = atoi(argv[index]);
		if (framerate == 0) {
			printf("Invalid framerate value, Using default "
			       "framerate = %d\n", DEFAULT_FRAMERATE);
			framerate = DEFAULT_FRAMERATE;
		}
		index++;
	}

	if (argc > index) {
		if (!strcmp(argv[index], "COLOR")) {
			colorLevel = V4L2_COLORFX_NONE;
			printf("Using default color level: %d\n", colorLevel);
		}
		if (!strcmp(argv[index], "BW")) {
			colorLevel = V4L2_COLORFX_BW;
			printf("Using black & white color level: %d\n",
			       colorLevel);
		} else {
			if (!strcmp(argv[index], "SEPIA")) {
				colorLevel = V4L2_COLORFX_SEPIA;
				printf("Using SEPIA color level: %d\n",
				       colorLevel);
			} else {
				if (!strcmp(argv[index], "SEPIA"))
					colorLevel = V4L2_COLORFX_SEPIA;
				else {
					printf("Invalid Color Effect: argv[%d]"
					       "=%s", index, argv[index]);
					usage();
					return -EINVAL;
				}
			}
		}
	}

	/*************************************************************/
	/* Set Frame Rate */

	ret = setFramerate(fd, framerate);
	if (ret < 0) {
		printf("Error setting framerate = %d\n", framerate);
		return ret;
	}


	/********************************************************/
	/* Get Camera Image Format & display */

	cformat.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	ret = ioctl(fd, VIDIOC_G_FMT, &cformat);
	if (ret < 0) {
		perror("VIDIOC_G_FMT");
		return ret;
	}

	/* Note: If no padding then bytesperline can be zero */
	total_w = (cformat.fmt.pix.bytesperline == 0)
		? cformat.fmt.pix.width
		: cformat.fmt.pix.bytesperline>>1;

	/* Calculate size of padding in pixels */
	pad_w = (cformat.fmt.pix.bytesperline == 0)
		? 0
		: ((cformat.fmt.pix.bytesperline>>1)-cformat.fmt.pix.width);

	printf("Camera Image:\n");
	printf("  width = %d, height = %d\n",
		cformat.fmt.pix.width, cformat.fmt.pix.height);
	printf("  padding = %d pixels\n", pad_w);
	printf("  size = %d bytes\n", cformat.fmt.pix.sizeimage);
	printf("  Total Dimensions: %d x %d\n",
		total_w, cformat.fmt.pix.height);

	/********************************************************/

	creqbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	creqbuf.memory = memtype;
	creqbuf.count = count;

	printf("Requesting %d buffers of type %s\n", creqbuf.count,
		(memtype == V4L2_MEMORY_USERPTR) ? "V4L2_MEMORY_USERPTR" :
						"V4L2_MEMORY_MMAP");
	ret = ioctl(fd, VIDIOC_REQBUFS, &creqbuf);
	if (ret) {
		perror("VIDEO_REQBUFS");
		return ret;
	}
	printf("Camera Driver allowed buffers reqbuf.count = %d\n",
		creqbuf.count);
	if (creqbuf.count != count)
		count = creqbuf.count;

	cbuffers = calloc(creqbuf.count, sizeof(*cbuffers));

	/* mmap driver memory or allocate user memory, and queue each buffer */
	for (i = 0; i < creqbuf.count; ++i) {
		struct v4l2_buffer buffer;
		buffer.type = creqbuf.type;
		buffer.memory = creqbuf.memory;
		buffer.index = i;
		ret = ioctl(fd, VIDIOC_QUERYBUF, &buffer);
		if (ret) {
			perror("VIDIOC_QUERYBUF");
			return ret;
		}
		if (memtype == V4L2_MEMORY_USERPTR) {
			cbuffers[i].length = buffer.length;
			posix_memalign(&cbuffers[i].start, 0x1000,
				       cbuffers[i].length);
			buffer.m.userptr =
			    (unsigned int)cbuffers[i].start;
			printf("User Buffer [%d].start = %x  length = %d\n",
				 i, cbuffers[i].start, cbuffers[i].length);
		} else {
			cbuffers[i].length = buffer.length;
			cbuffers[i].start =
			    mmap(NULL, buffer.length, PROT_READ | PROT_WRITE,
				 MAP_SHARED, fd, buffer.m.offset);
			if (cbuffers[i].start == MAP_FAILED) {
				perror("mmap");
				return -ENOMEM;
			}
			printf("Mapped Buffers[%d].start = %x  length = %d\n",
				i, cbuffers[i].start, cbuffers[i].length);
			buffer.m.userptr = (unsigned int)cbuffers[i].start;
			buffer.length = cbuffers[i].length;
		}
		ret = ioctl(fd, VIDIOC_QBUF, &buffer);
		if (ret) {
			perror("CAMERA VIDIOC_QBUF");
			return ret;
		}
	}

	/* capture 1000 frames or when we hit the passed number of frames */
	cfilledbuffer.type = creqbuf.type;
	cfilledbuffer.memory = memtype;

	/* query color capability*/
	memset(&queryctrl, 0, sizeof(queryctrl));

	queryctrl.id = V4L2_CID_COLORFX;
	ret = ioctl(fd, VIDIOC_QUERYCTRL, &queryctrl);
	if (ret) {
		printf("COLOR effect is not supported!\n");
	} else {
		control.id = V4L2_CID_COLORFX;
		ret = ioctl(fd, VIDIOC_G_CTRL, &control);
		if (ret)
			printf("VIDIOC_G_CTRL failed!\n");

		printf("Color effect at the beginning of the test is"
			" supported, min %d, max %d.\nCurrent color is"
			" level is %d\n",
			queryctrl.minimum, queryctrl.maximum, control.value);

		control.value = colorLevel;
		ret = ioctl(fd, VIDIOC_S_CTRL, &control);
		if (ret)
			printf("VIDIOC_S_CTRL COLOR failed!\n");

		control.id = V4L2_CID_COLORFX;
		ret = ioctl(fd, VIDIOC_G_CTRL, &control);
		if (ret)
			printf("VIDIOC_G_CTRL failed!\n");

		printf("Color effect values after setup is supported, min %d,"
			"max %d.\nCurrent color is level is %d\n",
			queryctrl.minimum, queryctrl.maximum, control.value);
	}

	/********************************************************/
	/* Get Sensor info using SENSOR_INFO ioctl */

	printf("Getting Sensor Info...\n");
	ret = ioctl(fd, VIDIOC_PRIVATE_OMAP34XXCAM_SENSOR_INFO, &sens_info);
	if (ret) {
		printf("VIDIOC_PRIVATE_OMAP34XXCAM_SENSOR_INFO not supported.\n");
	} else {
		printf("  Pixel clk:   %d Hz\n", sens_info.current_xclk);
		printf("  Full size:   %d x %d\n",
			sens_info.full_size.width,
			sens_info.full_size.height);
		printf("  Active size: %d x %d\n",
			sens_info.active_size.width,
			sens_info.active_size.height);
	}

	/* turn on streaming */
	ret = ioctl(fd, VIDIOC_STREAMON, &creqbuf.type);
	if (ret) {
		perror("VIDIOC_STREAMON");
		return ret;
	}

	/********************************************************/

	i = 0;
	while (i < 1000) {
		/* De-queue the next avaliable buffer */
		ret = ioctl(fd, VIDIOC_DQBUF, &cfilledbuffer);
		if (ret) {
			perror("VIDIOC_DQBUF");
			return ret;
		}

		i++;

		if (i == count) {
			printf("Cancelling the streaming capture...\n");
			creqbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
			ret = ioctl(fd, VIDIOC_STREAMOFF, &creqbuf.type);
			if (ret) {
				perror("VIDIOC_STREAMOFF");
				return ret;
			}
			printf("Done\n");
			break;
		}

		ret = ioctl(fd, VIDIOC_QBUF, &cfilledbuffer);
		if (ret) {
			perror("CAM VIDIOC_QBUF");
			return ret;
		}
	}
	/* we didn't turn off streaming yet */
	if (count == -1) {
		creqbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		ret = ioctl(fd, VIDIOC_STREAMOFF, &creqbuf.type);
		if (ret) {
			perror("VIDIOC_STREAMOFF");
			return ret;
		}
	}

	printf("Captured %d frames!\n", i);
	printf("Image Frame Size:  %u x %u\n",
		cformat.fmt.pix.width, cformat.fmt.pix.height);
	printf("Output Frame Size: %u x %u  (%d pixels padding)\n",
		total_w, cformat.fmt.pix.height, pad_w);

	printf("Start writing to file\n");
	if (fd_save > 0) {
		for (i = 0; i < count; i++) {
			void *start = cbuffers[i].start;
			/* Crop padding data */
			for (j = 0; j < cformat.fmt.pix.height; j++) {
				void *start = (void *)((unsigned int)cbuffers[i].start +
							(total_w * 2 * j));

				write(fd_save, start, (cformat.fmt.pix.width * 2));
			}
		}
	}
	printf("Completed writing to file: %s\n", fileName);
	for (i = 0; i < creqbuf.count; i++) {
		if (cbuffers[i].start) {
			if (memtype == V4L2_MEMORY_USERPTR)
				free(cbuffers[i].start);
			else
				munmap(cbuffers[i].start, cbuffers[i].length);
		}
	}

	free(cbuffers);
	close(fd);
	if (fd_save > 0)
		close(fd_save);
}
