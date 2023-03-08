SRC = alu_tb.v alu.v
OUT = Valu_tb

all:
	verilator $(SRC) -Wall -trace -cc --top-module alu_tb -exe top.cpp
	make -j -C obj_dir -f Valu_tb.mk Valu_tb
	cp obj_dir/$(OUT) .

run: clean all
	clear
	./$(OUT)

clean:
	rm -rf $(OUT) *.vcd obj_dir
