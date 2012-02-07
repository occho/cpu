library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
--use ieee.numeric_std.all;
--use work.alu_pack.all;


entity exec is
	port
	(
	CLK_EX	:	in	std_logic;	-- clk
	RESET	:	in	std_logic;	-- reset
	IR		:   in	std_logic_vector (31 downto 0);	-- instruction register
	PC_IN	:	in	std_logic_vector(31 downto 0);	-- current pc
	REG_S	:	in	std_logic_vector(31 downto 0);	-- value of rs
	REG_T	:	in	std_logic_vector(31 downto 0);	-- value of rt
	REG_D	:	in	std_logic_vector(31 downto 0);	-- value of rd
	FP_OUT	:	in	std_logic_vector(19 downto 0);	-- current frame pinter
	LR_OUT	:	in	std_logic_vector(31 downto 0);	-- current link register
	LR_IN	:	out	std_logic_vector(31 downto 0);	-- next link register
	PC_OUT	:	out	std_logic_vector(31 downto 0);	-- next pc
	N_REG	:	out std_logic_vector(4 downto 0);	-- register index
	REG_IN	:	out	std_logic_vector(31 downto 0);	-- value writing to reg
	N_RAM	:	out	std_logic_vector(19 downto 0);	-- ram address
	RAM_IN	:	out	std_logic_vector(31 downto 0);	-- value writing to ram
	REG_COND	:	out	std_logic_vector(3 downto 0);	-- reg flags
	RAM_WEN	:	out	std_logic	-- ram write enable
);


end exec;
architecture RTL of exec is

	signal op_code : std_logic_vector(5 downto 0);
	signal op_data : std_logic_vector(25 downto 0);

	signal cmp_flag : std_logic;
	signal shamt : std_logic_vector(4 downto 0);
	signal funct : std_logic_vector(5 downto 0);
	signal imm : std_logic_vector(15 downto 0);
	signal ex_imm : std_logic_vector(31 downto 0);
	signal target : std_logic_vector(25 downto 0);

	signal n_reg_s : std_logic_vector(4 downto 0);
	signal n_reg_t : std_logic_vector(4 downto 0);
	signal n_reg_d : std_logic_vector(4 downto 0);
	signal init : std_logic := '1';
	signal debug_count : std_logic_vector (31 downto 0) := x"00000000";

begin
	op_code <= IR(31 downto 26);
	op_data <= IR(25 downto 0);

	shamt <= op_data(10 downto 6);
	funct <= op_data(5 downto 0);
	imm <= op_data(15 downto 0);
	ex_imm <= (x"0000"&imm) when (imm(15)='0') else (x"ffff"&imm);
	target <= op_data(25 downto 0);

	n_reg_s <= op_data(25 downto 21);
	n_reg_t <= op_data(20 downto 16);
	n_reg_d <= op_data(15 downto 11);

	process(CLK_EX, RESET) 
		variable heap_size : std_logic_vector(31 downto 0) := (others=>'0');
		variable v32 : std_logic_vector(31 downto 0);
		variable v20 : std_logic_vector(19 downto 0);
		variable v_mul : std_logic_vector(63 downto 0);
	begin
		if (RESET = '1') then 
			PC_OUT <= (others=>'0');
		elsif rising_edge(CLK_EX) then
-----------------------------------------------------------
----	initialize (reg, ram, pc)
-----------------------------------------------------------
			if (init = '1') then
				case PC_IN is
					when x"00000000" => -- .init_heap_size
						heap_size := IR;
						REG_IN <= IR;
						N_REG <= "00010"; -- g2
						REG_COND <= "1000";
						RAM_WEN <= '0';	
						PC_OUT <= PC_IN + 1;
					when others =>
						RAM_IN <= IR;
						v32 := PC_IN - 1;
						N_RAM <= v32(19 downto 0);
						REG_COND <= "1000";
						RAM_WEN <= '1';	
						PC_OUT <= PC_IN + 1;
						if (heap_size(31 downto 2) = PC_IN(29 downto 0)) then
							init <= '0';
						end if;
				end case;
