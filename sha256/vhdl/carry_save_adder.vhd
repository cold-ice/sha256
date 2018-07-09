library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity carry_save_adder is
  generic(
    N    : in natural range 4 to 128 := 32
  );
  port(
    A    : in std_ulogic_vector(N-1 downto 0);
    B    : in std_ulogic_vector(N-1 downto 0);
    Cin  : in std_ulogic_vector(N-1 downto 0);
    S    : out std_ulogic_vector(N-1 downto 0);
    Cout : out std_ulogic_vector(N-1 downto 0)
    );
end entity carry_save_adder;

architecture behavioural of carry_save_adder is

  COMPONENT full_adder
  port(
    A    : in std_ulogic;
    B    : in std_ulogic;
    Cin  : in std_ulogic;
    S    : out std_ulogic;
    Cout : out std_ulogic
    );
  END COMPONENT;

begin

  gen_csa: for i in 0 to N-1 generate
    csa : full_adder port map
      (A(i), B(i), Cin(i), S(i), Cout(i));
  end generate gen_csa;

end architecture behavioural;
