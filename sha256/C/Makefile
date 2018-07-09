PLATFORM=arm-linux-gnueabihf
CC=gcc
FLAGS=-Wall

all: sha256.c
	$(PLATFORM)-$(CC) $(FLAGS) -o /tmp/sha256/initramfs/bin/sha256 $<

debug: sha256.c
	$(CC) $(FLAGS) -DDEBUG -o sha256 $<
