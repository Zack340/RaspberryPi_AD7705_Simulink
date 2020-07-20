/* 
 *  	Author : Eisuke Matsuzaki
 *  	Created on : 7/19/2020
 *  	Copyright (c) 2020 d’Arbeloff Lab, MIT Department of Mechanical Engineering
 *      Released under the GNU license
 * 
 *      AD7705 driver for Raspberry Pi
 */ 

#ifndef _AD7705_RASPI_H_
#define _AD7705_RASPI_H_
#include "rtwtypes.h"
#include <stdio.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif
    
struct Settings
{
    uint8_T filter;
    uint16_T speed;
    uint8_T ce[2];
    uint8_T ain[2];
    uint8_T calib[2];
    uint8_T gain[2];
    uint8_T polar[2];
    uint8_T buffer[2];
    uint8_T clockDis[2];
    uint8_T clockDiv[2];
};

struct Data
{
    uint16_T ce0ain;
    uint16_T ce1ain;
};

void initialize(struct Settings *settings);
void step(struct Data *data);
void terminate();
uint8_T commsResistor(uint8_T DRDY, uint8_T RS, uint8_T RW, uint8_T STBY, uint8_T CH);
uint8_T setupResistor(uint8_T MD, uint8_T G, uint8_T BU, uint8_T BUF, uint8_T FSYNC);
uint8_T clockResistor(uint8_T CLKDIS, uint8_T CLKDIV, uint8_T FS);
    
#ifdef __cplusplus
}
#endif
#endif //_AD7705_RASPI_H_