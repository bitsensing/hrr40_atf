#
# Copyright 2020-2021 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#

include drivers/arm/gic/v3/gicv3.mk
include lib/libc/libc.mk
include lib/libfdt/libfdt.mk
include lib/xlat_tables_v2/xlat_tables.mk
include make_helpers/build_macros.mk

ERRATA_A53_855873	:= 1
ERRATA_A53_836870	:= 1
ERRATA_A53_1530924	:= 1

S32G_EMU		?= 0
$(eval $(call add_define_val,S32G_EMU,$(S32G_EMU)))

# Tools
HEXDUMP ?= xxd
SED ?= sed

S32G_DRAM_INLINE_ECC	?= 1
$(eval $(call add_define_val,S32G_DRAM_INLINE_ECC,$(S32G_DRAM_INLINE_ECC)))

DDR_DRV = drivers/nxp/s32g/ddr

ifeq ($(S32G_EMU),1)
DDR_DRV_SRCS := \
	${DDR_DRV}/emu/ddrss_emu.c \
	${DDR_DRV}/emu/ddrss_firmware_emu.c \
	${DDR_DRV}/emu/ddrss_regconf_emu.c \

else
DDR_DRV_SRCS += \
	${DDR_DRV}/ddr_init.c \
	${DDR_DRV}/ddr_utils_mmio.c \
	${DDR_DRV}/ddr_lp_mmio.c \
	${DDR_DRV}/ddr_lp_csr.c \
	${DDR_DRV}/ddrss_cfg.c \
	${DDR_DRV}/imem_cfg.c \

endif

ifeq ($(S32G_EMU),0)
include plat/nxp/s32/s32g/bl31_sram/bl31_sram.mk
include plat/nxp/s32/s32g/bl31_ssram/bl31_ssram.mk
endif

PLAT_INCLUDES		+= -Iplat/nxp/s32/s32g/include \
			   -Iplat/nxp/s32/s32g/bl31_sram/include \
			   -Iplat/nxp/s32/s32g/bl31_ssram/include \
			   -Iinclude/common/tbbr \
			   -Iinclude/plat/common \
			   -Iinclude/plat/arm/common \
			   -Iinclude/plat/arm/soc/common \
			   -Iinclude/lib \
			   -Iinclude/lib/libc \
			   -Iinclude/drivers \
			   -Iinclude/lib/psci \
			   -Iinclude/drivers/nxp/s32g \
			   -Idrivers \

BL2_AT_EL3		:= 1

PLAT_BL_COMMON_SOURCES	+= plat/nxp/s32/s32g/s32g_lowlevel_common.S \
			   plat/nxp/s32/s32g/s32g_mc_me.c \
			   plat/nxp/s32/s32g/s32g_ncore.c \
			   plat/nxp/s32/s32g/s32g_bl_common.c \
			   plat/nxp/s32/s32g/s32g_dt.c \
			   plat/nxp/s32/s32g/s32g_pinctrl.c \
			   plat/nxp/s32/s32g/s32g_clocks.c \
			   plat/nxp/s32/s32g/s32g_sramc.c \
			   plat/nxp/s32/s32g/s32g_sramc_asm.S \
			   plat/nxp/s32/s32g/s32g_linflexuart.c \
			   plat/nxp/s32/s32g/s32g_linflexuart_crash.S \
			   drivers/nxp/s32g/i2c/s32g_i2c.c \
			   drivers/delay_timer/delay_timer.c \
			   drivers/delay_timer/generic_delay_timer.c \
			   drivers/nxp/s32g/memory_pool.c \
			   drivers/nxp/s32g/clk/early_clocks.c \
			   drivers/nxp/s32g/clk/enable_clk.c \
			   drivers/nxp/s32g/clk/get_rate.c \
			   drivers/nxp/s32g/clk/plat_clk.c \
			   drivers/nxp/s32g/clk/s32g_clk.c \
			   drivers/nxp/s32g/clk/s32gen1_clk.c \
			   drivers/nxp/s32g/rst/s32gen1_rst.c \
			   drivers/nxp/s32g/clk/set_par_rate.c \
			   drivers/nxp/uart/linflexuart.c \
			   drivers/nxp/s32g/ocotp.c \
			   lib/utils/crc8.c \
			   plat/nxp/s32/s32g/s32g_vr5510.c \
			   drivers/nxp/s32g/pmic/vr5510.c \
			   common/fdt_wrappers.c \
			   ${GICV3_SOURCES} \
			   ${BL31SRAM_SRC_DUMP} \

