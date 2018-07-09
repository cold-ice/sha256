library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity tb_round is
end entity tb_round;

architecture Msim_tb of tb_round is

  type word_array is array (0 to 15) of word;
  type word_array2 is array (0 to 31) of word;

  signal clk, sresetn, start, done         : std_ulogic;
  signal M, H0, H1, H2, H3, H4, H5, H6, H7 : word;
  signal nround                            : natural range 0 to 64;
  signal cblock                            : natural range 0 to 2048;
  -- CAREFUL: THE TESTBENCH WON'T WORK AS EXPECTED WITHOUT REVERSING THE BYTE ORDER OF THE MESSAGES --
  signal M_total : word_array := (
    x"61626380", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000018");
  signal M_total1 : word_array2 := (
    x"61626364", x"62636465", x"63646566", x"64656667", x"65666768", x"66676869", x"6768696a", x"68696a6b",
    x"696a6b6c", x"6a6b6c6d", x"6b6c6d6e", x"6c6d6e6f", x"6d6e6f70", x"6e6f7071", x"80000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"000001c0");

begin

  clk_signal : process
  begin
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
  end process clk_signal;

  ctrl_signals : process
  begin
    sresetn <= '0';
    start   <= '0';
    wait for 40 ns;
    sresetn <= '1';
    wait for 20 ns;
    start   <= '1';
    wait;
  end process ctrl_signals;

  M_update : process(nround, cblock)
  begin
    if(nround < 16 and cblock < 2) then
      -- LITTLE ENDIAN ONLY
      M <= M_total1(nround+cblock*16);
    else
      M <= (others => '0');
    end if;
  end process M_update;

  tb_sha256cu : entity work.sha256_cu(behavioural)
    port map(
      clk     => clk,
      sresetn => sresetn,
      nblocks => 2,
      stall   => '0',
      M       => M,
      nround  => nround,
      cblock  => cblock,
      done    => done,
      H0      => H0,
      H1      => H1,
      H2      => H2,
      H3      => H3,
      H4      => H4,
      H5      => H5,
      H6      => H6,
      H7      => H7
      );

end architecture Msim_tb;
