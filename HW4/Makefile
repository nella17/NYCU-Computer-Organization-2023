SRC = hw4_tb.v alu.v decode.v dmem.v imem.v reg_file.v hazard_ctrl.v
OUT = Vhw4_tb

all:
	verilator $(SRC) -Wno-WIDTH -trace -cc --top-module hw4_tb -exe top.cpp
	make -C obj_dir -f Vhw4_tb.mk Vhw4_tb
	cp obj_dir/$(OUT) .

run: clean all
	clear
	./$(OUT)

TESTSRC = hw3_tb.v alu.v decode.v dmem.v imem.v reg_file.v hazard_ctrl.v
TESTOUT = Vhw3_tb

test: clean
	verilator $(TESTSRC) -Wno-WIDTH -trace -cc --top-module hw3_tb -exe top-test.cpp
	make -C obj_dir -f Vhw3_tb.mk Vhw3_tb
	cp obj_dir/$(TESTOUT) .
	clear
	./$(TESTOUT)

clean:
	rm -rf $(OUT) *.vcd obj_dir
