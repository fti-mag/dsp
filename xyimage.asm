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

#define DVERT 4
#define NVERT 0x10 // 1<<DVERT
#define MVERT 0xf // (1<<DVERT) - 1
#define PVERT 5

#define DPTS 4
#define NPTS 0x10 // 1<<DPTS
#define MPTS 0xf // (1<<DPTS) - 1
#define PPTS 1

.section/dm seg_input;
.var/circ vert_x[NVERT] = 
	0x1800,
	0x2800,
	0x3400,
	0x4000,
	0x3000,
	0x2C00,
	0x2800,
	0x2000,
	0x1800,
	0x2800,
	0x2C00,
	0x1400,
	0x1000,
	0x0000,
	0x0C00,
	0x1800;

.var/circ vert_y[NVERT] = 
	0x4000,
	0x4000,
	0x2000,
	0x0000,
	0x0000,
	0x1000,
	0x1C00,
	0x3000,
	0x1C00,
	0x1C00,
	0x1000,
	0x1000,
	0x0000,
	0x0000,
	0x2000,
	0x4000;

// B50 sqrt2

#define PERIOD 0x200

.section/data seg_data;
.var counter = PERIOD;
.var channel = 0;
.var vertex = 0;
.var points = 0;

.section/pm seg_code;
start:
// INIT CODEC
CALL CodecInit;

loop_:
JUMP loop_;

SPORT0_rx:
// COUNTER
AR = DM(counter);
NONE = PASS AR;
IF NE JUMP __cnt_end;
TOGGLE FL1;
AR = PERIOD;
DM(counter) = AR;
__cnt_end:
AX0 = DM(counter);
AR = AX0 - 1;
DM(counter) = AR;

SE = -PVERT;
SI = DM(counter);
SR = LSHIFT SI (LO);
AR = SR0;
DM(vertex) = AR;

SE = -PPTS;
SI = DM(counter);
SR = LSHIFT SI (LO);
AX0 = SR0;
AY0 = MPTS;
AR = AX0 AND AY0;
DM(points) = AR;

// SELECT CHANNEL
AX1 = DM(channel);
AR = TGLBIT 1 OF AX1;
DM(channel) = AR;
IF NE JUMP __DAC_1;

__DAC_0:
AX0 = vert_x; // current
CALL cur_vert;
AR = AX0;
L0 = 0;
M0 = 0;
I0 = AR;
AR = DM(I0, M0);
AX1 = AR;
AX0 = vert_x; // next
CALL next_vert;
AR = AX0;
L0 = 0;
M0 = 0;
I0 = AR;
AR = DM(I0, M0);
AY0 = AR;
AX0 = AX1; // interpolate
AR = AX0;
AX0 = AY0;
AY0 = AR;
CALL interpolate;
TX0 = AX0;
RTI;

__DAC_1:
AX0 = vert_y; // current
CALL cur_vert;
AR = AX0;
L0 = 0;
M0 = 0;
I0 = AR;
AR = DM(I0, M0);
AX1 = AR;
AX0 = vert_y; // next
CALL next_vert;
AR = AX0;
L0 = 0;
M0 = 0;
I0 = AR;
AR = DM(I0, M0);
AY0 = AR;
AX0 = AX1; // interpolate
AR = AX0;
AX0 = AY0;
AY0 = AR;
CALL interpolate;
TX0 = AX0;
RTI;

btn:
RTS;

cur_vert:
AY0 = DM(vertex);
AR = AX0 + AY0;
AX0 = AR;
RTS;

next_vert:
AY1 = AX0;
AX0 = DM(vertex);
AR = AX0 + 1;
AX0 = AR;
AY0 = MVERT;
AR = AX0 AND AY0;
AX0 = AR;
AY0 = AY1;
AR = AX0 + AY0;
AX0 = AR;
RTS;

interpolate:
AY1 = AY0;
SE = -DPTS; // from
SI = AX0;
SR = LSHIFT SI (LO);
MX0 = SR0;
MY0 = DM(points);
MR = MX0*MY0 (SS);
AX1 = MR0;
SE = -DPTS; // to
SI = AY1;
SR = LSHIFT SI (LO);
MX0 = SR0;
AY0 = DM(points);
AX0 = NPTS;
AR = AX0 - AY0;
MY0 = AR;
MR = MX0*MY0 (SS);
AY1 = MR0;
AR = AX1 + AY1;
AX0 = AR;
RTS;

