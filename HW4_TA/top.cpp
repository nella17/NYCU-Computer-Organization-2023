#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vhw4_tb.h"
#include "Vhw4_tb__Syms.h"

#include <iostream>
#include <fstream>
#include <bitset>

using namespace std;

#define TRACE
vluint64_t sim_time = 0;

Vhw4_tb *dut;

int main() {
#ifdef TRACE
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
#endif
    
    dut = new Vhw4_tb("dut");        // our DUT(Design Under Test)

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

    for (int pat_num = 0; pat_num < 10; pat_num++) {
        
        // read file - cycle
        int cycle;
        fs >> cycle;
        cycle *= 5;
        cout << endl << "Pattern " << pat_num + 1 << " check at cycle " << cycle << endl;


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

        // initialize imem
        for (int k = 0; k < 16; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("instr[%d]=%x\n", k, temp);
            dut->hw4_tb->core_top_inst->imem_inst->RAM[k] = temp;
        }


        // initialize dmem
        for (int k = 0; k < 16; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("init_dmem[%d]=%x\n", k, temp);
            dut->hw4_tb->core_top_inst->dmem_inst->RAM[k] = temp;
        }

        // read file - final register file
        for (int k = 0; k < 32; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("golden_reg[%d]=%d\n", k, temp);
            dut->hw4_tb->golden_reg[k] = temp;
        }

        // read file - final dmem
        for (int k = 0; k < 16; k++) {
            unsigned int temp;
            fs >> temp;
            // printf("golden_dmem[%d]=%x\n", k, temp);
            dut->hw4_tb->golden_dmem[k] = temp;
        }

        dut->rst = 0;


        for (int j = 0; j < cycle * 2; j++) {
            dut->clk ^= 1;
            dut->eval();
#ifdef TRACE
            m_trace->dump(sim_time);   // dump simulation result into vcd file.
            sim_time++;
#endif
            
            // cout << bitset<32>(dut->hw4_tb->correctness_reg) << endl;
            // cout << bitset<16>(dut->hw4_tb->correctness_dmem) << endl;

            // cout << bitset<32>(dut->hw4_tb->core_top_inst->reg_file_inst->R[ 8]) << endl;
            // cout << bitset<32>(dut->hw4_tb->core_top_inst->reg_file_inst->R[ 9]) << endl;
            // cout << bitset<32>(dut->hw4_tb->core_top_inst->reg_file_inst->R[10]) << endl;
            // cout << bitset<32>(dut->hw4_tb->core_top_inst->reg_file_inst->R[11]) << endl;

            // if (dut->correctness == 0) {
            //     printf("Pattern %d : Fail\n", pat_num+1);
            // }
            // else {
            //     printf("Pattern %d : Passed\n", pat_num+1);
            //     total_score += 10;
            // }
        }

        // for (int i = 0; i < 32; i++) {
        //     if (dut->hw4_tb->golden_reg[i] != dut->hw4_tb->core_top_inst->reg_file_inst->R[i]) {
        //         cout << "Golden reg[" << i << "] is : " 
        //              << bitset<32>(dut->hw4_tb->golden_reg[i]) << ", "
        //              << "Your   reg[" << i << "] is : "
        //              << bitset<32>(dut->hw4_tb->core_top_inst->reg_file_inst->R[i]) << endl;
        //     }
        // }

        // for (int i = 0; i < 16; i++) {
        //     if (dut->hw4_tb->golden_dmem[i] != dut->hw4_tb->core_top_inst->dmem_inst->RAM[i]) {
        //         cout << "Golden dmem[" << i << "] is : " 
        //              << bitset<32>(dut->hw4_tb->golden_dmem[i]) << ", "
        //              << "Your   dmem[" << i << "] is : "
        //              << bitset<32>(dut->hw4_tb->core_top_inst->dmem_inst->RAM[i]) << endl;
        //     }
        // }

        // check answer
        if (dut->correctness == 0) {
            printf("Pattern %d : Fail\n", pat_num+1);
        }
        else {
            printf("Pattern %d : Passed\n", pat_num+1);
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