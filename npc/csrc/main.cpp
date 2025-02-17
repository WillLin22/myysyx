#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "Vtop.h"
#include "verilated.h"
#include "verilated_fst_c.h"

int main()
{
  VerilatedContext *context_p = new VerilatedContext;
  context_p->traceEverOn(true);
  Vtop* top = new Vtop{context_p};
  VerilatedFstC *tfp = new VerilatedFstC;
  top->trace(tfp, 0);
  tfp->open("./obj_dir/wave.fst");
  // while(!context_p->gotFinish())
  for(int i = 0; i < 100; i++)
  {
    // add your input here
    int a = top->a = rand() & 1;
    int b = top->b = rand() & 1;
    top->eval();
    tfp->dump(context_p->time());
    int f = top->f;
    context_p->timeInc(1);
    bool check = f == (a ^ b);// add your condition here
    if(!check)
    {
      printf("Test failed!\n");
      break;
    }
  }
  printf("Test passed!\n");
  delete top;
  tfp->close();
  delete context_p;
  return 0;
}