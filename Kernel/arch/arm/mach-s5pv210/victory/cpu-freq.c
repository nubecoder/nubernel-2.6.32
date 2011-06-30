/*
 *  linux/arch/arm/plat-s5pc11x/s5pc11x-cpufreq.c
 *
 *  CPU frequency scaling for S5PC110
 *
 *  Copyright (C) 2008 Samsung Electronics
 *
 *  Based on cpu-sa1110.c, Copyright (C) 2001 Russell King
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/sched.h>
#include <linux/delay.h>
#include <linux/init.h>
#include <linux/err.h>
#include <linux/clk.h>
#include <linux/io.h>

#include <asm/system.h>

#include <mach/hardware.h>
#include <mach/map.h>

#include <mach/regs-clock.h>
#include <mach/cpu-freq-v210.h>
#include <plat/pll.h>
#include <plat/clock.h>
#ifdef CONFIG_HAS_WAKELOCK
#include <linux/wakelock.h>
#include <linux/earlysuspend.h>
#include <linux/suspend.h>
#endif

#define ENABLE_DVFS_LOCK_HIGH 1
#define USE_DVS
//#define GPIO_BASED_DVS

#define DBG(fmt...)
//#define DBG(fmt...) printk(fmt)

#ifdef CONFIG_MACH_S5PC110_ARIES_OC
#if 0 // not using above 1.4GHz
extern int active_states[13];
#else
extern int active_states[11];
#endif // end not using above 1.4GHz
#else // no OC
extern int active_states[7];
#endif // end CONFIG_MACH_S5PC110_ARIES_OC

unsigned int dvfs_change_direction;
#define CLIP_LEVEL(a, b) (a > b ? b : a)

unsigned int MAXFREQ_LEVEL_SUPPORTED = 4;
unsigned int S5PC11X_MAXFREQLEVEL = 4;
unsigned int S5PC11X_FREQ_TAB;
static spinlock_t g_dvfslock = SPIN_LOCK_UNLOCKED;
static unsigned int s5pc11x_cpufreq_level = 3;
unsigned int s5pc11x_cpufreq_index = 4;

static char cpufreq_governor_name[CPUFREQ_NAME_LEN] = "conservative";// default governor
static char userspace_governor[CPUFREQ_NAME_LEN] = "userspace";
static char conservative_governor[CPUFREQ_NAME_LEN] = "conservative";
int s5pc11x_clk_dsys_psys_change(int index);
int s5pc11x_armclk_set_rate(struct clk *clk, unsigned long rate);

unsigned int prevIndex = 0;

static struct clk * mpu_clk;
#ifdef CONFIG_CPU_FREQ_LOG
static void inform_dvfs_clock_status(struct work_struct *work);
static DECLARE_DELAYED_WORK(dvfs_info_print_work, inform_dvfs_clock_status);
#endif
#if ENABLE_DVFS_LOCK_HIGH
unsigned int g_dvfs_high_lock_token = 0;
static DEFINE_MUTEX(dvfs_high_lock);
unsigned int g_dvfs_high_lock_limit = 4;
unsigned int g_dvfslockval[NUMBER_OF_LOCKTOKEN];
bool g_dvfs_fix_lock_limit = false; // global variable to avoid up frequency scaling 

#endif //ENABLE_DVFS_LOCK_HIGH

extern int store_up_down_threshold(unsigned int down_threshold_value,
				unsigned int up_threshold_value);

/* frequency */
static struct cpufreq_frequency_table s5pc110_freq_table_1GHZ[] = {
#ifdef CONFIG_MACH_S5PC110_ARIES_OC
#if 0 // not using above 1.4GHz
	{0, 1600*1000},
	{1, 1500*1000},
	{2, 1400*1000},
	{3, 1300*1000},
	{4, 1200*1000},
	{5, 1120*1000},
	{6, 1000*1000},
	{7, 900*1000},
	{8, 800*1000},
	{9, 600*1000},
	{10, 400*1000},
	{11, 200*1000},
	{12, 100*1000},
	{0, CPUFREQ_TABLE_END},
#else
	{0, 1400*1000},
	{1, 1300*1000},
	{2, 1200*1000},
	{3, 1120*1000},
	{4, 1000*1000},
	{5, 900*1000},
	{6, 800*1000},
	{7, 600*1000},
	{8, 400*1000},
	{9, 200*1000},
	{10, 100*1000},
	{0, CPUFREQ_TABLE_END},
#endif // end not using above 1.4GHz
#else // no OC
	{0, 1000*1000},
	{1, 900*1000},
	{2, 800*1000},
	{3, 600*1000},
	{4, 400*1000},
	{5, 200*1000},
	{6, 100*1000},
	{0, CPUFREQ_TABLE_END},
#endif // end CONFIG_MACH_S5PC110_ARIES_OC
};

