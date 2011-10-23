/*
 * kernel/nubernel/nc_kset.c
 *
 * nubecoder 2011
 *
 * Based on samples/kobject/kset-example.c
 *
 * Sample kset and ktype implementation
 *
 * Copyright (C) 2004-2007 Greg Kroah-Hartman <greg@kroah.com>
 * Copyright (C) 2007 Novell Inc.
 *
 * Released under the GPL version 2 only.
 *
 */
#include <linux/kobject.h>
#include <linux/string.h>
#include <linux/sysfs.h>
#include <linux/module.h>
#include <linux/init.h>

#include <linux/nubernel/nc_kset.h>

#define to_nubernel_obj(x) container_of(x, struct nubernel_obj, kobj)
#define to_nubernel_attr(x) container_of(x, struct nubernel_attribute, attr)

static ssize_t nubernel_attr_show(struct kobject *kobj, struct attribute *attr, char *buf)
{
	struct nubernel_attribute *attribute;
	struct nubernel_obj *nubernel;
	attribute = to_nubernel_attr(attr);
	nubernel = to_nubernel_obj(kobj);
	if (!attribute->show)
	{
		return -EIO;
	}
	return attribute->show(nubernel, attribute, buf);
}
static ssize_t nubernel_attr_store(struct kobject *kobj, struct attribute *attr, const char *buf, size_t len)
{
	struct nubernel_attribute *attribute;
	struct nubernel_obj *nubernel;
	attribute = to_nubernel_attr(attr);
	nubernel = to_nubernel_obj(kobj);
	if (!attribute->store)
	{
		return -EIO;
	}
	return attribute->store(nubernel, attribute, buf, len);
}
static struct sysfs_ops nubernel_sysfs_ops = {
	.show = nubernel_attr_show,
	.store = nubernel_attr_store,
};
static void nubernel_release(struct kobject *kobj)
{
	struct nubernel_obj *nubernel;
	nubernel = to_nubernel_obj(kobj);
	kfree(nubernel);
}
static struct attribute *nubernel_default_attrs[] = {
	NULL,
};
static struct kobj_type nubernel_ktype = {
	.sysfs_ops = &nubernel_sysfs_ops,
	.release = nubernel_release,
	.default_attrs = nubernel_default_attrs,
};
static struct kset *nc_kset;

struct nubernel_obj *create_nubernel_obj(const char *name)
{
	struct nubernel_obj *nubernel;
	int retval;
	nubernel = kzalloc(sizeof(*nubernel), GFP_KERNEL);
	if (!nubernel)
	{
		return NULL;
	}
	nubernel->kobj.kset = nc_kset;
	retval = kobject_init_and_add(&nubernel->kobj, &nubernel_ktype, NULL, "%s", name);
	if (retval)
	{
		kobject_put(&nubernel->kobj);
		return NULL;
	}
	kobject_uevent(&nubernel->kobj, KOBJ_ADD);
	return nubernel;
}
void destroy_nubernel_obj(struct nubernel_obj *nubernel)
{
	kobject_put(&nubernel->kobj);
}

int nubernel_sysfs_create_file(struct nubernel_obj *nubernel, const struct nubernel_attribute *attr)
{
	return sysfs_create_file(&nubernel->kobj, &attr->attr);
}
void nubernel_sysfs_remove_file(struct nubernel_obj *nubernel, const struct nubernel_attribute *attr)
{
	sysfs_remove_file(&nubernel->kobj, &attr->attr);
}

int nc_kset_init(void)
{
	if (!nc_kset)
	{
		nc_kset = kset_create_and_add("nubernel", NULL, NULL);
		if (!nc_kset)
		{
			return -ENOMEM;
		}
	}
	return 0;
}
void nc_kset_exit(void)
{
	kset_unregister(nc_kset);
}
