#
# Copyright 2022 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#

include plat/nxp/s32/s32g/s32g2/s32g2.mk

S32_BOARD_PATH		:= ${PLAT_SOC_PATH}/s32g2xxaevb

PLAT_INCLUDES		+= -I${S32_BOARD_PATH}/include \

PLAT_BL_COMMON_SOURCES +=      ${PLAT_SOC_PATH}/s32g2_vr5510.c \

DTB_FILE_NAME		?= fsl-s32g2xxa-evb.dtb
