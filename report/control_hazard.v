wire control_hazard;

// 控制冒险：分支/跳转指令
assign control_hazard = (id_ex_valid && (id_ex_branch_flag || id_ex_jump_flag)) ||
                        (ex_mem_valid && (ex_mem_branch_flag || ex_mem_jump_flag));