BL2_SOURCES		+= plat/nxp/s32/s32g/s32g_lowlevel_bl2.S \
			   plat/nxp/s32/s32g/s32g_bl2_el3.c \
			   plat/nxp/s32/s32g/s32g_storage.c \
			   drivers/io/io_storage.c \
			   common/desc_image_load.c \
			   common/fdt_fixup.c \
			   drivers/mmc/mmc.c \
			   drivers/nxp/s32g/io/io_mmc.c \
			   drivers/nxp/s32g/io/io_memmap.c \
			   drivers/io/io_fip.c \
			   drivers/nxp/s32g/mmc/s32g_mmc.c \
			   ${BL31SSRAM_SRC_DUMP} \
			   ${DDR_DRV_SRCS} \
			   lib/optee/optee_utils.c \
			   ${XLAT_TABLES_LIB_SRCS} \

BL31_SOURCES		+= plat/nxp/s32/s32g/s32g_bl31.c \
			   plat/nxp/s32/s32g/s32g_psci.c \
			   plat/nxp/s32/s32g/s32g_resume.c \
			   plat/nxp/s32/s32g/s32g_pm.c \
			   plat/nxp/s32/s32g/s32g_svc.c \
			   plat/nxp/s32/s32g/s32g_scmi_clk.c \
			   plat/nxp/s32/s32g/s32g_scmi_rst.c \
			   plat/common/plat_psci_common.c \
			   plat/common/plat_gicv3.c \
			   drivers/nxp/s32g/s32g_wkpu.c \
			   drivers/nxp/s32g/clk/clk.c \
			   drivers/nxp/s32g/clk/fixed_clk.c \
			   drivers/nxp/s32g/clk/s32g_scmi_ids.c \
			   drivers/nxp/s32g/clk/s32gen1_scmi_clk.c \
			   drivers/nxp/s32g/clk/s32gen1_scmi_ids.c \
			   drivers/scmi-msg/base.c \
			   drivers/scmi-msg/clock.c \
			   drivers/scmi-msg/entry.c \
			   drivers/scmi-msg/reset_domain.c \

BL31_SOURCES		+= plat/nxp/s32/s32g/bl31_lowlevel.S \
			   plat/nxp/s32/s32g/include/plat_macros.S

BL31_SOURCES		+= ${XLAT_TABLES_LIB_SRCS}

DTC_FLAGS		+= -Wno-unit_address_vs_reg

all: check_dtc_version
check_dtc_version:
	$(eval DTC_VERSION_RAW = $(shell $(DTC) --version | cut -f3 -d" " \
							  | cut -f1 -d"-"))
	$(eval DTC_VERSION = $(shell echo $(DTC_VERSION_RAW) | sed "s/\./0/g"))
	@if [ ${DTC_VERSION} -lt 10406 ]; then \
		echo "$(DTC) version must be 1.4.6 or above"; \
		false; \
	fi

BL2_W_DTB		:= ${BUILD_PLAT}/bl2_w_dtb.bin
all: ${BL2_W_DTB}
${BL2_W_DTB}: bl2 dtbs
	@cp ${BUILD_PLAT}/fdts/${DTB_FILE_NAME} $@
	@dd if=${BUILD_PLAT}/bl2.bin of=$@ bs=1024 seek=8 status=none

# User defined parameters, for example:
# 	make FIP_MMC_OFFSET=0x5400 <...other parameters>
# These defines update only BL2's view of FIP AppBootCode:Code position.
# IVT header updates (e.g. mkimage application code offset) should be updated
# independently
# These offsets must be aligned to the block size of 512 bytes
FIP_MMC_OFFSET		?= 0x3400
$(eval $(call add_define,FIP_MMC_OFFSET))
FIP_QSPI_OFFSET		?= 0x3400
$(eval $(call add_define,FIP_QSPI_OFFSET))

# If FIP_MEM_OFFSET is defined, the FIP is not read from boot source (QSPI/MMC)
# but from this defined memory address.
# The use case is that M7 bootloader loads the FIP from storage at this SRAM
# location and BL2 will read from it without accessing the storage.
ifdef FIP_MEM_OFFSET
$(eval $(call add_define,FIP_MEM_OFFSET))
endif

