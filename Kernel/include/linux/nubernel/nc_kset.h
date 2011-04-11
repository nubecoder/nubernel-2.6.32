/*
 * kernel/nubernel/nc_kset.h
 *
 * nubecoder 2011
 *
 * Licensed under GPLv2
 *
 */

// Header guard
#ifndef NC_KSET_H
#define NC_KSET_H

//
#define CHARGE_RATE_AC_DEFAULT		5
#define CHARGE_RATE_AC_MAX		7

#define CHARGE_RATE_USB_DEFAULT		1
#define CHARGE_RATE_USB_MAX		4
//

//
#define BATT_RECHARGE_COUNT_MIN		1
#define BATT_RECHARGE_COUNT_DEFAULT		20

#define CURRENT_OF_FULL_CHG_MIN		15
#define CURRENT_OF_FULL_CHG_DEFAULT		91

#define CHG_CURRENT_COUNT_MIN		1
#define CHG_CURRENT_COUNT_DEFAULT		20

#define FULL_CHARGE_COND_VOLTAGE_MAX		4200
#define FULL_CHARGE_COND_VOLTAGE_DEFAULT		4000

#define RECHARGE_COND_VOLTAGE_MAX		4180
#define RECHARGE_COND_VOLTAGE_DEFAULT		4110

#define RECHARGE_COND_VOLTAGE_BACKUP_MAX		4100
#define RECHARGE_COND_VOLTAGE_BACKUP_DEFAULT		4000
//

//
#define FG_ADJ_VALUE_MAX		999
#define FG_ADJ_VALUE_DEFAULT		950
//

struct nubernel_obj {
	struct kobject kobj;
};
struct nubernel_attribute {
	struct attribute attr;
	ssize_t (*show)(struct nubernel_obj *nubernel, struct nubernel_attribute *attr, char *buf);
	ssize_t (*store)(struct nubernel_obj *nubernel, struct nubernel_attribute *attr, const char *buf, size_t count);
};

extern struct nubernel_obj *create_nubernel_obj(const char *name);
extern void destroy_nubernel_obj(struct nubernel_obj *nubernel);

extern int nubernel_sysfs_create_file(struct nubernel_obj *nubernel, const struct nubernel_attribute *attr);
extern void nubernel_sysfs_remove_file(struct nubernel_obj *nubernel, const struct nubernel_attribute *attr);

extern int nc_kset_init(void);
extern void nc_kset_exit(void);

#endif
