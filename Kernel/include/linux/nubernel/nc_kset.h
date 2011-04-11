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
