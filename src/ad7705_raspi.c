#include "ad7705_raspi.h"

struct ad7705_Settings *ad_sets;
static const uint8_T spiBPW = 8;
static const uint16_T spiDelay = 0;
int32_T spiFds[CE_MAX];
uint32_T spiSpeeds[CE_MAX];
pthread_t ad_thread;
uint16_T ad_pdata[CE_MAX] = {0};

#ifdef __cplusplus
extern "C" {
#endif

void ad7705_initialize(struct ad7705_Settings *settings)
{
    ad_sets = settings;
    
    for (uint8_T i = 0; i < CE_MAX; ++i)
    {
        if (ad_sets->ce[i])
        {
            ad7705_spiSetup(i, ad_sets->speed, 3);
            
            uint8_T resetReg[4] = {0xff, 0xff, 0xff, 0xff};
            uint8_T clockReg[2] = 
                    {ad7705_commsResistor(0, 2, 0, 0, ad_sets->ain[i]),
                     ad7705_clockResistor(ad_sets->clockDis[i], ad_sets->clockDiv[i], ad_sets->filter)};
            uint8_T setupReg[2] = 
                    {ad7705_commsResistor(0, 1, 0, 0, ad_sets->ain[i]),
                     ad7705_setupResistor(ad_sets->calib[i], ad_sets->gain[i], ad_sets->polar[i], ad_sets->buffer[i], 0)};
                     
            ad7705_spiDataRW(i, resetReg, 4);
            ad7705_spiDataRW(i, clockReg, 2);
            ad7705_spiDataRW(i, setupReg, 2);
        }
    }
    
    sleep(2);
    
    pthread_create(&ad_thread, NULL, (void *)ad7705_getValues, &ad_pdata);
}

void ad7705_step(uint16_T *data)
{
    pthread_join(ad_thread, NULL);
    
    for (uint8_T i = 0; i < CE_MAX; ++i)
    {
        data[i] = ad_pdata[i];
    }
    
    pthread_create(&ad_thread, NULL, (void *)ad7705_getValues, &ad_pdata);
}

void ad7705_terminate()
{
    pthread_join(ad_thread, NULL);
}

void *ad7705_getValues(void *pdata)
{
    uint16_T *data = (uint16_T *)pdata;
    
    for (uint8_T i = 0; i < CE_MAX; ++i)
    {
        if (ad_sets->ce[i])
        {
            uint8_T readReg[3] = {ad7705_commsResistor(0, 3, 1, 0, ad_sets->ain[i]), 0x00, 0x00};
            ad7705_spiDataRW(i, readReg, 3);
            
            data[i] = (readReg[1]<<8)|(readReg[2]);
        }
    }
}

uint8_T ad7705_commsResistor(uint8_T DRDY, uint8_T RS, uint8_T RW, uint8_T STBY, uint8_T CH)
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

uint8_T ad7705_setupResistor(uint8_T MD, uint8_T G, uint8_T BU, uint8_T BUF, uint8_T FSYNC)
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

uint8_T ad7705_clockResistor(uint8_T CLKDIS, uint8_T CLKDIV, uint8_T CLK_FS)
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

int32_T ad7705_spiDataRW(int32_T ch, uint8_T *data, int32_T len)
{
    struct spi_ioc_transfer spi;
    
    memset (&spi, 0, sizeof(spi));
    
    spi.tx_buf = (uint32_T)data;
    spi.rx_buf = (uint32_T)data;
    spi.len = len;
    spi.delay_usecs = spiDelay;
    spi.speed_hz = spiSpeeds[ch];
    spi.bits_per_word = spiBPW;
    
    return ioctl(spiFds[ch], SPI_IOC_MESSAGE(1), &spi);
}

int32_T ad7705_spiSetup(int32_T ch, int32_T speed, int32_T mode)
{
    int32_T fd;
    int8_T spiDev[32];
    
    snprintf(spiDev, 31, "/dev/spidev0.%d", ch);
    fd = open(spiDev, O_RDWR);

    if (fd < 0)
    {
        printf("Unable to open SPI device: %s\n", spiDev);
        exit(1);
    }

    spiSpeeds[ch] = speed;
    spiFds[ch] = fd;
    
    if (ioctl(fd, SPI_IOC_WR_MODE, &mode) < 0)
    {
        printf("SPI Mode Change failure: %s, mode %d\n", spiDev, mode);
        exit(1);
    }
    
    if (ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &spiBPW) < 0)
    {
        printf("SPI BPW Change failure: %s, bit per width %d\n", spiDev, spiBPW);
        exit(1);
    }
    
    if (ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) < 0)
    {
        printf("SPI Speed Change failure: %s, speed %d\n", spiDev, speed);
        exit(1);
    }
    
    return fd;
}

#ifdef __cplusplus
}
#endif