/*Assigning different index for fast scaling up*/
static unsigned char transition_state_1GHZ[][2] = {
#ifdef CONFIG_MACH_S5PC110_ARIES_OC
#if 0 // not using above 1.4GHz
	{1, 0},   //Down 0  to 1  Up 0  to 0
	{2, 0},   //Down 1  to 2  Up 1  to 0
	{3, 1},   //Down 2  to 3  Up 2  to 1
	{4, 2},   //Down 3  to 4  Up 3  to 2
	{5, 3},   //Down 4  to 5  Up 4  to 3
	{6, 4},   //Down 5  to 6  Up 5  to 4
	{7, 5},   //Down 6  to 7  Up 6  to 5
	{8, 6},   //Down 7  to 8  Up 7  to 6
	{9, 7},   //Down 8  to 9  Up 8  to 7
	{10, 8},  //Down 9  to 10 Up 9  to 8
	{11, 9},  //Down 10 to 11 Up 10 to 9
	{12, 10}, //Down 11 to 12 Up 11 to 10
	{12, 11}, //Down 12 to 12 Up 12 to 11
#else
	{1, 0},   //Down 0  to 1  Up 0  to 0
	{2, 0},   //Down 1  to 2  Up 1  to 0
	{3, 1},   //Down 2  to 3  Up 2  to 1
	{4, 2},   //Down 3  to 4  Up 3  to 2
	{5, 3},   //Down 4  to 5  Up 4  to 3
	{6, 4},   //Down 5  to 6  Up 5  to 4
	{7, 5},   //Down 6  to 7  Up 6  to 5
	{8, 6},   //Down 7  to 8  Up 7  to 6
	{9, 7},   //Down 8  to 9  Up 8  to 7
	{10, 8},  //Down 9  to 10 Up 9  to 8
	{10, 9},  //Down 10 to 10 Up 10 to 9
#endif // end not using above 1.4GHz
#else // no OC
	{1, 0}, //Down 0 to 1  Up 0 to 0
	{2, 0}, //Down 1 to 2  Up 1 to 0
	{3, 1}, //Down 2 to 3  Up 2 to 1
	{4, 2}, //Down 3 to 4  Up 3 to 2
	{5, 3}, //Down 4 to 5  Up 4 to 3
	{6, 4}, //Down 5 to 6  Up 5 to 4
	{6, 5}, //Down 6 to 6  Up 6 to 5
#endif // end CONFIG_MACH_S5PC110_ARIES_OC
};

/* frequency */
static struct cpufreq_frequency_table s5pc110_freq_table_1d2GHZ[] = {
	{0, 1200*1000},
	{1, 1000*1000},
	{2, 800*1000},
	{3, 400*1000},
	{4, 200*1000},
	{5, 100*1000},
	{0, CPUFREQ_TABLE_END},
};

/*Assigning different index for fast scaling up*/
static unsigned char transition_state_1d2GHZ[][2] = {
	{1, 0}, //Down 0 to 1  Up 0 to 0
	{2, 0}, //Down 1 to 2  Up 1 to 0
	{3, 1}, //Down 2 to 3  Up 2 to 1
	{4, 2}, //Down 3 to 4  Up 3 to 2
	{5, 3}, //Down 4 to 5  Up 4 to 3
	{5, 4}, //Down 5 to 5  Up 5 to 4
};

static unsigned char (*transition_state[2])[2] = {
	transition_state_1GHZ,
	transition_state_1d2GHZ,
};

static struct cpufreq_frequency_table *s5pc110_freq_table[] = {
	s5pc110_freq_table_1GHZ,
	s5pc110_freq_table_1d2GHZ,
};

unsigned int s5pc110_thres_table_1GHZ[][2] = {
#ifdef CONFIG_MACH_S5PC110_ARIES_OC
#if 0 // not using above 1.4GHz
	{55, 80}, //1600
	{55, 90}, //1500
	{55, 90}, //1400
	{55, 90}, //1300
	{55, 90}, //1200
	{55, 90}, //1120
	{55, 90}, //1000
	{60, 80}, //900
	{60, 80}, //800
	{60, 80}, //600
	{60, 80}, //400
	{60, 80}, //200
	{60, 80}, //100
#else
	{55, 90}, //1400
	{55, 90}, //1300
	{55, 90}, //1200
	{55, 90}, //1120
	{55, 90}, //1000
	{60, 80}, //900
	{60, 80}, //800
	{60, 80}, //600
	{60, 80}, //400
	{60, 80}, //200
	{60, 80}, //100
#endif // end not using above 1.4GHz
#else // no OC
	{55, 80}, //1000
	{50, 90}, //900
	{50, 90}, //800
	{50, 90}, //600
	{40, 90}, //400
	{40, 90}, //200
	{20, 80}, //100
#endif // end CONFIG_MACH_S5PC110_ARIES_OC
};

static unsigned int s5pc110_thres_table_1d2GHZ[][2] = {
	{55, 80}, //1200
	{50, 90}, //1000
	{50, 90}, //800
	{40, 90}, //400
	{30, 80}, //200
	{20, 70}, //100
};

static unsigned int  (*s5pc110_thres_table[2])[2] = {
	s5pc110_thres_table_1GHZ,
	s5pc110_thres_table_1d2GHZ,
};

/*return performance level */
static int get_dvfs_perf_level(enum freq_level_states freq_level, unsigned int *perf_level)
{
	unsigned int freq=0, index = 0;
	struct cpufreq_frequency_table *freq_tab = s5pc110_freq_table[S5PC11X_FREQ_TAB];
	switch(freq_level)
	{
#if CONFIG_MACH_S5PC110_ARIES_OC
#if 0 // not using above 1.4GHz
	case LEV_1600MHZ:
		freq = 1600 * 1000;
		break;
	case LEV_1500MHZ:
		freq = 1500 * 1000;
		break;
#endif // end not using above 1.4GHz
	case LEV_1400MHZ:
		freq = 1400 * 1000;
		break;
	case LEV_1300MHZ:
		freq = 1300 * 1000;
		break;
	case LEV_1200MHZ:
		freq = 1200 * 1000;
		break;
	case LEV_1120MHZ:
		freq = 1120 * 1000;
		break;
#endif // end CONFIG_MACH_S5PC110_ARIES_OC
	case LEV_1000MHZ:
		freq = 1000 * 1000;
		break;
	case LEV_900MHZ:
		freq = 900 * 1000;
		break;
	case LEV_800MHZ:
		freq = 800 * 1000;
		break;
	case LEV_600MHZ:
		freq = 600 * 1000;
		break;
	case LEV_400MHZ:
		freq = 400 * 1000;
		break;
	case LEV_200MHZ:
		freq = 200 * 1000;
		break;
	case LEV_100MHZ:
		freq = 100 * 1000;
		break;
	default:
		printk(KERN_ERR "Invalid freq level\n");
		return -EINVAL;
	}
	while((freq_tab[index].frequency != CPUFREQ_TABLE_END) &&
		(freq_tab[index].frequency != freq)) {
		index++;
	}
	if(freq_tab[index].frequency == CPUFREQ_TABLE_END)
	{
		printk(KERN_ERR "Invalid freq table\n");
		return -EINVAL;
	}

	*perf_level = freq_tab[index].index;
	return 0;
}

