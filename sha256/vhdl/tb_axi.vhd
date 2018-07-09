library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

use work.sha256_pkg.all;

entity tb_axi is
end entity tb_axi;

architecture Msim_tb of tb_axi is

  signal clk, aresetn, arvalid, rready, awvalid, wvalid, bready : std_ulogic;
  signal rvalid, bvalid                                         : std_ulogic;
  signal araddr, awaddr                                         : std_ulogic_vector(11 downto 0);
  signal arprot, awprot                                         : std_ulogic_vector(2 downto 0);
  signal wdata                                                  : word;
  signal wstrb                                                  : std_ulogic_vector(3 downto 0);
  signal wrand, rrand                                           : natural range 0 to 10 := 0;

begin

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

  rnd_gen_ack : process
    variable seed1, seed2 : positive;   -- seed values for random generator
    variable rand         : real;  -- random real-number value in range 0 to 1.0
    variable range_ack    : real    := 10.0;  -- the range of random values created will be 0 to +10.
    variable phase        : natural := 0;
  begin
    if phase = 0 then
      phase := 1;
      wait for 1 ns;
    end if;
    uniform(seed1, seed2, rand);        -- generate random number
    rrand <= integer(rand*range_ack);  -- rescale to 0..10, convert integer part
    uniform(seed1, seed2, rand);        -- generate random number
    wrand <= integer(rand*range_ack);  -- rescale to 0..10, convert integer part
    uniform(seed1, seed2, rand);
    wstrb <= std_ulogic_vector(to_unsigned(integer(rand*range_ack), 4));
    wait for 10 ns;
  end process rnd_gen_ack;

  rnd_addr_data : process
    variable seed1, seed2 : positive;
    variable rand         : real;
    variable range_addr   : real    := 1024.0;
    variable range_data   : real    := 255.0;
    variable wdata0       : unsigned(7 downto 0);
    variable wdata1       : unsigned(7 downto 0);
    variable wdata2       : unsigned(7 downto 0);
    variable wdata3       : unsigned(7 downto 0);
    variable phase        : natural := 0;
  begin
    if phase = 0 then
      phase := 1;
      wait for 1 ns;
    end if;
    uniform(seed1, seed2, rand);
    araddr <= std_ulogic_vector(to_unsigned(integer(rand*range_addr), 12));
    uniform(seed1, seed2, rand);
    awaddr <= std_ulogic_vector(to_unsigned(integer(rand*range_addr), 12));
    uniform(seed1, seed2, rand);
    wdata0 := to_unsigned(integer(rand*range_data), 8);
    uniform(seed1, seed2, rand);
    wdata1 := to_unsigned(integer(rand*range_data), 8);
    uniform(seed1, seed2, rand);
    wdata2 := to_unsigned(integer(rand*range_data), 8);
    uniform(seed1, seed2, rand);
    wdata3 := to_unsigned(integer(rand*range_data), 8);
    wdata  <= std_ulogic_vector(wdata1 & wdata0 & wdata3 & wdata2);
    wait for 10 ns;
  end process rnd_addr_data;

  req_proc : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      arvalid <= '0';
      wvalid  <= '0';
      awvalid <= '0';
      if(rrand < 7) then
        arvalid <= '1';
      end if;
      if(wrand < 4) then
        awvalid <= '1';
      end if;
      if(wrand < 4 and rrand < 5) then
        wvalid <= '1';
      end if;
    end if;
  end process req_proc;

  ack_proc : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      rready <= '0';
      bready <= '0';
      if(rrand < 6) then
        rready <= '1';
      end if;
      if(wrand < 6) then
        bready <= '1';
      end if;
    end if;
  end process ack_proc;

  sha256_du : entity work.sha256_ctrl_axi(behavioural)
    port map(
      aclk           => clk,
      areset         => aresetn,
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
      s0_axi_awready => open,
      s0_axi_wready  => open,
      s0_axi_bresp   => open,
      s0_axi_bvalid  => bvalid
      );
end architecture Msim_tb;
