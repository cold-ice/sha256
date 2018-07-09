library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity full_adder is
  port(
    A    : in std_ulogic;
    B    : in std_ulogic;
    Cin  : in std_ulogic;
    S    : out std_ulogic;
    Cout : out std_ulogic
    );
end entity full_adder;

architecture behavioural of full_adder is

  signal node1 : std_ulogic;

begin

  node1 <= A XOR B;
  S <= node1 XOR Cin;
  Cout <= (A AND B) OR (node1 AND Cin);

end architecture behavioural;
