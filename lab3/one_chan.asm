.section/pm seg_rth;
JUMP start; NOP; NOP; NOP; /* RESET 0x00 */
RTI; NOP; NOP; NOP;        /* IRQ2  0x04 */
RTI; NOP; NOP; NOP;        /* IRQ1l 0x08 */
RTI; NOP; NOP; NOP;        /* IRQl0 0x0c */
JUMP SPORT0_tx; NOP; NOP; NOP; /* SPORT0_TX  */
JUMP SPORT0_rx; NOP; NOP; NOP; /* SPORT0_RX  */
CALL btn; RTI; NOP; NOP;   /* IRQE      0x18 */
RTI; NOP; NOP; NOP;        /* BDMA      0x1c */
RTI; NOP; NOP; NOP;        /* SPORT1 TX 0x20 */
RTI; NOP; NOP; NOP;        /* SPORT1 RX 0x24 */
NOP; NOP; NOP; RTI;        /* timer     0x28 */
RTI; NOP; NOP; NOP;        /* POWERDOWN 0x2c */

#define PERIOD 20000

.section/data seg_data;
.var counter = PERIOD;
.var channel = 0;

.section/pm seg_code;
start:
CALL CodecInit;
ENA INTS;
IMASK = 0x0071;

endless:
JUMP endless;

SPORT0_rx:
// LED COUNTER
AX0 = DM(counter);
AR = AX0 - 1;
DM(counter) = AR;
NONE = PASS AR;
IF NE JUMP __SPORT_rx__cnt_end;
TOGGLE FL1;
AR = PERIOD;
DM(counter) = AR;
__SPORT_rx__cnt_end:

// SELECT CHANNEL
AX1 = DM(channel);
AR = TGLBIT 1 OF AX1;
DM(channel) = AR;
IF NE JUMP __SPORT_rx__DAC_1;

// DAC_0
__SPORT_rx__DAC_0:
TX0 = RX0;
RTI;

// DAC_1
__SPORT_rx__DAC_1:
TX0 = 0x0000;
RTI;

btn:
TOGGLE FL1;
RTS;