-----------------------------------------------------------
-----------------------------------------------------------
			else
				debug_count <= debug_count + 1;
				case op_code is

					when "000000" =>	-- SPECIAL
						case funct is
							when "100000" => -- ADD
								REG_IN <= REG_S + REG_T;
								N_REG <= n_reg_d;
								REG_COND <= "1000";
								RAM_WEN <= '0';	
								PC_OUT <= PC_IN + 1;
							when "100010" => -- SUB
								REG_IN <= REG_S - REG_T;
								N_REG <= n_reg_d;
								REG_COND <= "1000";
								RAM_WEN <= '0';	
								PC_OUT <= PC_IN + 1;
							when "011000" => -- MUL
								v_mul := REG_S * REG_T;
								REG_IN <= v_mul(31 downto 0);
								N_REG <= n_reg_d;
								REG_COND <= "1000";
								RAM_WEN <= '0';	
								PC_OUT <= PC_IN + 1;
							when "111111" => -- HALT
							when others =>	
						end case;
					when "000001" =>	-- IO
						case funct is
							when "000000" => -- INPUT
							when "000001" => -- OUTPUT
								RAM_IN <= REG_S;
								N_RAM <= x"01000";
								REG_COND <= "1000";
								RAM_WEN <= '1'; 
								PC_OUT <= PC_IN + 1;	
							when others =>
						end case;
					when "000111" =>	-- MVLO
						REG_IN <= REG_S(31 downto 16) & imm;
						N_REG <= n_reg_s;
						REG_COND <= "1000";
						RAM_WEN <= '0';	
						PC_OUT <= PC_IN + 1;
					when "001111" =>	-- MVHI
						REG_IN <= imm &  REG_S(15 downto 0);
						N_REG <= n_reg_s;
						REG_COND <= "1000";
						RAM_WEN <= '0';	
						PC_OUT <= PC_IN + 1;
					when "001000" =>	-- ADDI
						REG_IN <= REG_S + ex_imm;
						N_REG <= n_reg_t;
						REG_COND <= "1000";
						RAM_WEN <= '0';	
						PC_OUT <= PC_IN + 1;
					when "010000" =>	-- SUBI
						REG_IN <= REG_S - ex_imm;
						N_REG <= n_reg_t;
						REG_COND <= "1000";
						RAM_WEN <= '0';	
						PC_OUT <= PC_IN + 1;
					when "011000" =>	-- MULI
						v_mul := REG_S * ex_imm;
						REG_IN <= v_mul(31 downto 0);
						N_REG <= n_reg_t;
						REG_COND <= "1000";
						RAM_WEN <= '0';	
						PC_OUT <= PC_IN + 1;
					when "101000" =>	-- SLLI
						case imm(1 downto 0) is
							when "11" =>
								REG_IN <= REG_S(28 downto 0)&"000";
							when "10" =>
								REG_IN <= REG_S(29 downto 0)&"00";
							when "01" =>
								REG_IN <= REG_S(30 downto 0)&"0";
							when others =>
								REG_IN <= REG_S;
						end case;
						N_REG <= n_reg_t;
						REG_COND <= "1000";
						RAM_WEN <= '0';	
						PC_OUT <= PC_IN + 1;
					when "101010" =>	-- SRLI
						REG_IN <= REG_S(31)&REG_S(31 downto 1);
						N_REG <= n_reg_t;
						REG_COND <= "1000";
						RAM_WEN <= '0';	
						PC_OUT <= PC_IN + 1;
					when "110000" =>	-- CALL
						REG_COND <= "1010";
						N_REG <= "00001"; -- g1
						REG_IN <= x"000"&(FP_OUT - 4); -- push
						RAM_WEN <= '1';
						N_RAM <= "00"&FP_OUT(19 downto 2);
						RAM_IN <= LR_OUT;
						LR_IN <= PC_IN + 1;
						PC_OUT <= "00000000"&target(25 downto 2);
					when "111000" =>	-- RETURN
						REG_COND <= "1011";
						N_REG <= "00001"; -- g1
						v20 := FP_OUT + 4; -- next frame pointer
						REG_IN <= x"000"&(FP_OUT + 4); -- pop
						RAM_WEN <= '0';
						N_RAM <= "00"&v20(19 downto 2);
						PC_OUT <= LR_OUT;
					when "001010" =>	-- JEQ
						REG_COND <= "0000";
						RAM_WEN <= '0';	
						if (REG_S = REG_T) then
							PC_OUT <= PC_IN + (ex_imm(31)&ex_imm(31)&ex_imm(31 downto 2));
						else
							PC_OUT <= PC_IN + 1;
						end if;
					when "010010" =>	-- JNE
						REG_COND <= "0000";
						RAM_WEN <= '0';	
						if (REG_S /= REG_T) then
							PC_OUT <= PC_IN + (ex_imm(31)&ex_imm(31)&ex_imm(31 downto 2));
						else
							PC_OUT <= PC_IN + 1;
						end if;
					when "011010" =>	-- JLT
						REG_COND <= "0000";
						RAM_WEN <= '0';	
						if (REG_S < REG_T) then
							PC_OUT <= PC_IN + (ex_imm(31)&ex_imm(31)&ex_imm(31 downto 2));
						else
							PC_OUT <= PC_IN + 1;
						end if;
					when "000010" =>	-- JMP
						REG_COND <= "0000";
						RAM_WEN <= '0';	
						PC_OUT <= ("00000000"&target(25 downto 2));
					when "101011" =>	-- STI
						v32 := REG_S - ex_imm;
						N_RAM <= v32(21 downto 2);
						RAM_IN <= REG_T;
						REG_COND <= "0000";
						RAM_WEN <= '1'; 
						PC_OUT <= PC_IN + 1;	
					when "100011" =>	-- LDI
						v32 := REG_S - ex_imm;
						N_RAM <= v32(21 downto 2);
						N_REG <= n_reg_t;
						REG_COND <= "1100";
						RAM_WEN <= '0'; 
						PC_OUT <= PC_IN + 1;	
					when others =>	
						REG_COND <= "0000";
						RAM_WEN <= '0'; 
						debug_count <= x"ffffffff";
						PC_OUT <= PC_IN;
				end case;	
			end if;
		end if;	
	end process;	

end RTL;





