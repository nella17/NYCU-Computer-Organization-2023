#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vhw3_tb.h"
#include "Vhw3_tb__Syms.h"

#include <iostream>
#include <fstream>

using namespace std;

#define TRACE
vluint64_t sim_time = 0;

Vhw3_tb *dut;

int main(int argc, char* const argv[]) {
    int count = argc <= 1 ? 0 : atoi(argv[1]);
    int testcase = -1, cnt = count;
    auto readcase = [&]() {
        if (cnt) {
            cnt--;
            printf("test > ");
            scanf("%d", &testcase);
        }
    };
    readcase();

#ifdef TRACE
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
#endif
    
    dut = new Vhw3_tb("dut");        // our DUT(Design Under Test)

#ifdef TRACE
    dut->trace(m_trace, 99);
    m_trace->open("waveform.vcd"); // open a waveform file to be write
#endif

    dut->clk = 1;
    dut->rst = 0;

    int total_score = 0;

    fstream fs("ans.txt", std::fstream::in);

    dut->rst = 1;
    for (int j = 0; j < 10; j++) {
        dut->clk ^= 1; 
        dut->rst = 1;
        dut->eval();
#ifdef TRACE
        m_trace->dump(sim_time);   // dump simulation result into vcd file.
        sim_time++;
#endif
    }
    dut->rst = 0;

    for (int i = 0; i < 10; i++) {
        
        // read file - cycle
        int cycle;
        fs >> cycle;
        cycle *= 4;
        cout << endl << "Pattern " << i+1 << " check at cycle " << cycle << endl;

        // initialize imem
        for (int k = 0; k < 16; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("instr[%d]=%x\n", k, temp);
            dut->hw3_tb->write_imem(k, temp);
        }


        // initialize dmem
        for (int k = 0; k < 16; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("init_dmem[%d]=%x\n", k, temp);
            dut->hw3_tb->write_dmem(k, temp);
        }

        // read file - final register file
        fs.unsetf(std::ios::dec);
        fs.unsetf(std::ios::hex);
        fs.unsetf(std::ios::oct);

        for (int k = 0; k < 32; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("golden_reg[%d]=%d\n", k, temp);
            dut->hw3_tb->write_golden_reg(k, temp);
        }

        // read file - final dmem
        for (int k = 0; k < 16; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("golden_dmem[%d]=%x\n", k, temp);
            dut->hw3_tb->write_golden_dmem(k, temp);
        }

        if (count and i+1 != testcase) continue;

        dut->rst = 1;
        for (int j = 0; j < 10; j++) {
            dut->clk ^= 1; 
            dut->rst = 1;
            dut->eval();
#ifdef TRACE
            m_trace->dump(sim_time);   // dump simulation result into vcd file.
            sim_time++;
#endif
        }
        dut->rst = 0;


        for (int j = 0; j < cycle * 2; j++) {
            dut->clk ^= 1;
            dut->eval();
#ifdef TRACE
            m_trace->dump(sim_time);   // dump simulation result into vcd file.
            sim_time++;
#endif
            bool v;
            dut->hw3_tb->check_pc(v);
            if (v) {
                printf("early finish at cycle %d\n", j / 2);
                break;
            }
        }

        // check answer
        if (dut->correctness == 0) {
            printf("Pattern %d : Fail\n", i+1);
            for (int k = 0; k < 32; k++) {
                bool v;
                dut->hw3_tb->read_correctness_reg(k, v);
                if (!v) {
                    uint32_t val, golden;
                    dut->hw3_tb->read_reg(k, val);
                    dut->hw3_tb->read_golden_reg(k, golden);
                    printf("  reg  %02d fail: %d (%d)\n", k, val, golden);
                }
            }
            for (int k = 0; k < 16; k++) {
                bool v;
                dut->hw3_tb->read_correctness_dmem(k, v);
                if (!v) {
                    uint32_t val, golden;
                    dut->hw3_tb->read_dmem(k, val);
                    dut->hw3_tb->read_golden_dmem(k, golden);
                    printf("  dmem %02d fail: %d (%d)\n", k * 4, val, golden);
                }
            }
        }
        else {
            printf("Pattern %d : Pass\n", i+1);
            total_score += 10;
        }

        readcase();
    }

    printf ("===========================================\n");
    printf ("Your score : %d\n", total_score);
    printf ("===========================================\n");


#ifdef TRACE
    m_trace->close();              // flush and close the file
    delete m_trace;
#endif

    delete dut;
    exit(EXIT_SUCCESS);
}
