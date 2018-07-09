library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wallace_tree_A is
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
    S    : out std_ulogic_vector(N-1 downto 0);
    Cout : out std_ulogic
    );
end entity wallace_tree_A;

architecture behavioural of wallace_tree_A is

  COMPONENT full_adder
  port(
    A    : in std_ulogic;
    B    : in std_ulogic;
    Cin  : in std_ulogic;
    S    : out std_ulogic;
    Cout : out std_ulogic
    );
  END COMPONENT;

signal S0, S1, S2, S3, S4                : std_ulogic_vector(N-1 downto 0);
signal Cout0, Cout1, Cout2, Cout3, Cout4 : std_ulogic_vector(N-1 downto 0);
signal Cout_rca                          : std_ulogic_vector(N-2 downto 0);

begin

  csa1: for i in 0 to N-1 generate
    csa : full_adder port map
      (A(i), B(i), C(i), S0(i), Cout0(i));
  end generate csa1;

  csa2: for i in 0 to N-1 generate
    csa : full_adder port map
      (D(i), E(i), F(i), S1(i), Cout1(i));
  end generate csa2;

  csa3: for i in 0 to N-1 generate
    csa : full_adder port map
      (S0(i), Cout0(i), S1(i), S3(i), Cout3(i));
  end generate csa3;

  csa4: for i in 0 to N-1 generate
    csa : full_adder port map
      (S3(i), Cout3(i), Cout1(i), S4(i), Cout4(i));
  end generate csa4;

  S(0) <= S4(0);

  --RIPPLE CARRY ADDER
  rca0 : full_adder port map
    (Cout4(0), S4(1), '0', S(1), Cout_rca(0));

  rca: for i in 1 to N-2 generate
    rca : full_adder port map
      (Cout4(i), S4(i+1), Cout_rca(i-1), S(i+1), Cout_rca(i));
  end generate rca;

  rcalast : full_adder port map
    (Cout4(N-1), '0', Cout_rca(N-2), Cout, open);

end architecture behavioural;
