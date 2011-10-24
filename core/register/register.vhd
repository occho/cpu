--Wed Oct  5 19:33:13 2011
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity Registers is
  port (
    rs,rt,rd : in std_logic_vector(4 downto 0);  -- opcode [25 - 0]
    RegDst : in std_logic;              -- 書く番号の選択(Mux)
    MemtoReg : in std_logic_vector(1 downto 0);    -- 書きこむデータの選択(Mux)
    MemWrite : in std_logic;            -- 立った時点の値が書き込まれる
    GorF   : in std_logic := '0';       -- Grobal or Floating point
    DMR, ALUOut : in std_logic_vector(31 downto 0); -- DMR:DataMemoryRegister
    REG_InData : in std_logic_vector(31 downto 0);
    A, B   : out std_logic_vector(31 downto 0));
end Registers;

architecture rgstr of Registers is
  type reg_set is array(0 to 31) of std_logic_vector(35 downto 0);
  signal greg : reg_set;                 -- grobal regster set
  signal freg : reg_set;                 -- FP register set
  signal Wnum : std_logic_vector(4 downto 0);
  signal Wdata : std_logic_vector(31 downto 0);
begin  -- reg

  readout: process (rs, rt)
  begin  -- process read
    if GorF = '1' then
      A <= freg(conv_integer(rs));
      B <= freg(conv_integer(rt));
    else
      A <= greg(conv_integer(rs));
      B <= greg(conv_integer(rt));
    end if;
  end process read;

  MuxA: process (rt, rd, RegDst)
  begin  -- process MuxA
    if RegDst = '0' then
      Wnum <= rs;
    else
      Wnum <= rt;
    end if;
  end process MuxA;

  MuxB: process (MemtoReg, rd, ALU_out, DMR, MemWrite, GorF, REG_InData)
  begin  -- process MuxB
    case MemtoReg is
      when "00" => Wdata <= ALUOut;
      when "01" => Wdata <= DMR;
      when "10" => Wdata <= REG_InData;
      when others => null;
    end case;
    if MemWrite = '1' then
      if GorF = '1' then
        freg(conv_integer(Wnum)) <= Wdata;
      else
        greg(conv_integer(Wnum)) <= Wdata;
      end if;
    end if;
  end process MuxB;

end rgstr;
