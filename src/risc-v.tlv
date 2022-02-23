\m4_TLV_version 1d: tl-x.org
\SV
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/1d1023ccf8e7b0a8cf8e8fc4f0a823ebb61008e3/risc-v_defs.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])
   m4_define(['M4_MAX_CYC'], 50)
   m4_test_prog()

\SV
   m4_makerchip_module   
\TLV
   
   $reset = *reset;
   
   //Program Counter
   $pc[31:0] = >>1$next_pc;
   $next_pc[31:0] = $reset ? 0 : 
                    ($taken_br | $is_j_instr) ? $br_tgt_pc : 
                    $is_jalr ? $jalr_tgt_pc : ($pc + 32'h4);
   
   // Creating the memory
   `READONLY_MEM($pc, $$instr[31:0])
   
   // Checking whihc type of inst is is
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   $is_j_instr = $instr[6:2] == 5'b11011;
   $is_b_instr = $instr[6:2] == 5'b11000;
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   $is_r_instr = ($instr[6:2] == 5'b01011) || ($instr[6:2] ==? 5'b011x0) || ($instr[6:2] == 5'b10100);
   $is_i_instr = ($instr[6:2] ==? 5'b0000x) || ($instr[6:2] ==? 5'b00001) || ($instr[6:2] ==? 5'b001x0) || ($instr[6:2] ==? 5'b11001);
   
   // Extracting rs2 
   $rs2[4:0] = $instr[24:20];
   // Checking if it is a rs2 containing instruction
   $rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
   
   //Extracting rs1
   $rs1[4:0] = $instr[19:15];
   $rs1_valid = $is_r_instr || $is_s_instr || $is_b_instr || $is_i_instr;
   
   
   //Extracting rd
   $rd[4:0] = $instr[11:7];
   $rd_valid = ($is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr) & ($rd != 5'b0) ;
   
   // is the immediate value valid 
   $imm_valid = $is_u_instr || $is_j_instr || $is_b_instr || $is_s_instr || $is_i_instr;
   //Constructing the immediate value
   $imm[31:0] = $is_i_instr ? {{21{$instr[31]}},$instr[30:20]} :
          $is_s_instr ? {{21{$instr[31]}},$instr[30:25],$instr[11:8],$instr[7]} :
          $is_b_instr ? {{20{$instr[31]}},$instr[7],$instr[30:25],$instr[11:8],1'b0} :
          $is_u_instr ? {$instr[31],$instr[30:20],$instr[19:12],12'b0} :
          $is_j_instr ? {{12{$instr[31]}},$instr[19:12],$instr[20],$instr[30:25],$instr[24:21],1'b0} : 32'b0;
   
   
   //Extracting funct3
   
   // Concatenating the deciding bits opcode,funct3,funct7
   $dec_bits[10:0] = $is_i_instr ? {$imm[10],$instr[14:12],$instr[6:0]} : {$instr[30],$instr[14:12],$instr[6:0]};
   
   //--------------- B-Type ----------- //
   
   //Checking if it is BEQ
   $is_beq = $dec_bits ==? 11'bx_000_1100011;
   
   //Checking if it is BNE
   $is_bne = $dec_bits ==? 11'bx_001_1100011;
   
   //Checking if it is BLT
   $is_blt = $dec_bits ==? 11'bx_100_1100011;
   
   //Checking if it is BGE
   $is_bge = $dec_bits ==? 11'bx_101_1100011;
   
   //Checking if it is BLTU
   $is_bltu = $dec_bits ==? 11'bx_110_1100011;
   
   //Checking if it is BGEU
   $is_bgeu = $dec_bits ==? 11'bx_111_1100011;
   
 
   //-------------- R-Type--------------//
 
 
   //Checking if it is ADD
   $is_add = $dec_bits == 11'b0_000_0110011;
   
   
   //Checking if it is SUB
   $is_sub = $dec_bits == 11'b1_000_0110011;
   
   //Checking if it is SLL
   $is_sll = $dec_bits == 11'b0_001_0110011;
   
   //Checking if it is SLT
   $is_slt = $dec_bits == 11'b0_010_0110011;
   
   //Checking if it is SLTU
   $is_sltu = $dec_bits == 11'b0_011_0110011;
   
   //Checking if it is XOR
   $is_xor = $dec_bits == 11'b0_100_0110011;
   
   //Checking if it is SRL
   $is_srl = $dec_bits == 11'b0_101_0110011;
   
   //Checking if it is SRA
   $is_sra = $dec_bits == 11'b1_101_0110011;
   
   //Checking if it is OR
   $is_or = $dec_bits == 11'b0_110_0110011;
   
   //Checking if it is AND
   $is_and = $dec_bits == 11'b0_111_0110011;
   
   //------------- U-Type ------------//
   
   //Checking if it is LUI
   
   $is_lui = $instr[6:0] == 7'b0110111;
   
   //Checking if it is AUIPC
   $is_auipc = $instr[6:0] == 7'b0010111;
   
   
   //------------ J-Type------------//
   //Checking if it is JAL
   
   $is_jal = $instr[6:0] == 7'b1101111;
   
   
   //----------- LOAD -------------//
   //Checking if it is LOAD 
   
   $is_load = $instr[6:0] == 7'b0000011;
   
   //----------- I-Type -----------//
   //Checking if it is ADDI
   $is_addi = $dec_bits ==? 11'bx_000_0010011;
   
   
   //Checking if it is JALR
   
   $is_jalr = $dec_bits ==? 11'bx_000_1100111;
   
   //Checking if it is SLTI
   $is_slti = $dec_bits ==? 11'bx_010_0010011;
   
   //Checking if it is SLTIU
   $is_sltiu = $dec_bits ==? 11'bx_011_0010011;
   
   //Checking if it is XORI
   $is_xori = $dec_bits ==? 11'bx_100_0010011;
   
   //Checking if it is ORI
   $is_ori = $dec_bits ==? 11'bx_110_0010011;
   
   //Checking if it is ANDI
   $is_andi = $dec_bits ==? 11'bx_111_0010011;
   
   //Checking if it is SLLI
   $is_slli = $dec_bits ==? 11'b0_001_0010011;
   
   //Checking if it is SRLI
   $is_srli = $dec_bits ==? 11'b0_101_0010011;
   
   //Checking if it is SRAI
   $is_srai = $dec_bits ==? 11'b1_101_0010011;
   
   
   
   // ----- ALU ------ //
   //SLTU and SLTIU
   $stlu_result[31:0] = {31'b0,$src1_value < $src2_value};
   $stliu_result[31:0] = {31'b0,$src1_value < $imm};
   //SRA and SRAI
   $sext_src1[63:0] = {{32{$src1_value[31]}},$src1_value};
   $sra_result[63:0] = $sext_src1 >> $src2_value[4:0];
   $srai_result[63:0] = $sext_src1 >> $imm[4:0];
   
   
   $output[31:0] = $is_addi ? ($src1_value + $imm) :
                  $is_add ? ($src1_value + $src2_value) : 
                  $is_andi ? ($src1_value & $imm) :
                  $is_ori ? ($src1_value | $imm) :
                  $is_xori ? ($src1_value ^ $imm) :
                  $is_slli ? ($src1_value << $imm[5:0]) :
                  $is_srli ? ($src1_value >> $imm[5:0]) :
                  $is_and ? ($src1_value & $src2_value) :
                  $is_or ? ($src1_value | $src2_value) :
                  $is_xor ? ($src1_value ^ $src2_value) :
                  $is_sub ? ($src1_value - $src2_value) :
                  $is_sll ? ($src1_value << $src2_value[4:0]) :
                  $is_srl ? ($src1_value >> $src2_value[4:0]) :
                  $is_sltu ? $stlu_result[31:0] :
                  $is_sltiu ? $stliu_result[31:0] :
                  $is_lui ? {$imm[31:12],12'b0} :
                  $is_auipc ? $pc + $imm :
                  $is_jal ? $pc + 32'd4 :
                  $is_jalr ? $pc + 32'd4 :
                  $is_slt ? (($src1_value[31] == $src2_value[31]) ?
                                  $stlu_result  : 
                                  {31'b0,$src1_value[31]}) :
                  $is_slti ? (($src1_value[31] == $imm[31]) ?
                                  $stliu_result  : 
                                  {31'b0,$src1_value[31]}) :
                  $is_sra ? $sra_result[31:0] :
                  $is_srai ? $srai_result[31:0] : 
                  ($is_load  | $is_s_instr) ? $src1_value + $imm : 32'b0;
   
   // Checking if this is a branch condition
   $taken_br = $is_beq ? ($src1_value == $src2_value) :
               $is_bne ? ($src1_value != $src2_value) :
               $is_blt ? (($src1_value < $src2_value) | ($src1_value[31] != $src2_value[31])) :
               $is_bge ? (($src1_value >= $src2_value) | ($src1_value[31] != $src2_value[31])) :
               $is_bltu ? ($src1_value < $src2_value) :
               $is_bgeu ? ($src1_value >= $src2_value) : 1'b0;
               
   $br_tgt_pc[31:0] = $pc + $imm;
   $jalr_tgt_pc[31:0] = $src1_value + $imm;
   
   //Result 
   
   $result[31:0] = $is_load ? $ld_data : $output; 
   
   *failed = *cyc_cnt > M4_MAX_CYC;
   m4+tb()
   m4+rf(32, 32, $reset, $rd_valid, $rd[4:0], $result[31:0], $rs1_valid, $rs1, $src1_value, $rs2_valid, $rs2, $src2_value)
   m4+dmem(32, 32, $reset, $output[4:0], $is_s_instr, $src2_value[31:0], $is_load, $ld_data)
\SV
   endmodule