extern int exp_update_states;

void update_transition_states()
{
	u32 i, prev_j; int j;

	for(i=0;i<S5PC11X_MAXFREQLEVEL;i++) { //down
		for(j=i+1;j<S5PC11X_MAXFREQLEVEL+1;j++)
			if(active_states[j]) {
				transition_state[S5PC11X_FREQ_TAB][i][0]=j;
				j=S5PC11X_MAXFREQLEVEL+1;
			} else {
				transition_state[S5PC11X_FREQ_TAB][i][0]=i;
			}
	}
	transition_state[S5PC11X_FREQ_TAB][S5PC11X_MAXFREQLEVEL][0]=S5PC11X_MAXFREQLEVEL;

	prev_j=0;
	for(i=S5PC11X_MAXFREQLEVEL;i>0;i--) { //up
		for(j=i-1;j>-1;j--)
			if(active_states[j]) {
				transition_state[S5PC11X_FREQ_TAB][i][1]=j;
				prev_j=j;
				j=-1;
			} else {
				transition_state[S5PC11X_FREQ_TAB][i][1]=prev_j;
			}
	}
	transition_state[S5PC11X_FREQ_TAB][0][1]=prev_j;

	printk("update_transition_state...\n");
	for(i=0;i<S5PC11X_MAXFREQLEVEL+1;i++) {
		printk("%d, %d\n",transition_state[S5PC11X_FREQ_TAB][i][0],transition_state[S5PC11X_FREQ_TAB][i][1]);
	}
}

// for active high with event from TS and key
static int dvfs_perf_lock = 0;
int dvfs_change_quick = 0;

// jump to the given performance level
static void set_dvfs_perf_level(unsigned int perf_level) 
{
	unsigned long irqflags;

	spin_lock_irqsave(&g_dvfslock,irqflags);
	if(s5pc11x_cpufreq_index > perf_level) {
		s5pc11x_cpufreq_index = perf_level; // jump to specified level 
		dvfs_change_quick = 1;
	}
	spin_unlock_irqrestore(&g_dvfslock,irqflags);
	return;
}

//Jump to the given frequency level 
void set_dvfs_target_level(enum freq_level_states freq_level) 
{
	unsigned int ret = 0, perf_level=0;
	
	ret = get_dvfs_perf_level(freq_level, &perf_level);
	if(ret)
		return;

	set_dvfs_perf_level(perf_level);
	return;
}

#if ENABLE_DVFS_LOCK_HIGH
//Lock and jump to the given frequency level
void s5pc110_lock_dvfs_high_level(unsigned int nToken, enum freq_level_states freq_level)
{
	unsigned int nLevel, ret, perf_level=0;
	//printk("dvfs lock with token %d\n",nToken);
	ret = get_dvfs_perf_level(freq_level, &perf_level);
	if(ret)
		return;
	nLevel = perf_level;
#ifdef CONFIG_NC_DEBUG
	printk(KERN_INFO "PM:DVFS: lock with token: %d, level: %d\n", nToken, nLevel);
#endif
	if (nToken == DVFS_LOCK_TOKEN_6 ) nLevel--; // token for launcher , this can use 1GHz
	// check lock corruption
	if (g_dvfs_high_lock_token & (1 << nToken)) printk ("PM:DVFS: [DVFSLOCK] lock token %d is already used!\n", nToken);
	//mutex_lock(&dvfs_high_lock);
	g_dvfs_high_lock_token |= (1 << nToken);
	g_dvfslockval[nToken] = nLevel;
	if (nLevel < g_dvfs_high_lock_limit)
		g_dvfs_high_lock_limit = nLevel;
	//mutex_unlock(&dvfs_high_lock);
	set_dvfs_perf_level(nLevel);
}
EXPORT_SYMBOL(s5pc110_lock_dvfs_high_level);

void s5pc110_unlock_dvfs_high_level(unsigned int nToken) 
{
	unsigned int i;
#ifdef CONFIG_NC_DEBUG
	printk(KERN_INFO "PM:DVFS: unlock with token %d\n", nToken);
#endif
	//printk("dvfs unlock with token %d\n",nToken);
	//mutex_lock(&dvfs_high_lock);
	g_dvfs_high_lock_token &= ~(1 << nToken);
	g_dvfslockval[nToken] = MAXFREQ_LEVEL_SUPPORTED-1;
	g_dvfs_high_lock_limit = MAXFREQ_LEVEL_SUPPORTED-1;

	if (g_dvfs_high_lock_token) {
		for (i=0;i<NUMBER_OF_LOCKTOKEN;i++) {
			if (g_dvfslockval[i] < g_dvfs_high_lock_limit)  g_dvfs_high_lock_limit = g_dvfslockval[i];
		}
	}

	//mutex_unlock(&dvfs_high_lock);
}
EXPORT_SYMBOL(s5pc110_unlock_dvfs_high_level);
#endif //ENABLE_DVFS_LOCK_HIGH

