/*
 * Copyright 2019-2022 NXP
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <lib/mmio.h>
#include "s32g_clocks.h"
#include "s32_linflexuart.h"
#include "s32_storage.h"
#include "s32g_mc_rgm.h"
#include "s32g_mc_me.h"
#include "bl31_ssram.h"
#include "s32_bl2_el3.h"
#include "s32g_bl_common.h"
#include <plat/nxp/s32g/bl31_ssram/ssram_mailbox.h>
#include "s32_sramc.h"
#if S32G_EMU == 1
#include <ddr/ddrss.h>
#else
#include <ddr/ddr_init.h>
#include <drivers/nxp/s32/ddr/ddr_lp.h>
#endif

static bl_mem_params_node_t s32g_bl2_mem_params_descs[6];
REGISTER_BL_IMAGE_DESCS(s32g_bl2_mem_params_descs)

static void clear_reset_cause(void)
{
	uint32_t mc_rgm_des = mmio_read_32(MC_RGM_DES);

	mmio_write_32(MC_RGM_DES, mc_rgm_des);
}

static enum reset_cause get_reset_cause(void)
{
	uint32_t mc_rgm_des = mmio_read_32(MC_RGM_DES);

	if (mc_rgm_des & DES_F_POR)
		return CAUSE_POR;

	if (mc_rgm_des & DES_F_DR_ANY) {
		if (mmio_read_32(MC_RGM_RDSS) & RDSS_DES_RES)
			return CAUSE_DESTRUCTIVE_RESET_DURING_STANDBY;
		else
			return CAUSE_DESTRUCTIVE_RESET_DURING_RUN;
	}

	if (mmio_read_32(MC_RGM_FES) & FES_F_FR_ANY) {
		if (mmio_read_32(MC_RGM_RDSS) & RDSS_FES_RES)
			return CAUSE_FUNCTIONAL_RESET_DURING_STANDBY;
		else
			return CAUSE_FUNCTIONAL_RESET_DURING_RUN;
	}

	if (mmio_read_32(MC_ME_MODE_STAT) & MODE_STAT_PREV_MODE)
		return CAUSE_WAKEUP_DURING_STANDBY;

	return CAUSE_ERROR;
}

static const char *get_reset_cause_str(enum reset_cause reset_cause)
{
	static const char * const names[] = {
		[CAUSE_POR] = "Power-On Reset",
		[CAUSE_DESTRUCTIVE_RESET_DURING_RUN] = "Destructive Reset (RUN)",
		[CAUSE_DESTRUCTIVE_RESET_DURING_STANDBY] = "Destructive Reset (STBY)",
		[CAUSE_FUNCTIONAL_RESET_DURING_RUN] = "Functional Reset (RUN)",
		[CAUSE_FUNCTIONAL_RESET_DURING_STANDBY] = "Functional Reset (STBY)",
		[CAUSE_WAKEUP_DURING_STANDBY] = "Wakeup (STBY)",
		[CAUSE_ERROR] = "Error",
	};

	if (reset_cause >= ARRAY_SIZE(names))
		return "Unknown cause";

	return names[reset_cause];
}

#if S32G_EMU == 0
static void resume_bl31(struct s32g_ssram_mailbox *ssram_mb)
{
	s32g_warm_entrypoint_t resume_entrypoint;
	uintptr_t csr_addr;

	resume_entrypoint = ssram_mb->bl31_warm_entrypoint;
	csr_addr = (uintptr_t)&ssram_mb->csr_settings[0];

	s32_enable_a53_clock();
	s32_enable_ddr_clock();
	ddrss_to_normal_mode(csr_addr);

	resume_entrypoint();
}
#endif

#if S32G_EMU == 1
static void skip_emu_images(bl_mem_params_node_t *params, size_t size)
{
	unsigned int image_id;
	size_t i;

	for (i = 0; i < size; i++) {
		image_id = params[i].image_id;

		if (image_id == BL31_IMAGE_ID || image_id == BL33_IMAGE_ID)
			params[i].image_info.h.attr |=
			    IMAGE_ATTRIB_SKIP_LOADING;
	}
}
#endif

void bl2_el3_early_platform_setup(u_register_t arg0, u_register_t arg1,
				  u_register_t arg2, u_register_t arg3)
{
	enum reset_cause reset_cause;
	size_t index = 0;
	bl_mem_params_node_t *params = s32g_bl2_mem_params_descs;

	reset_cause = get_reset_cause();
	clear_reset_cause();

	/* No resume on emulator */
#if S32G_EMU == 0
	struct s32g_ssram_mailbox *ssram_mb = (void *)BL31SSRAM_MAILBOX;

	if ((reset_cause == CAUSE_WAKEUP_DURING_STANDBY) &&
	    !ssram_mb->short_boot) {
		/* Trampoline to bl31_warm_entrypoint */
		resume_bl31(ssram_mb);
		panic();
	}
#endif

	s32_early_plat_init(false);
	console_s32_register();
	s32_io_setup();

	NOTICE("Reset status: %s\n", get_reset_cause_str(reset_cause));

	add_fip_img_to_mem_params_descs(params, &index);
	add_bl31_img_to_mem_params_descs(params, &index);
	add_bl32_img_to_mem_params_descs(params, &index);
	add_bl32_extra1_img_to_mem_params_descs(params, &index);
	add_bl33_img_to_mem_params_descs(params, &index);
	add_invalid_img_to_mem_params_descs(params, &index);

#if S32G_EMU == 1
	skip_emu_images(params, index);
#endif

	bl_mem_params_desc_num = index;
}

#if S32G_EMU == 0
static void copy_bl31ssram_image(void)
{
	/* Copy bl31 ssram stage. This includes IVT */
	memcpy((void *)S32G_SSRAM_BASE, bl31ssram, bl31ssram_len);
}
#endif

void bl2_el3_plat_arch_setup(void)
{
	uint32_t ret;

#if S32G_EMU == 0
	ret = s32_el3_mmu_fixup();
	if (ret)
		panic();

	dt_init_ocotp();
	dt_init_pmic();

	ret = pmic_setup();
	if (ret)
		ERROR("Failed to disable VR5510 watchdog\n");

	s32_sram_clear(S32_BL33_IMAGE_BASE, DTB_BASE);
	/* Clear only the necessary part for the FIP header. The rest will
	 * be cleared in bl2_plat_handle_post_image_load, before loading
	 * the entire FIP image.
	 */
	s32_sram_clear(FIP_BASE, FIP_BASE + FIP_HEADER_SIZE);

	s32_ssram_clear();

	copy_bl31ssram_image();

	clear_swt_faults();
#endif

	/* This will also populate CSR section from bl31ssram */
	ret = ddr_init();
	if (ret)
		panic();
}

#if S32G_EMU == 1
void bl2_plat_preload_setup(void)
{
	printf("Now it's time to load the following images:\n");
	printf("BL31 @ 0x%x\n", BL31_BASE);
	printf("U-Boot @ 0x%x\n", BL33_BASE);

	__asm__ volatile("b .");
}
#endif
