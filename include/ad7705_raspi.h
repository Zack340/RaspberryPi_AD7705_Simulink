/* 
 *  	Author : Eisuke Matsuzaki
 *  	Created on : 7/29/2020
 *  	Copyright (c) 2020 d’Arbeloff Lab, MIT Department of Mechanical Engineering
 *      Released under the MIT license
 * 
 *      AD7705 driver for Raspberry Pi
 */ 

#ifndef _AD7705_RASPI_H_
#define _AD7705_RASPI_H_
#include "rtwtypes.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <asm/ioctl.h>
#include <linux/spi/spidev.h>
#include <unistd.h>
#include <pthread.h>

#define CE_MAX 4

#ifdef __cplusplus
extern "C" {
#endif
    
struct ad7705_Settings
{
    uint8_T filter;
    uint16_T speed;
    boolean_T init;
    uint8_T ce[CE_MAX];
    uint8_T ain[CE_MAX];
    uint8_T calib[CE_MAX];
    uint8_T gain[CE_MAX];
    uint8_T polar[CE_MAX];
    uint8_T buffer[CE_MAX];
    uint8_T clockDis[CE_MAX];
    uint8_T clockDiv[CE_MAX];
};

void ad7705_initialize(struct ad7705_Settings *settings);
void ad7705_step(uint16_T *data);
void ad7705_terminate();
void *ad7705_getValues(void *pdata);
uint8_T ad7705_commsResistor(uint8_T DRDY, uint8_T RS, uint8_T RW, uint8_T STBY, uint8_T CH);
uint8_T ad7705_setupResistor(uint8_T MD, uint8_T G, uint8_T BU, uint8_T BUF, uint8_T FSYNC);
uint8_T ad7705_clockResistor(uint8_T CLKDIS, uint8_T CLKDIV, uint8_T FS);
int32_T ad7705_spiDataRW(int32_T ch, uint8_T *data, int32_T len);
int32_T ad7705_spiSetup(int32_T ch, int32_T speed, int32_T mode);
    
#ifdef __cplusplus
}
#endif
#endif //_AD7705_RASPI_H_