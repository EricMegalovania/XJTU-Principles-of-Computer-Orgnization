// 指令格式定义和常量定义

// 指令长度
`define INSTR_LEN 32
// 数据长度
`define DATA_LEN 32
// 地址长度
`define ADDR_LEN 32

// 寄存器堆大小
`define REG_NUM 32
// 寄存器地址长度
`define REG_ADDR_LEN 5

// 指令格式位定义
// R型指令: [31-26:opcode][25-21:rs][24-20:rt][19-15:rd][14-10:shamt][9-0:funct]
`define OPCODE 31:26
`define RS 25:21
`define RT 24:20
`define RD 19:15
`define SHAMT 14:10
`define FUNCT 9:0

// I型指令: [31-26:opcode][25-21:rs][24-20:rt][19-0:imm]
`define IMM 19:0

// J型指令: [31-26:opcode][25-0:address]
`define J_ADDR 25:0

// 立即数符号扩展
`define SIGN_EXTEND(imm) {{16{imm[15]}}, imm[15:0]}
// 立即数零扩展
`define ZERO_EXTEND(imm) {{16{1'b0}}, imm[15:0]}

// opcode 定义
`define OP_R_TYPE 6'b000000 // R型指令
`define OP_ADDI 6'b001000    // addi
`define OP_ORI 6'b001101     // ori
`define OP_BEQ 6'b000100     // beq
`define OP_J 6'b000010       // j
`define OP_LW 6'b100011      // lw
`define OP_SW 6'b101011      // sw

// R型指令 funct 定义
`define FUNCT_ADD 6'b100000  // add
`define FUNCT_SUB 6'b100010  // sub
`define FUNCT_AND 6'b100100  // and
`define FUNCT_OR 6'b100101   // or
`define FUNCT_XOR 6'b100110  // xor
`define FUNCT_SLL 6'b000000  // sll
`define FUNCT_SRL 6'b000010  // srl
`define FUNCT_SRA 6'b000011  // sra
`define FUNCT_SLT 6'b101010  // slt
`define FUNCT_SLTU 6'b101011 // sltu

// ALU 操作类型定义
`define ALU_ADD 4'b0000      // 加
`define ALU_SUB 4'b0001      // 减
`define ALU_AND 4'b0010      // 与
`define ALU_OR 4'b0011       // 或
`define ALU_XOR 4'b0100      // 异或
`define ALU_SLL 4'b0101      // 逻辑左移
`define ALU_SRL 4'b0110      // 逻辑右移
`define ALU_SRA 4'b0111      // 算术右移
`define ALU_SLT 4'b1000      // 带符号小于置1
`define ALU_SLTU 4'b1001     // 无符号小于置1
`define ALU_LW_SW 4'b1010    // lw/sw的地址计算