unsigned int s5pc11x_target_freq_find_index(unsigned int index_find, int flag)
{
	unsigned int index = index_find;
	struct cpufreq_frequency_table *freq_tab = s5pc110_freq_table[S5PC11X_FREQ_TAB];
	if(flag == 1) {
		while(true) {
			if(active_states[index] == 1 || (index == 0))
				break;
			index--;
		}
	}
	else {
		while(true) {
			/*
				fixed a possible out-of-bounds condition here where active_states doesn't have
				an index for CPUFREQ_TABLE_END. The || logic will short-circuit that check
				and stop segfaults.
			*/
			if((freq_tab[index].frequency == CPUFREQ_TABLE_END) || active_states[index] == 1)
				break;
			index++;
		}
		if (freq_tab[index].frequency == CPUFREQ_TABLE_END) {
			/*
				we can get here if we are already at our lowest possible freqency
				and were asked to find the next step lower, but there aren't any
				lower frequencies enabled. In this case, we should stay put
			*/
			index = s5pc11x_cpufreq_index;
		}
	}
	return index;
}

unsigned int s5pc11x_target_frq(unsigned int pred_freq,
                               int flag, unsigned int policy_min)
{
	int index;
	//unsigned long irqflags;
	unsigned int freq;

	struct cpufreq_frequency_table *freq_tab = s5pc110_freq_table[S5PC11X_FREQ_TAB];

	spin_lock(&g_dvfslock);
	if(freq_tab[0].frequency < pred_freq) {
		index = 0;
		goto s5pc11x_target_frq_end;
	}

	if(exp_update_states) {
		update_transition_states();
		exp_update_states = 0;
	}

	if((flag != 1)&&(flag != -1)) {
		printk("s5pc1xx_target_frq: flag error!!!!!!!!!!!!!\n");
	}

	index = s5pc11x_cpufreq_index;

	if(freq_tab[index].frequency == pred_freq) {
		if(flag == 1)
			index = transition_state[S5PC11X_FREQ_TAB][index][1];
		else
			index = transition_state[S5PC11X_FREQ_TAB][index][0];
	}
	/*else {
		index = 0;
	}*/

	if (g_dvfs_high_lock_token) {
		if(g_dvfs_fix_lock_limit == true) {
#ifdef CONFIG_NC_DEBUG
			printk(KERN_INFO "PM:DVFS: fix: true, index: %d, dvfs_high_lock: %d\n", index, g_dvfs_high_lock_limit);
			printk(KERN_INFO "PM:DVFS: index freq: %dMHz, lock freq: %dMHz\n",
				freq_tab[index].frequency/1000, freq_tab[g_dvfs_high_lock_limit].frequency/1000);
#endif
			index = g_dvfs_high_lock_limit;// use the same level
		}
		else {
			if (index > g_dvfs_high_lock_limit) {
#ifdef CONFIG_NC_DEBUG
				printk(KERN_INFO "PM:DVFS: index: %d > dvfs_high_lock: %d\n", index, g_dvfs_high_lock_limit);
				printk(KERN_INFO "PM:DVFS: index freq: %dMHz, lock freq: %dMHz\n",
					freq_tab[index].frequency/1000, freq_tab[g_dvfs_high_lock_limit].frequency/1000);
#endif
				index = g_dvfs_high_lock_limit;
			}
		}
	}
	//printk("s5pc11x_target_frq index = %d\n",index);

s5pc11x_target_frq_end:
	//spin_lock_irqsave(&g_cpufreq_lock, irqflags);
	index = s5pc11x_target_freq_find_index(index,flag);
	index = CLIP_LEVEL(index, s5pc11x_cpufreq_level);
	s5pc11x_cpufreq_index = index;
	//spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);

	freq = freq_tab[index].frequency;
	spin_unlock(&g_dvfslock);
	if (freq > policy_min) {
#ifdef CONFIG_NC_DEBUG
		printk(KERN_INFO "PM:FREQ: ret freq: %dMHz\n", freq/1000);
#endif
		return freq;
	}
	else {
#ifdef CONFIG_NC_DEBUG
		printk(KERN_INFO "PM:FREQ: ret min: %dMHz, freq: %dMHz\n", policy_min/1000, freq/1000);
#endif
		return policy_min;
	}
}

int s5pc11x_target_freq_index(unsigned int freq)
{
	int index = 0;
	//unsigned long irqflags;
	
	struct cpufreq_frequency_table *freq_tab = s5pc110_freq_table[S5PC11X_FREQ_TAB];

	if(freq >= freq_tab[index].frequency) {
		goto s5pc11x_target_freq_index_end;
	}

	/*Index might have been calculated before calling this function.
	check and early return if it is already calculated*/
	if(freq_tab[s5pc11x_cpufreq_index].frequency == freq) {		
		return s5pc11x_cpufreq_index;
	}

	while((freq < freq_tab[index].frequency) &&
			(freq_tab[index].frequency != CPUFREQ_TABLE_END)) {
		index++;
	}

	/*
		check freq_tab first to avoid walking off the edge of active_states, which
		is one entry smaller than freq_tab
	*/
	while((freq_tab[index].frequency != CPUFREQ_TABLE_END) && active_states[index] == 0) {
		index++;
	}

	if(index > 0) {
		if(freq != freq_tab[index].frequency) {
#ifdef CONFIG_NC_DEBUG
			printk(KERN_INFO "PM: freq: %dMHz != freq_tab[index]: %dMHz \n", freq/1000, freq_tab[index].frequency/1000);
#endif
			index--;
		}
	}

s5pc11x_target_freq_index_end:
	spin_lock(&g_dvfslock);
	index = CLIP_LEVEL(index, s5pc11x_cpufreq_level);
	s5pc11x_cpufreq_index = index;
	spin_unlock(&g_dvfslock);
	
	return index;
} 

