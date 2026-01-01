wire data_hazard;

// 检测EX阶段的数据冒险
wire data_hazard_ex;
assign data_hazard_ex = (id_ex_valid && id_ex_reg_write_flag && id_ex_write_reg_addr != 0) &&
                        ((id_ex_write_reg_addr == if_id_inst[`RS]) || 
                        (id_ex_write_reg_addr == if_id_inst[`RT]));

// 检测MEM阶段的数据冒险
wire data_hazard_mem;
assign data_hazard_mem = (ex_mem_valid && ex_mem_reg_write_flag && ex_mem_write_reg_addr != 0) &&
                        ((ex_mem_write_reg_addr == if_id_inst[`RS]) || 
                            (ex_mem_write_reg_addr == if_id_inst[`RT]));

// 检测WB阶段的数据冒险（写回正在进行）
wire data_hazard_wb;
assign data_hazard_wb = (mem_wb_valid && mem_wb_reg_write_flag && mem_wb_write_reg_addr != 0) &&
                        ((mem_wb_write_reg_addr == if_id_inst[`RS]) || 
                        (mem_wb_write_reg_addr == if_id_inst[`RT]));

// 总的数据冒险
assign data_hazard = data_hazard_ex || data_hazard_mem || data_hazard_wb;