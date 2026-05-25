CC = riscv-none-elf-gcc
OBJCOPY = riscv-none-elf-objcopy

CFLAGS = -march=rv32imc -mabi=ilp32 -nostdlib -T link.ld -O2

all: firmware.hex

firmware.elf: crt0.S main.c
	$(CC) $(CFLAGS) crt0.S main.c -o firmware.elf

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin

# Update only this line in sw/Makefile:
firmware.hex: firmware.bin
	python3 -c "import sys; b=open('firmware.bin','rb').read(); \
	padded = b + b'\x00' * (4 - len(b) % 4) if len(b) % 4 != 0 else b; \
	[print(f'{padded[i+3]:02x}{padded[i+2]:02x}{padded[i+1]:02x}{padded[i]:02x}') for i in range(0, len(padded), 4)]" > firmware.hex

clean:
	rm -f *.elf *.bin *.hex