int s5pc110_pm_target(unsigned int target_freq)
{
	int ret = 0;
	unsigned long arm_clk;
	unsigned int index;

	index = s5pc11x_target_freq_index(target_freq);
	if(index == INDX_ERROR) {
		printk("s5pc110_target: INDX_ERROR \n");
		return -EINVAL;
	}

	arm_clk = s5pc110_freq_table[S5PC11X_FREQ_TAB][index].frequency;

	target_freq = arm_clk;

#ifdef USE_DVS
#ifdef GPIO_BASED_DVS
	set_voltage_dvs(index);
#else
	set_voltage(index);
#endif
#endif
/* frequency scaling */
	ret = clk_set_rate(mpu_clk, target_freq * KHZ_T);
	if(ret != 0) {
		printk("frequency scaling error\n");
		return -EINVAL;
	}
#if 1
	/*change the frequency threshold level*/
	store_up_down_threshold(s5pc110_thres_table[S5PC11X_FREQ_TAB][index][0], 
				s5pc110_thres_table[S5PC11X_FREQ_TAB][index][1]);
#endif
	return ret;
}

int is_userspace_gov(void)
{
	int ret = 0;
	//unsigned long irqflags;
	//spin_lock_irqsave(&g_cpufreq_lock, irqflags);
	if(!strnicmp(cpufreq_governor_name, userspace_governor, CPUFREQ_NAME_LEN)) {
		ret = 1;
	}
	// spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);
	return ret;
}

int is_conservative_gov(void)
{
	int ret = 0;
	//unsigned long irqflags;
	//spin_lock_irqsave(&g_cpufreq_lock, irqflags);
	if(!strnicmp(cpufreq_governor_name, conservative_governor, CPUFREQ_NAME_LEN)) {
		ret = 1;
	}
	// spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);
	return ret;
}


/* TODO: Add support for SDRAM timing changes */

int s5pc110_verify_speed(struct cpufreq_policy *policy)
{
	if (policy->cpu)
		return -EINVAL;

	return cpufreq_frequency_table_verify(policy, s5pc110_freq_table[S5PC11X_FREQ_TAB]);
}

unsigned int s5pc110_getspeed(unsigned int cpu)
{
	unsigned long rate;

	if (cpu)
		return 0;

	rate = clk_get_rate(mpu_clk) / KHZ_T;

	return rate;
}

