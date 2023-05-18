SRC = hw4_tb.v alu.v decode.v dmem.v imem.v reg_file.v
OUT = Vhw4_tb

all:
	verilator $(SRC) -Wno-WIDTH -trace -cc --top-module hw4_tb -exe top.cpp
	make -C obj_dir -f Vhw4_tb.mk Vhw4_tb
	cp obj_dir/$(OUT) .

run: clean all
	clear
	./$(OUT)

clean:
	rm -rf $(OUT) *.vcd obj_dir
