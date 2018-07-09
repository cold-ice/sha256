library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regNbit is
  generic(
    N : in natural range 4 to 128 := 32
    );
  port(
    clk     : in  std_ulogic;
    D       : in  std_ulogic_vector(N-1 downto 0);
    en      : in  std_ulogic;
    sresetn : in  std_ulogic;
    Q       : out std_ulogic_vector(N-1 downto 0)
    );
end entity regNbit;

architecture behavioural of regNbit is

begin

  reg : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      if(sresetn='0') then
        Q <= (others=>'0');
      elsif(en='1') then
        Q <= D;
      end if;
    end if;
  end process reg;

end architecture behavioural;