unsigned int s5pc11x_nearest_avail_index(struct cpufreq_policy *policy, unsigned int target_freq, unsigned int relation)
{
	unsigned int ret_index = 0;
	unsigned int hi_index = 0;
	unsigned int lo_index = 0;
	unsigned int max_index = 0;
	unsigned int min_index = 0;
	int hi_diff;
	int lo_diff;
	struct cpufreq_frequency_table *freq_tab = s5pc110_freq_table[S5PC11X_FREQ_TAB];

	// Find the 1st freq lower than or equal to target_freq
	while((target_freq < freq_tab[hi_index].frequency) && (freq_tab[hi_index].frequency != CPUFREQ_TABLE_END)) {
		hi_index++;
	}
	if (hi_index != 0) {
		/*
			If we don't have an exact match, or the current index is not an active state, or we are at CPUFREQ_TABLE_END.
			Then we need to increase the freq and check for the next available active state
		*/
		if((target_freq != freq_tab[hi_index].frequency) | (active_states[hi_index] == 0) | (freq_tab[hi_index].frequency == CPUFREQ_TABLE_END)) {
			hi_index--;
			while((hi_index > 0) && (active_states[hi_index] == 0)) {
				hi_index--;
			}
		}
	}
	// index == 0
	else {
		// if hi_index == 0, find highest available freq
		while((freq_tab[hi_index].frequency != CPUFREQ_TABLE_END) && active_states[hi_index] == 0) {
			hi_index++;
		}
		// if we hit the end of the table, force the lowest freq
		if (freq_tab[hi_index].frequency == CPUFREQ_TABLE_END) {
			hi_index--;
		}
	}
	// if hi_index is an exact match, use it
	if (target_freq == freq_tab[hi_index].frequency) {
		ret_index = hi_index;
#ifdef CONFIG_NC_DEBUG
		printk(KERN_INFO "FREQ:NC: target match: %dMHz \n", freq_tab[ret_index].frequency/1000);
#endif
	}
	// not an exact match
	else {
		lo_index = hi_index+1;
		// if lo_index puts us at CPUFREQ_TABLE_END, use hi_index
		if (freq_tab[lo_index].frequency == CPUFREQ_TABLE_END) {
			ret_index = hi_index;
		} else {
			// find next available lower freq
			while((freq_tab[lo_index].frequency != CPUFREQ_TABLE_END) && active_states[lo_index] == 0) {
				lo_index++;
			}
			// if we hit the end of the table, force the lowest freq
			if (freq_tab[lo_index].frequency == CPUFREQ_TABLE_END) {
				lo_index--;
			}
#ifdef CONFIG_NC_DEBUG
			printk(KERN_INFO "FREQ:NC: target: %dMHz| lo: %dMHz| hi: %dMHz \n",
				target_freq/1000, freq_tab[lo_index].frequency/1000, freq_tab[hi_index].frequency/1000);
#endif
			// calculate difference
			hi_diff = freq_tab[hi_index].frequency - target_freq;
			lo_diff = target_freq - freq_tab[lo_index].frequency;
			// if hi_diff < lo_diff, hi_index is nearest
			if (hi_diff < lo_diff) {
				ret_index = hi_index;
#ifdef CONFIG_NC_DEBUG
				printk(KERN_INFO "FREQ:NC: ret hi_index: %d, freq: %dMHz \n", ret_index, freq_tab[ret_index].frequency/1000);
#endif
			}
			// if hi_diff == lo_diff, use the scaling relation
			else if (hi_diff == lo_diff) {
				// flag == 1,  scale up
				// relation == CPUFREQ_RELATION_L, Lowest freq at or above, scale up
				if(relation == CPUFREQ_RELATION_L) {
					ret_index = hi_index;
#ifdef CONFIG_NC_DEBUG
					printk(KERN_INFO "FREQ:NC: RELATION_L, freq: %dMHz \n", freq_tab[ret_index].frequency/1000);
#endif
				}
				// flag != 1, scale down
				// relation == CPUFREQ_RELATION_H, Highest freq at or below, scale down
				else {
					ret_index = lo_index;
#ifdef CONFIG_NC_DEBUG
					printk(KERN_INFO "FREQ:NC: RELATION_H, freq: %dMHz \n", freq_tab[ret_index].frequency/1000);
#endif
				}
			}
			// if hi_diff != lo_diff, and !(hi_diff < lo_diff), lo_index is nearest
			else {
				ret_index = lo_index;
#ifdef CONFIG_NC_DEBUG
				printk(KERN_INFO "FREQ:NC: ret lo_index: %d, freq: %dMHz \n", ret_index, freq_tab[ret_index].frequency/1000);
#endif
			}
		}
	}
	// if we have a lock
	if (g_dvfs_high_lock_token) {
		// if fixed lock == true, use fixed lock freq
		if(g_dvfs_fix_lock_limit == true) {
			ret_index = g_dvfs_high_lock_limit;
#ifdef CONFIG_NC_DEBUG
			printk(KERN_INFO "PM:DVFS:NC: fixed lock: %dMHz \n", freq_tab[ret_index].frequency/1000);
#endif
		} else {
			// if freq < lock freq (freq_index > lock_index), use lock freq
			if (ret_index > g_dvfs_high_lock_limit) {
				ret_index = g_dvfs_high_lock_limit;
#ifdef CONFIG_NC_DEBUG
				printk(KERN_INFO "PM:DVFS:NC: lock: %dMHz \n", freq_tab[ret_index].frequency/1000);
#endif
			}
		}
	}
	//we do not have a lock
	else {
		// if freq > policy max, find and use policy max
		if (freq_tab[ret_index].frequency > policy->max) {
			// Find the 1st freq equal to policy max
			while(freq_tab[max_index].frequency != CPUFREQ_TABLE_END) {
				if (policy->max == freq_tab[max_index].frequency) {
#ifdef CONFIG_NC_DEBUG
					printk(KERN_INFO "FREQ:NC: found max_index: %d, freq: %dMHz \n", max_index, freq_tab[max_index].frequency/1000);
#endif
					break;
				} else {
					max_index++;
				}
			}
			if(freq_tab[max_index].frequency == CPUFREQ_TABLE_END) {
#ifdef CONFIG_NC_DEBUG
				printk(KERN_INFO "FREQ:NC: max_index == CPUFREQ_TABLE_END \n");
#endif
				max_index--;
			}
#ifdef CONFIG_NC_DEBUG
			printk(KERN_INFO "FREQ:NC: ret max_index: %d, freq: %dMHz \n", max_index, freq_tab[max_index].frequency/1000);
#endif
			ret_index = max_index;
		}
		// if freq < policy min, find and use policy min
		if (freq_tab[ret_index].frequency < policy->min) {
			// Find the 1st freq equal to policy min
			while(freq_tab[min_index].frequency != CPUFREQ_TABLE_END) {
				if (policy->min == freq_tab[min_index].frequency) {
#ifdef CONFIG_NC_DEBUG
					printk(KERN_INFO "FREQ:NC: found min_index: %d, freq: %dMHz \n", min_index, freq_tab[min_index].frequency/1000);
#endif
					break;
				} else {
					min_index++;
				}
			}
			// if min_index = TABLE END
			if(freq_tab[min_index].frequency == CPUFREQ_TABLE_END) {
#ifdef CONFIG_NC_DEBUG
				printk(KERN_INFO "FREQ:NC: min_index == CPUFREQ_TABLE_END \n");
#endif
				min_index--;
			}
#ifdef CONFIG_NC_DEBUG
			printk(KERN_INFO "FREQ:NC: ret min_index: %d, freq: %dMHz \n", min_index, freq_tab[min_index].frequency/1000);
#endif
			ret_index = min_index;
		}
	}
#if 1
	spin_lock(&g_dvfslock);
	s5pc11x_cpufreq_index = ret_index;
	spin_unlock(&g_dvfslock);
#endif
	// return nearest index
#ifdef CONFIG_NC_DEBUG
	printk(KERN_INFO "FREQ:NC: ret ret_index: %d, freq: %dMHz \n", ret_index, freq_tab[ret_index].frequency/1000);
#endif
	return ret_index;
}

