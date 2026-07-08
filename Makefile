obj-m += hid-logitech-dj.o
ccflags-y += -I$(src)

KVERSION ?= $(shell uname -r)

all:
	$(MAKE) -C /lib/modules/$(KVERSION)/build M=$(PWD) modules

clean:
	$(MAKE) -C /lib/modules/$(KVERSION)/build M=$(PWD) clean
