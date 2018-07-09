library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg32bit_axi is
  port(
    clk     : in  std_ulogic;
    D       : in  std_ulogic_vector(31 downto 0);
    en      : in  std_ulogic;
    sresetn : in  std_ulogic;
    strobe  : in  std_ulogic_vector(3 downto 0);
    Q       : out std_ulogic_vector(31 downto 0)
    );
end entity reg32bit_axi;

architecture behavioural of reg32bit_axi is

begin

  reg : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      if(sresetn = '0') then
        Q <= (others => '0');
      elsif(en = '1') then
        if(strobe(0) = '1') then
          Q(7 downto 0) <= D(7 downto 0);
        end if;
        if(strobe(1) = '1') then
          Q(15 downto 8) <= D(15 downto 8);
        end if;
        if(strobe(2) = '1') then
          Q(23 downto 16) <= D(23 downto 16);
        end if;
        if(strobe(3) = '1') then
          Q(31 downto 24) <= D(31 downto 24);
        end if;
      end if;
    end if;
  end process reg;

end architecture behavioural;