extern void print_clocks(void);
extern void dvs_set_for_1dot2Ghz (int onoff);
extern bool gbTransitionLogEnable;
static int s5pc110_target(struct cpufreq_policy *policy,
		       unsigned int target_freq,
		       unsigned int relation)
{
	struct cpufreq_freqs freqs;
	int ret = 0;
	unsigned long arm_clk;
	unsigned int index;

	//unsigned long irqflags;

	DBG("s5pc110_target called for freq=%d\n",target_freq);

	freqs.old = s5pc110_getspeed(0);
	DBG("old _freq = %d\n",freqs.old);

	if(policy != NULL) {
		if(policy -> governor) {
			//spin_lock_irqsave(&g_cpufreq_lock, irqflags);
			if (strnicmp(cpufreq_governor_name, policy->governor->name, CPUFREQ_NAME_LEN)) {
				strcpy(cpufreq_governor_name, policy->governor->name);
			}
			//spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);
		}
	}

#ifdef CONFIG_CPU_S5PV210
	index = s5pc11x_nearest_avail_index(policy, target_freq, relation);
#else
	index = s5pc11x_target_freq_index(target_freq);
#endif
	if(index == INDX_ERROR) {
		printk("s5pc110_target: INDX_ERROR \n");
		return -EINVAL;
	}
	DBG("Got index = %d\n",index);

	if(prevIndex == index)
	{	
		DBG("Target index = Current index\n");
		return ret;
	}

	arm_clk = s5pc110_freq_table[S5PC11X_FREQ_TAB][index].frequency;

	freqs.new = arm_clk;
	freqs.cpu = 0;

	target_freq = arm_clk;
	cpufreq_notify_transition(&freqs, CPUFREQ_PRECHANGE);
	//spin_lock_irqsave(&g_cpufreq_lock, irqflags);

	if(prevIndex < index) { // clock down
		dvfs_change_direction = 0;
		/* frequency scaling */
		ret = s5pc11x_clk_dsys_psys_change(index);

		ret = s5pc11x_armclk_set_rate(mpu_clk, target_freq * KHZ_T);
		//ret = clk_set_rate(mpu_clk, target_freq * KHZ_T);
		if(ret != 0) {
			printk("frequency scaling error\n");
			ret = -EINVAL;
			goto s5pc110_target_end;
		}
		
		// ARM MCS value set
		if (S5PC11X_FREQ_TAB  == 0) { // for 1G table
#if 0 // not using above 1.4GHz
			if ((prevIndex < 11) && (index >= 11)) {
#else
			if ((prevIndex < 9) && (index >= 9)) {
#endif // end not using above 1.4GHz
				ret = __raw_readl(S5P_ARM_MCS);
				DBG("MDSvalue = %08x\n", ret);
				ret = (ret & ~(0x3)) | 0x3;
				__raw_writel(ret, S5P_ARM_MCS);
			}
		} else if (S5PC11X_FREQ_TAB  == 1) { // for 1.2Ghz table
			if ((prevIndex < 4) && (index >= 4)) {
				ret = __raw_readl(S5P_ARM_MCS);
				ret = (ret & ~(0x3)) | 0x3;
				__raw_writel(ret, S5P_ARM_MCS);
			}		
		} else {
			DBG("\n\nERROR\n\n INVALID DVFS TABLE !!\n");
			return ret;
		}

/* TODO */
#if 0
		if (S5PC11X_FREQ_TAB) {	
			if (index <= 2)
				dvs_set_for_1dot2Ghz(1);
			else if (index >= 3)
				dvs_set_for_1dot2Ghz(0);
		}
#endif

#ifdef USE_DVS
#ifdef GPIO_BASED_DVS
		set_voltage_dvs(index);
#else
		/* voltage scaling */
		set_voltage(index);
#endif
#endif
		dvfs_change_direction = -1;
	} else { // clock up
		dvfs_change_direction = 1;
/* TODO */
#if 0
		if (S5PC11X_FREQ_TAB) {	
			if (index <= 2)
				dvs_set_for_1dot2Ghz(1);
			else if (index >= 3)
				dvs_set_for_1dot2Ghz(0);
		}
#endif
#ifdef USE_DVS
#ifdef GPIO_BASED_DVS
		set_voltage_dvs(index);
#else
		/* voltage scaling */
		set_voltage(index);
#endif
#endif

		// ARM MCS value set
		if (S5PC11X_FREQ_TAB  == 0) { // for 1G table
#if 0 // not using above 1.4GHz
			if ((prevIndex >= 11) && (index < 11)) {
#else
			if ((prevIndex >= 9) && (index < 9)) {
#endif // end not using above 1.4GHz
				ret = __raw_readl(S5P_ARM_MCS);
				DBG("MDSvalue = %08x\n", ret);				
				ret = (ret & ~(0x3)) | 0x1;
				__raw_writel(ret, S5P_ARM_MCS);
			}
		} else if (S5PC11X_FREQ_TAB  == 1) { // for 1.2G table
			if ((prevIndex >= 4) && (index < 4)) {
				ret = __raw_readl(S5P_ARM_MCS);
				ret = (ret & ~(0x3)) | 0x1;
				__raw_writel(ret, S5P_ARM_MCS);
			}		
		} else {
			DBG("\n\nERROR\n\n INVALID DVFS TABLE !!\n");
			return ret;
		}

		/* frequency scaling */
		ret = s5pc11x_armclk_set_rate(mpu_clk, target_freq * KHZ_T);
		//ret = clk_set_rate(mpu_clk, target_freq * KHZ_T);
		if(ret != 0) {
			printk("frequency scaling error\n");
			ret = -EINVAL;
			goto s5pc110_target_end;
		}
		ret = s5pc11x_clk_dsys_psys_change(index);
		dvfs_change_direction = -1;
	}

	//spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);
	cpufreq_notify_transition(&freqs, CPUFREQ_POSTCHANGE);
	prevIndex = index; // save to preIndex

	mpu_clk->rate = freqs.new * KHZ_T;

#if 1 // not using it as of now
	/*change the frequency threshold level*/
	store_up_down_threshold(s5pc110_thres_table[S5PC11X_FREQ_TAB][index][0], 
				s5pc110_thres_table[S5PC11X_FREQ_TAB][index][1]);
#endif
	DBG("Perf changed[L%d] freq=%d\n",index,arm_clk);
#ifdef CONFIG_CPU_FREQ_LOG
	if(gbTransitionLogEnable == true)
	{
		DBG("Perf changed[L%d]\n",index);
		printk("[DVFS Transition]...\n");
		print_clocks();
	}
#endif
	return ret;
s5pc110_target_end:
	//spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);
	return ret;
}

#ifdef CONFIG_CPU_FREQ_LOG
static void inform_dvfs_clock_status(struct work_struct *work) {
//	if (prevIndex == )
	printk("[Clock Info]...\n");	
	print_clocks();
	schedule_delayed_work(&dvfs_info_print_work, 1 * HZ);
}
#endif

#ifdef CONFIG_HAS_WAKELOCK
#if 0
void s5pc11x_cpufreq_powersave(struct early_suspend *h)
{
	//unsigned long irqflags;
	//spin_lock_irqsave(&g_cpufreq_lock, irqflags);
	s5pc11x_cpufreq_level = S5PC11X_MAXFREQLEVEL + 2;
	//spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);
	return;
}

void s5pc11x_cpufreq_performance(struct early_suspend *h)
{
	//unsigned long irqflags;
	if(!is_userspace_gov()) {
		//spin_lock_irqsave(&g_cpufreq_lock, irqflags);
		s5pc11x_cpufreq_level = S5PC11X_MAXFREQLEVEL;
		s5pc11x_cpufreq_index = CLIP_LEVEL(s5pc11x_cpufreq_index, S5PC11X_MAXFREQLEVEL);
		//spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);
		s5pc110_target(NULL, s5pc110_freq_table[S5PC11X_FREQ_TAB][s5pc11x_cpufreq_index].frequency, 1);
	}
	else {
		//spin_lock_irqsave(&g_cpufreq_lock, irqflags);
		s5pc11x_cpufreq_level = S5PC11X_MAXFREQLEVEL;
		//spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);
#ifdef USE_DVS
#ifdef GPIO_BASED_DVS
		set_voltage_dvs(s5pc11x_cpufreq_index);
#else
		set_voltage(s5pc11x_cpufreq_index);
#endif
#endif
	}
	return;
}

static struct early_suspend s5pc11x_freq_suspend = {
	.suspend = s5pc11x_cpufreq_powersave,
	.resume = s5pc11x_cpufreq_performance,
	.level = EARLY_SUSPEND_LEVEL_DISABLE_FB + 1,
};
#endif
#endif //CONFIG_HAS_WAKELOCK


unsigned int get_min_cpufreq(void)
{
	unsigned int frequency;
	frequency = s5pc110_freq_table[S5PC11X_FREQ_TAB][S5PC11X_MAXFREQLEVEL].frequency;
	return frequency;
}

static int __init s5pc110_cpu_init(struct cpufreq_policy *policy)
{
	u32 i;
	int ret_table_cpuinfo;
	//unsigned long irqflags;

	mpu_clk = clk_get(NULL, MPU_CLK);
	if (IS_ERR(mpu_clk))
		return PTR_ERR(mpu_clk);

	/*set the table for maximum performance*/

	if (policy->cpu != 0)
		return -EINVAL;
	policy->cur = policy->min = policy->max = s5pc110_getspeed(0);

	if(policy->max > 1000000)
		policy->max = 1000000;
	if(policy->min < 200000)
		policy->min = 200000;
	//spin_lock_irqsave(&g_cpufreq_lock, irqflags);

#ifdef CONFIG_MACH_S5PC110_ARIES_OC
	S5PC11X_FREQ_TAB = 0;
#if 0 // not using above 1.4GHz
	S5PC11X_MAXFREQLEVEL = 12;
	MAXFREQ_LEVEL_SUPPORTED = 13;
	g_dvfs_high_lock_limit = 12;
#else
	S5PC11X_MAXFREQLEVEL = 10;
	MAXFREQ_LEVEL_SUPPORTED = 11;
	g_dvfs_high_lock_limit = 10;
#endif // end not using above 1.4GHz
#else // no OC
	S5PC11X_FREQ_TAB = 0;
	S5PC11X_MAXFREQLEVEL = 6;
	MAXFREQ_LEVEL_SUPPORTED = 7;
	g_dvfs_high_lock_limit = 6;
#endif // end CONFIG_MACH_S5PC110_ARIES_OC
	
	printk("S5PC11X_FREQ_TAB=%d, S5PC11X_MAXFREQLEVEL=%d\n",S5PC11X_FREQ_TAB,S5PC11X_MAXFREQLEVEL);

	s5pc11x_cpufreq_level = S5PC11X_MAXFREQLEVEL;
	//spin_unlock_irqrestore(&g_cpufreq_lock, irqflags);
#ifdef CONFIG_MACH_S5PC110_ARIES_OC
#if 0 // not using above 1.4GHz
	prevIndex = 8;// we are currently at 800MHZ level
#else
	prevIndex = 6;// we are currently at 800MHZ level
#endif // end not using above 1.4GHz
#else // no OC
	prevIndex = 2;// we are currently at 800MHZ level
#endif // end CONFIG_MACH_S5PC110_ARIES_OC

#ifdef CONFIG_CPU_FREQ_LOG
	//schedule_delayed_work(&dvfs_info_print_work, 60 * HZ);
#endif
	cpufreq_frequency_table_get_attr(s5pc110_freq_table[S5PC11X_FREQ_TAB], policy->cpu);

	policy->cpuinfo.transition_latency = 80000; //40000;	//1us

#ifdef CONFIG_HAS_WAKELOCK
//	register_early_suspend(&s5pc11x_freq_suspend);	
#endif

	#if ENABLE_DVFS_LOCK_HIGH
	/*initialise the dvfs lock level table*/
	for(i = 0; i < NUMBER_OF_LOCKTOKEN; i++)
		g_dvfslockval[i] = MAXFREQ_LEVEL_SUPPORTED-1;
	#endif

	update_transition_states();

	ret_table_cpuinfo = cpufreq_frequency_table_cpuinfo(policy, s5pc110_freq_table[S5PC11X_FREQ_TAB]);
	return ret_table_cpuinfo;
}

static struct freq_attr *s5pc110_cpufreq_attr[] = {
	&cpufreq_freq_attr_scaling_available_freqs,
	NULL,
};

static struct cpufreq_driver s5pc110_driver = {
	.flags		= CPUFREQ_STICKY,
	.verify		= s5pc110_verify_speed,
	.target		= s5pc110_target,
	.get		= s5pc110_getspeed,
	.init		= s5pc110_cpu_init,
	.name		= "s5pc110",
	.attr		= s5pc110_cpufreq_attr,
};

static int __init s5pc110_cpufreq_init(void)
{
	return cpufreq_register_driver(&s5pc110_driver);
}

//arch_initcall(s5pc110_cpufreq_init);
module_init(s5pc110_cpufreq_init);
