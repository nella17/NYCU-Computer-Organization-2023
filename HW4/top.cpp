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

int main() {
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
        cycle *= 10;
        cout << endl << "Pattern " << i+1 << " check at cycle " << cycle << endl;

        // initialize imem
        for (int k = 0; k < 16; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("instr[%d]=%x\n", k, temp);
            dut->hw3_tb->core_top_inst->imem_inst->RAM[k] = temp;
        }


        // initialize dmem
        for (int k = 0; k < 16; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("init_dmem[%d]=%x\n", k, temp);
            dut->hw3_tb->core_top_inst->dmem_inst->RAM[k] = temp;
        }

        // read file - final register file
        for (int k = 0; k < 32; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("golden_reg[%d]=%d\n", k, temp);
            dut->hw3_tb->golden_reg[k] = temp;
        }

        // read file - final dmem
        for (int k = 0; k < 16; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("golden_dmem[%d]=%x\n", k, temp);
            dut->hw3_tb->golden_dmem[k] = temp;
        }

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
        }

        // check answer
        if (dut->correctness == 0) {
            printf("Pattern %d : Fail\n", i+1);
        }
        else {
            printf("Pattern %d : Pass\n", i+1);
            total_score += 10;
        }
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
