library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder6 is
  generic(
    N    : in natural range 4 to 128 := 32
  );
  port(
    A    : in std_ulogic_vector(N-1 downto 0);
    B    : in std_ulogic_vector(N-1 downto 0);
    C    : in std_ulogic_vector(N-1 downto 0);
    D    : in std_ulogic_vector(N-1 downto 0);
    E    : in std_ulogic_vector(N-1 downto 0);
    F    : in std_ulogic_vector(N-1 downto 0);
    S    : out std_ulogic_vector(N-1 downto 0)
    );
end entity adder6;

architecture behavioural of adder6 is
begin
  S<=std_ulogic_vector(unsigned(A)+unsigned(B)+unsigned(C)+unsigned(D)+unsigned(E)+unsigned(F));
end architecture behavioural;
