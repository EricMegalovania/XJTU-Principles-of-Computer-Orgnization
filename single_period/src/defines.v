`define INSTR_LEN 32  // 指令长度
`define DATA_LEN 32   // 数据长度
`define ADDR_LEN 32   // 地址长度

`define REG_NUM 32      // 寄存器堆大小
`define REG_ADDR_LEN 5  // 寄存器地址长度

// R-R 型指令: [31-26:opcode][25-21:rs][20-16:rt][15-11:rd][10-6:ZERO][5-0:funct]
`define OPCODE 31:26
`define RS 25:21
`define RT 20:16
`define RD 15:11
`define ZERO 10:6
`define FUNCT 5:0

// R-I 型指令: [31-26:opcode][25-21:rs][20-16:rt][15-0:imm]
`define IMM 15:0

// beq 指令: [31-26:opcode][25-21:rs][20-16:rt][15-0:offset]
// beq 和 R-I 型指令相同

// j 指令: [31-26:opcode][25-0:instr_index]
`define J_ADDR 25:0

// lw, sw 指令: [31-26:opcode][25-21:base][20-16:rt][15-0:offset]
// lw, sw 和 R-I 型指令相同

// opcode 定义
`define OP_R_TYPE 6'b000000  // R-R 型指令
`define OP_ADDI   6'b001000  // addi
`define OP_ORI    6'b001101  // ori
`define OP_BEQ    6'b000100  // beq
`define OP_J      6'b000010  // j
`define OP_LW     6'b100011  // lw
`define OP_SW     6'b101011  // sw

// R型指令 funct 定义
`define FUNCT_ADD 6'b100000  // add
`define FUNCT_SUB 6'b100010  // sub
`define FUNCT_AND 6'b100100  // and
`define FUNCT_OR  6'b100101  // or

// ALU 操作类型定义
`define ALU_ADD   4'b0000  // 加
`define ALU_SUB   4'b0001  // 减
`define ALU_AND   4'b0010  // 与
`define ALU_OR    4'b0011  // 或
`define ALU_LW_SW 4'b1010  // lw, sw 的地址计算