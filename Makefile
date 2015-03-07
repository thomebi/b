ASM=nasm
ASMFLAGS=-f bin


all: b print64 test 

b: b.asm
	@ $(ASM) $(ASMFLAAGS) -o $@ $^
	@ chmod +x $@

print64: b
	@ echo -n "Bin bytes: "
	@ wc -c $^
	@ echo "Base64:"
	@ cat $^ | openssl enc -base64
	@ echo -n "Chars: "
	@ cat $^ | openssl enc -base64 | wc -c

test: b
	@ echo "Output"
	@ ./$^

clean: 
	@ rm -f b

