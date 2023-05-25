SRC = hw4_tb.v alu.v decode.v dmem.v imem.v reg_file.v hazard_ctrl.v
OUT = Vhw3_tb

all:
	verilator $(SRC) -Wno-WIDTH -trace -cc --top-module hw3_tb -exe top.cpp
	make -C obj_dir -f Vhw3_tb.mk Vhw3_tb
	cp obj_dir/$(OUT) .

run: clean all
	clear
	./$(OUT)

TESTSRC = hw3_tb.v alu.v decode.v dmem.v imem.v reg_file.v hazard_ctrl.v
TESTOUT = Vhw3_tb

test-build: clean
	verilator $(TESTSRC) -Wno-WIDTH -trace -cc --top-module hw3_tb -exe top-test.cpp
	make -C obj_dir -f Vhw3_tb.mk Vhw3_tb
	cp obj_dir/$(TESTOUT) .

test: test-build
	clear
	./$(TESTOUT)

test-single: test-build
	clear
	./$(TESTOUT) 1

clean:
	rm -rf $(OUT) *.vcd obj_dir