FIP_MAXIMUM_SIZE	:= 0x400000
$(eval $(call add_define,FIP_MAXIMUM_SIZE))

FIP_ALIGN := 512
all: add_to_fip
add_to_fip: fip ${BL2_W_DTB}
	$(eval FIP_MAXIMUM_SIZE_10 = $(shell printf "%d\n" ${FIP_MAXIMUM_SIZE}))
	${Q}${FIPTOOL} update ${FIP_ARGS} \
		--tb-fw ${BUILD_PLAT}/bl2_w_dtb.bin \
		--soc-fw-config ${BUILD_PLAT}/fdts/${DTB_FILE_NAME} \
		${BUILD_PLAT}/${FIP_NAME}
	@echo "Added BL2 and DTB to ${BUILD_PLAT}/${FIP_NAME} successfully"
	${Q}${FIPTOOL} info ${BUILD_PLAT}/${FIP_NAME}
	$(eval ACTUAL_FIP_SIZE = $(shell \
				stat --printf="%s" ${BUILD_PLAT}/${FIP_NAME}))
	@if [ ${ACTUAL_FIP_SIZE} -gt ${FIP_MAXIMUM_SIZE_10} ]; then \
		echo "FIP image exceeds the maximum size of" \
		     "0x${FIP_MAXIMUM_SIZE}"; \
		false; \
	fi

DTB_BASE		:= 0x34300000
$(eval $(call add_define,DTB_BASE))
BL2_BASE		:= 0x34302000
$(eval $(call add_define,BL2_BASE))

all: call_mkimage
call_mkimage: add_to_fip
ifeq ($(MKIMAGE),)
	$(eval MKIMAGE = $(shell dirname $(BL33))/tools/mkimage)
endif
	@${MKIMAGE} -e ${BL2_BASE} -a ${DTB_BASE} -T s32gen1image \
		-d ${BUILD_PLAT}/${FIP_NAME} ${BUILD_PLAT}/fip.s32
	@echo "Generated ${BUILD_PLAT}/fip.s32 successfully"

# Disable the PSCI platform compatibility layer
ENABLE_PLAT_COMPAT	:= 0

MULTI_CONSOLE_API	:= 1
LOAD_IMAGE_V2		:= 1
USE_COHERENT_MEM	:= 0

# Set RESET_TO_BL31 to boot from BL31
PROGRAMMABLE_RESET_ADDRESS	:= 1
RESET_TO_BL31			:= 0
# We need SMP boot in order to make specific initializations such as
# secure GIC registers, which U-Boot and then Linux won't be able to.
COLD_BOOT_SINGLE_CPU		:= 0

ERRATA_SPECULATIVE_AT	:= 1

### Platform-specific defines ###
# Which LinFlexD to use as a UART device
S32G_LINFLEX_MODULE	:= 0
$(eval $(call add_define_val,S32G_LINFLEX_MODULE,$(S32G_LINFLEX_MODULE)))
# Sharing the LinFlexD UART is not always a safe option. Different drivers
# (e.g. Linux and TF-A) can configure the UART controller differently; even so,
# there is no hardware lock to prevent concurrent access to the device. For now,
# opt to suppress output (except for crash reporting). For debugging and other
# similarly safe contexts, output can be turned back on using this switch.
S32G_USE_LINFLEX_IN_BL31	?= 0
$(eval $(call add_define_val,S32G_USE_LINFLEX_IN_BL31,$(S32G_USE_LINFLEX_IN_BL31)))
# Whether we're going to run a hypervisor (EL2) or jump straight into the
# bootloader (EL1)
S32G_HAS_HV		?= 0
$(eval $(call add_define_val,S32G_HAS_HV,$(S32G_HAS_HV)))

BL2_EL3_STACK_ALIGNMENT :=	512
$(eval $(call add_define_val,BL2_EL3_STACK_ALIGNMENT,$(BL2_EL3_STACK_ALIGNMENT)))

### Devel & Debug options ###
CFLAGS			+= -O0
# Enable dump of processor register state upon exceptions while running BL31
CRASH_REPORTING		:= 1
# As verbose as it can be
LOG_LEVEL		?= 50

# If BL32_EXTRA1 option is present, include the binary it is pointing to
# in the FIP image
ifneq ($(BL32_EXTRA1),)
$(eval $(call TOOL_ADD_IMG,bl32_extra1,--tos-fw-extra1))
endif
