#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vhw5_tb.h"
#include "Vhw5_tb__Syms.h"

#include <iostream>
#include <fstream>

using namespace std;

#define TRACE
vluint64_t sim_time = 0;

Vhw5_tb *dut;

int main() {

    int total_score = 0;

    char vcd_file[2][100];
    strcpy(vcd_file[0], "waveform_1.vcd");
    strcpy(vcd_file[1], "waveform_2.vcd");

    char ans_file[2][100];
    strcpy(ans_file[0], "ans_1.txt");
    strcpy(ans_file[1], "ans_2.txt");

    for (int i = 0; i < 2; i++) {
        
        #ifdef TRACE
            Verilated::traceEverOn(true);
            VerilatedVcdC *m_trace = new VerilatedVcdC;
        #endif
            
            dut = new Vhw5_tb("dut");        // our DUT(Design Under Test)

        #ifdef TRACE
            dut->trace(m_trace, 99);
            m_trace->open(vcd_file[i]); // open a waveform file to be write
        #endif

            dut->clk = 1;
            dut->rst = 0;

            fstream fs(ans_file[i], std::fstream::in);

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

        // read file - cycle
        int cycle;
        fs >> cycle;
        unsigned int end_pc;
        fs >> end_pc;
        // cout << endl << "Pattern " << i+1 << " check at cycle " << cycle << endl;

        // initialize imem
        for (int k = 0; k < 64; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("instr[%d]=%x\n", k, temp);
            dut->hw5_tb->core_top_inst->imem_inst->RAM[k] = temp;
        }


        // initialize dmem
        for (int k = 0; k < 64; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("init_dmem[%d]=%x\n", k, temp);
            dut->hw5_tb->core_top_inst->dmem_inst->RAM[k] = temp;
        }

        // read file - final register file
        for (int k = 0; k < 32; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("golden_reg[%d]=%d\n", k, temp);
            dut->hw5_tb->golden_reg[k] = temp;
        }

        // read file - final dmem
        for (int k = 0; k < 64; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("golden_dmem[%d]=%x\n", k, temp);
            dut->hw5_tb->golden_dmem[k] = temp;
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

        int count_cycle = 0;

        for (int j = 0; j < cycle * 2; j++) {
            dut->clk ^= 1;
            dut->eval();
#ifdef TRACE
            m_trace->dump(sim_time);   // dump simulation result into vcd file.
            sim_time++;
#endif
            if(j % 2 == 0) count_cycle+=1;
            if(end_pc == dut->out_pc) break;
        }

        // check answer
        if (dut->correctness == 0) {
            printf("Pattern %d : Fail\n", i+1);
        }
        else {
            printf("Pattern %d : Pass in %d cycles\n", i+1, count_cycle);
            total_score += 10;
        }

    #ifdef TRACE
        m_trace->close();              // flush and close the file
        delete m_trace;
    #endif

        delete dut;
    }

    exit(EXIT_SUCCESS);
}