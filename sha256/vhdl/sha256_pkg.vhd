-- MASTER-ONLY: DO NOT MODIFY THIS FILE
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sha256_pkg is
  subtype word is std_ulogic_vector(31 downto 0);
  type H_array is array (0 to 7) of word;
  type K_array is array (0 to 63) of word;

  constant H_init  : H_array;
  constant K       : K_array;

  function Ch (x, y, z : word) return word;
  function Maj (x, y, z : word) return word;
  function Sigma0(x : word) return word;
  function Sigma1(x : word) return word;
  function sig0(x : word) return word;
  function sig1(x : word) return word;

end package sha256_pkg;

package body sha256_pkg is

  constant H_init : H_array :=(x"6a09e667",  --0
                               x"bb67ae85",  --1
                               x"3c6ef372",  --2
                               x"a54ff53a",  --3
                               x"510e527f",  --4
                               x"9b05688c",  --5
                               x"1f83d9ab",  --6
                               x"5be0cd19"); --7

  constant K : K_array := ( x"428a2f98", x"71374491", x"b5c0fbcf", x"e9b5dba5", x"3956c25b",
  x"59f111f1", x"923f82a4", x"ab1c5ed5", x"d807aa98", x"12835b01", x"243185be", x"550c7dc3", x"72be5d74",
  x"80deb1fe", x"9bdc06a7", x"c19bf174", x"e49b69c1", x"efbe4786", x"0fc19dc6", x"240ca1cc", x"2de92c6f",
  x"4a7484aa", x"5cb0a9dc", x"76f988da", x"983e5152", x"a831c66d", x"b00327c8", x"bf597fc7", x"c6e00bf3",
  x"d5a79147", x"06ca6351", x"14292967", x"27b70a85", x"2e1b2138", x"4d2c6dfc", x"53380d13",
  x"650a7354", x"766a0abb", x"81c2c92e", x"92722c85", x"a2bfe8a1", x"a81a664b", x"c24b8b70", x"c76c51a3",
  x"d192e819", x"d6990624", x"f40e3585", x"106aa070", x"19a4c116", x"1e376c08", x"2748774c", x"34b0bcb5",
  x"391c0cb3", x"4ed8aa4a", x"5b9cca4f", x"682e6ff3", x"748f82ee", x"78a5636f", x"84c87814", x"8cc70208",
  x"90befffa", x"a4506ceb", x"bef9a3f7", x"c67178f2");

  function Ch (x, y, z : word) return word is
    variable ret : word;
    begin
      ret := (x AND y) XOR ( (NOT x) AND z);
      return ret;
  end function Ch;

  function Maj (x, y, z : word) return word is
    variable ret : word;
    begin
      ret := (x AND y) XOR (x AND z) XOR (y AND z);
      return ret;
  end function Maj;

  function Sigma0 (x : word) return word is
    variable ret : word;
    begin
      ret := x(1 downto 0)&x(31 downto 2) XOR x(12 downto 0)&x(31 downto 13) XOR x(21 downto 0)&x(31 downto 22);
      return ret;
  end function Sigma0;

  function Sigma1 (x : word) return word is
    variable ret : word;
    begin
      ret := x(5 downto 0)&x(31 downto 6) XOR x(10 downto 0)&x(31 downto 11) XOR x(24 downto 0)&x(31 downto 25);
      return ret;
  end function Sigma1;

  function sig0 (x : word) return word is
    variable ret : word;
    begin
      ret := x(6 downto 0)&x(31 downto 7) XOR x(17 downto 0)&x(31 downto 18) XOR "000"&x(31 downto 3);
      return ret;
  end function sig0;

  function sig1 (x : word) return word is
    variable ret : word;
    begin
      ret := x(16 downto 0)&x(31 downto 17) XOR x(18 downto 0)&x(31 downto 19) XOR "0000000000"&x(31 downto 10);
      return ret;
  end function sig1;

end package body sha256_pkg;
