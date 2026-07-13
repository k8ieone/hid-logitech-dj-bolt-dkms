obj-m += hid-logitech-dj.o
obj-m += hid-logitech-hidpp.o
ccflags-y += -I$(src)

KVERSION ?= $(shell uname -r)

all:
	$(MAKE) -C /lib/modules/$(KVERSION)/build M=$(CURDIR) modules

clean:
	$(MAKE) -C /lib/modules/$(KVERSION)/build M=$(CURDIR) clean
