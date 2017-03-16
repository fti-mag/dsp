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

#define BUFLEN 0x40
#define BLPOW2 6

.section/dm seg_input;
.var/circ buffer2[BUFLEN];

#define PERIOD 20000
#define FILTMAX BLPOW2

.section/data seg_data;
.var counter = PERIOD;
.var channel = 0;
.var filtpow = FILTMAX;
.var filtlen = BUFLEN;

.section/pm seg_code;
start:
L2 = BUFLEN;
M2 = 1;
I2 = buffer2;

// INIT CODEC
CALL CodecInit;

endless:
JUMP endless;

SPORT0_rx:
// LED COUNTER
AX0 = DM(counter);
AR = AX0 - 1;
DM(counter) = AR;
NONE = PASS AR;
IF NE JUMP __cnt_end;
TOGGLE FL1;
AR = PERIOD;
DM(counter) = AR;
__cnt_end:

// SELECT CHANNEL
AX1 = DM(channel);
AR = TGLBIT 1 OF AX1;
DM(channel) = AR;
IF NE JUMP __DAC_1;

__DAC_0:
// write to buffer
AR = RX0;
DM(I2, M2) = AR;
// sum all values in buffer
L1 = DM(filtlen);
M1 = 1;
I1 = buffer2;
MR0 = 0;
MR1 = 0;
MY0 = 1;
CNTR = DM(filtlen);
DO __sum UNTIL CE;
       MX0 = DM(I1, M1);
__sum: MR = MR + MX0*MY0(SS);
// normalize (shift to BLPOW2)
AX0 = DM(filtpow);
AR = 0 - AX0;
SE = AR;
SR = ASHIFT MR1 (HI);
SI = MR0;
SR = SR OR LSHIFT SI (LO);
AX0 = SR0;
// write value to output
TX0 = AX0;
RTI;

__DAC_1:
TX0 = RX0;
RTI;

btn:
TOGGLE FL1;
// FILTPOW COUNTER
AX0 = DM(filtpow);
AR = AX0 - 1;
DM(filtpow) = AR;
NONE = PASS AR;
IF NE JUMP __filtpow_end;
AR = FILTMAX;
DM(filtpow) = AR;
__filtpow_end:

// FILTPOW TO FILTLEN
SE = DM(filtpow);
SI = 1;
SR = LSHIFT SI (LO);
AR = SR0;
DM(filtlen) = AR;

// SET BUFFER BOUNDS
L2 = DM(filtlen);
M2 = 1;
I2 = buffer2;
RTS;
