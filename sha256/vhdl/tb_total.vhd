library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sha256_pkg.all;

entity tb_total is
end entity tb_total;

architecture Msim_tb of tb_total is

  type word_array is array (0 to 31) of word;
  -- CAREFUL: THE TESTBENCH WON'T WORK AS EXPECTED WITHOUT REVERSING THE BYTE ORDER OF THE MESSAGES --
  signal M_total : word_array := (
    x"61626364", x"62636465", x"63646566", x"64656667", x"65666768", x"66676869", x"6768696a", x"68696a6b",
    x"696a6b6c", x"6a6b6c6d", x"6b6c6d6e", x"6c6d6e6f", x"6d6e6f70", x"6e6f7071", x"80000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"000001c0");

  type word_array2 is array (0 to 15) of word;
  signal M_total2 : word_array2 := (
    x"61626380", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000018");

  signal clk, aresetn, arvalid, rready, awvalid, wvalid, bready : std_ulogic;
  signal rvalid, bvalid, awready, wready                        : std_ulogic;
  signal araddr, awaddr                                         : std_ulogic_vector(11 downto 0);
  signal arprot, awprot                                         : std_ulogic_vector(2 downto 0);
  signal wdata                                                  : word;
  signal wstrb                                                  : std_ulogic_vector(3 downto 0);
  signal wrand, rrand                                           : natural range 0 to 10   := 0;
  signal index                                                  : natural range 0 to 2048 := 0;

begin
  wstrb <= "1111";

  reset : process
  begin
    aresetn <= '0';
    wait for 40 ns;
    aresetn <= '1';
    wait;
  end process reset;

  clk_proc : process
  begin
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
  end process clk_proc;

  rready  <= '0';
  bready  <= '1';
  arvalid <= '0';
  araddr  <= (others => '0');


  msg_send : process
  begin
    awaddr  <= "000000100100";
    wdata   <= x"00000002";
    wvalid  <= '1';
    awvalid <= '1';
    wait until awready = '1' and wready = '1';
    wait for 1 ns;
    awaddr  <= "000000101100";
    wdata  <= M_total(0)(7 downto 0)&M_total(0)(15 downto 8)&M_total(0)(23 downto 16)&M_total(0)(31 downto 24);
    for I in 1 to 31 loop
      wait until awready = '1' and wready = '1';
      wait for 1 ns;
      awaddr <= std_ulogic_vector(unsigned(awaddr)+4);
      wdata  <= M_total(I)(7 downto 0)&M_total(I)(15 downto 8)&M_total(I)(23 downto 16)&M_total(I)(31 downto 24);
    end loop;
    wait until awready = '1' and wready = '1';
    wait for 1 ns;
    wvalid  <= '0';
    awvalid <= '0';
    wait for 4 us;
    awaddr  <= "000000100100";
    wdata   <= x"00000001";
    wvalid  <= '1';
    awvalid <= '1';
    wait until awready = '1' and wready = '1';
    wait for 1 ns;
    awaddr  <= "000000101100";
    wdata  <= M_total2(0)(7 downto 0)&M_total2(0)(15 downto 8)&M_total2(0)(23 downto 16)&M_total2(0)(31 downto 24);
    for I in 1 to 15 loop
      wait until awready = '1' and wready = '1';
      wait for 1 ns;
      awaddr <= std_ulogic_vector(unsigned(awaddr)+4);
      wdata  <= M_total2(I)(7 downto 0)&M_total2(I)(15 downto 8)&M_total2(I)(23 downto 16)&M_total2(I)(31 downto 24);
    end loop;
    wait until awready = '1' and wready = '1';
    wait for 1 ns;
    wvalid  <= '0';
    awvalid <= '0';
    wait;
  end process msg_send;

  sha256_du : entity work.sha256_ctrl_axi(behavioural)
    port map(
      aclk           => clk,
      aresetn        => aresetn,
      s0_axi_araddr  => araddr,
      s0_axi_arprot  => arprot,
      s0_axi_arvalid => arvalid,
      s0_axi_rready  => rready,
      s0_axi_awaddr  => awaddr,
      s0_axi_awprot  => awprot,
      s0_axi_awvalid => awvalid,
      s0_axi_wdata   => wdata,
      s0_axi_wstrb   => wstrb,
      s0_axi_wvalid  => wvalid,
      s0_axi_bready  => bready,
      s0_axi_arready => open,
      s0_axi_rdata   => open,
      s0_axi_rresp   => open,
      s0_axi_rvalid  => rvalid,
      s0_axi_awready => awready,
      s0_axi_wready  => wready,
      s0_axi_bresp   => open,
      s0_axi_bvalid  => bvalid
      );
end architecture Msim_tb;
