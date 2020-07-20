#include "ad7705_raspi.h"
#include <wiringPiSPI.h>

struct Settings *sets;

#ifdef __cplusplus
extern "C" {
#endif

void initialize(struct Settings *settings)
{
    sets = settings;
    
    for (uint8_T i = 0; i < 2; ++i)
    {
        if (sets->ce[i])
        {
            int fd = wiringPiSPISetupMode(i, sets->speed, 3);
            if (fd == -1)
            {
                printf("\nFailed to init SPI0/CE%d communication.\n", i);
                exit(1);
            }
            
            uint8_T resetReg[4] = {0xff, 0xff, 0xff, 0xff};
            uint8_T clockReg[2] = 
                    {commsResistor(0, 2, 0, 0, sets->ain[i]),
                     clockResistor(sets->clockDis[i], sets->clockDiv[i], sets->filter)};
            uint8_T setupReg[2] = 
                    {commsResistor(0, 1, 0, 0, sets->ain[i]),
                     setupResistor(sets->calib[i], sets->gain[i], sets->polar[i], sets->buffer[i], 0)};
                     
            wiringPiSPIDataRW(i, resetReg, 4);
            wiringPiSPIDataRW(i, clockReg, 2);
            wiringPiSPIDataRW(i, setupReg, 2);
        }
    }
    
    delay(2000);
}

void step(struct Data *data)
{
    for (uint8_T i = 0; i < 2; ++i)
    {
        if (sets->ce[i])
        {
            uint8_T readReg[3] = {commsResistor(0, 3, 1, 0, sets->ain[i]), 0x00, 0x00};
            wiringPiSPIDataRW(i, readReg, 3);
            
            switch (i)
            {
                case 0:
                    data->ce0ain = (readReg[1]<<8)|(readReg[2]);
                    break;
                case 1:
                    data->ce1ain = (readReg[1]<<8)|(readReg[2]);
                    break;
                default:
                    break;
            }
        }
    }
}

void terminate()
{

}

uint8_T commsResistor(uint8_T DRDY, uint8_T RS, uint8_T RW, uint8_T STBY, uint8_T CH)
{
    uint8_T reg = 0x00;
    
    reg = reg << 0;
    reg |= DRDY;	// 0/DRDY
    reg = reg << 3;
    reg |= RS;      // RS2, RS1, RS0
    reg = reg << 1;
    reg |= RW;      // R/W
    reg = reg << 1;
    reg |= STBY;	// STBY
    reg = reg << 2;
    reg |= CH;      // CH1, CH0

    return reg;
}

uint8_T setupResistor(uint8_T MD, uint8_T G, uint8_T BU, uint8_T BUF, uint8_T FSYNC)
{
    uint8_T reg = 0x00;
    
    reg = reg << 1;
    reg |= MD;      // MD1, MD0
    reg = reg << 3;
    reg |= G;       // G2, G1, G0
    reg = reg << 1;
    reg |= BU;      // B/U
    reg = reg << 1;
    reg |= BUF;     // BUF
    reg = reg << 1;
    reg |= FSYNC;	// FSYNC
 
    return reg;
}

uint8_T clockResistor(uint8_T CLKDIS, uint8_T CLKDIV, uint8_T CLK_FS)
{
    uint8_T reg = 0x00;
    
    reg = reg << 2;
    reg |= 0x00;	// ZERO
    reg = reg << 1;
    reg |= CLKDIS;  // CLKDIS
    reg = reg << 1;
    reg |= CLKDIV;	// CLKDIV
    reg = reg << 3;
    reg |= CLK_FS;  // CLK & FS1, FS0
 
    return reg;
}

#ifdef __cplusplus
}
#endif