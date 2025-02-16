#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

int main()
{
  while (???) {
    int a = rand() & 1;
    int b = rand() & 1;
    top->a = a;
    top->b = b;
    top->eval();
    printf("a = %d, b = %d, f = %d\n", a, b, top->f);
    assert(top->f == (a ^ b));
  }
}
