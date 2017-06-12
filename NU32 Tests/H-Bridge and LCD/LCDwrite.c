#include "NU32.h" // constants, funcs for startup and UART
#include "LCD.h"

#define MSG_LEN 20

int main() {
  char msg[MSG_LEN];
  int Kp = 0, Ki = 0, Kd = 0;
  NU32_Startup(); // cache on, interrupts on, LED/button init, UART init
  
  LCD_Setup();
  
  while(1)
  {
    LCD_Clear();
    LCD_Move(0,0);
    sprintf(msg, "Kp: %d Ki: %d Kd: %d", Kp, Ki, Kd);
    LCD_WriteString(msg);        
  }
  
  return 0;
}
