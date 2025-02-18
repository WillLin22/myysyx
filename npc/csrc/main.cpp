#include <nvboard.h>
#include <Vtop.h>

Vtop dut;

void nvboard_bind_all_pins(Vtop* top);
int main()
{
    nvboard_bind_all_pins(&dut);
    nvboard_init();
    
    while (1) {
      dut.a = rand() & 1;
      dut.b = rand() & 1;
      dut.eval();
      nvboard_update();
    }
    
    nvboard_quit();
}