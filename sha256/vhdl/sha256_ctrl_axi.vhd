-- sha256 XL wrapper, AXI lite version, top level

--library unisim;
--use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi_pkg.all;
use work.sha256_pkg.all;

entity sha256_ctrl_axi is
  generic(
    NSTATUS : natural range 0 to 2048 := 9;
    NDATA   : natural range 0 to 2048 := 128
    );
  port(
    aclk           : in  std_ulogic;
    aresetn        : in  std_ulogic;
    s0_axi_araddr  : in  std_ulogic_vector(11 downto 0);
    s0_axi_arprot  : in  std_ulogic_vector(2 downto 0);
    s0_axi_arvalid : in  std_ulogic;
    s0_axi_rready  : in  std_ulogic;
    s0_axi_awaddr  : in  std_ulogic_vector(11 downto 0);
    s0_axi_awprot  : in  std_ulogic_vector(2 downto 0);
    s0_axi_awvalid : in  std_ulogic;
    s0_axi_wdata   : in  std_ulogic_vector(31 downto 0);
    s0_axi_wstrb   : in  std_ulogic_vector(3 downto 0);
    s0_axi_wvalid  : in  std_ulogic;
    s0_axi_bready  : in  std_ulogic;
    s0_axi_arready : out std_ulogic;
    s0_axi_rdata   : out std_ulogic_vector(31 downto 0);
    s0_axi_rresp   : out std_ulogic_vector(1 downto 0);
    s0_axi_rvalid  : out std_ulogic;
    s0_axi_awready : out std_ulogic;
    s0_axi_wready  : out std_ulogic;
    s0_axi_bresp   : out std_ulogic_vector(1 downto 0);
    s0_axi_bvalid  : out std_ulogic
    );
end entity sha256_ctrl_axi;

architecture behavioural of sha256_ctrl_axi is
  ------------------------------CONTROL UNIT------------------------------
  type read_states is (IDLE, RACK, ROK, RERR, RERROK);
  type write_states is (IDLE, WACK, WOK, WERR, WERROK, WRO, WROOK);
  signal status_read                       : read_states;
  signal next_status_read                  : read_states;
  signal status_write                      : write_states;
  signal next_status_write                 : write_states;
  signal rdata_en, rw_en                   : std_ulogic;
  signal ADDRESS_RANGE                     : integer := NSTATUS*4+NDATA*4;
  --------------------------------DATAPATH--------------------------------
  type reg_type is array (0 to NDATA+NSTATUS-1) of std_ulogic_vector(31 downto 0);
  type reg_dtype is array (0 to 7) of std_ulogic_vector(31 downto 0);
  signal data_reg                          : reg_type;
  signal raddress, waddress                : natural range 0 to 4096;
  signal nround                            : natural range 0 to 65;
  signal nwrites                           : natural range 0 to 4096;
  signal cblock, nblocks                   : natural range 0 to 4096;
  signal M, H0, H1, H2, H3, H4, H5, H6, H7 : word;
  signal stall, done, data_en              : std_ulogic;

begin
  ------------------------------CONTROL UNIT------------------------------
  update_read : process(aclk)
  begin
    if(RISING_EDGE(aclk)) then
      if(aresetn = '1') then
        status_read <= next_status_read;
      else
        status_read <= IDLE;
      end if;
    end if;
  end process update_read;

  control_read : process(status_read, s0_axi_arvalid, s0_axi_rready, s0_axi_araddr)
  begin
    case status_read is
      when IDLE =>
        s0_axi_arready <= '0';
        s0_axi_rvalid  <= '0';
        s0_axi_rresp   <= axi_resp_okay;
        rdata_en       <= '1';
        if(s0_axi_arvalid = '1' and to_integer(unsigned(s0_axi_araddr)) < ADDRESS_RANGE) then
          next_status_read <= RACK;
        elsif (s0_axi_arvalid = '1' and to_integer(unsigned(s0_axi_araddr)) >= ADDRESS_RANGE) then
          next_status_read <= RERR;
        else
          next_status_read <= IDLE;
        end if;

      when RACK =>
        s0_axi_arready <= '1';
        s0_axi_rvalid  <= '1';
        s0_axi_rresp   <= axi_resp_okay;
        rdata_en       <= '0';
        if(s0_axi_rready = '1') then
          next_status_read <= IDLE;
        else
          next_status_read <= ROK;
        end if;

      when ROK =>
        s0_axi_arready <= '0';
        s0_axi_rvalid  <= '1';
        s0_axi_rresp   <= axi_resp_okay;
        rdata_en       <= '0';
        if(s0_axi_rready = '1') then
          next_status_read <= IDLE;
        else
          next_status_read <= ROK;
        end if;

      when RERR =>
        s0_axi_arready <= '1';
        s0_axi_rvalid  <= '1';
        s0_axi_rresp   <= axi_resp_decerr;
        rdata_en       <= '0';
        if(s0_axi_rready = '1') then
          next_status_read <= IDLE;
        else
          next_status_read <= RERROK;
        end if;

      when RERROK =>
        s0_axi_arready <= '0';
        s0_axi_rvalid  <= '1';
        s0_axi_rresp   <= axi_resp_decerr;
        rdata_en       <= '0';
        if(s0_axi_rready = '1') then
          next_status_read <= IDLE;
        else
          next_status_read <= RERROK;
        end if;

      when others =>
        s0_axi_arready <= '0';
        s0_axi_rvalid  <= '0';
        s0_axi_rresp   <= axi_resp_okay;
        rdata_en       <= '1';
        if(s0_axi_arvalid = '1' and to_integer(unsigned(s0_axi_araddr)) < ADDRESS_RANGE) then
          next_status_read <= RACK;
        elsif (s0_axi_arvalid = '1' and to_integer(unsigned(s0_axi_araddr)) >= ADDRESS_RANGE) then
          next_status_read <= RERR;
        else
          next_status_read <= IDLE;
        end if;

    end case;
  end process control_read;

  update_write : process(aclk)
  begin
    if(RISING_EDGE(aclk)) then
      if(aresetn = '1') then
        status_write <= next_status_write;
      else
        status_write <= IDLE;
      end if;
    end if;
  end process update_write;

  control_write : process(status_write, s0_axi_awvalid, s0_axi_wvalid, s0_axi_awaddr, s0_axi_bready)
  begin

    case status_write is
      when IDLE =>
        s0_axi_awready <= '0';
        s0_axi_wready  <= '0';
        s0_axi_bresp   <= axi_resp_okay;
        s0_axi_bvalid  <= '0';
        rw_en          <= '1';
        if(s0_axi_awvalid = '1' and s0_axi_wvalid = '1' and to_integer(unsigned(s0_axi_awaddr)) < (NSTATUS*4)) then
          next_status_write <= WRO;
        elsif(s0_axi_awvalid = '1' and s0_axi_wvalid = '1' and to_integer(unsigned(s0_axi_awaddr)) >= ADDRESS_RANGE) then
          next_status_write <= WERR;
        elsif(s0_axi_awvalid = '1' and s0_axi_wvalid = '1' and to_integer(unsigned(s0_axi_awaddr)) >= NSTATUS*4 and to_integer(unsigned(s0_axi_awaddr)) < ADDRESS_RANGE) then
          next_status_write <= WACK;
        else
          next_status_write <= IDLE;
        end if;

      when WACK =>
        s0_axi_awready <= '1';
        s0_axi_wready  <= '1';
        s0_axi_bresp   <= axi_resp_okay;
        s0_axi_bvalid  <= '1';
        rw_en          <= '0';
        if(s0_axi_bready = '1') then
          next_status_write <= IDLE;
        else
          next_status_write <= WOK;
        end if;

      when WOK =>
        s0_axi_awready <= '0';
        s0_axi_wready  <= '0';
        s0_axi_bresp   <= axi_resp_okay;
        s0_axi_bvalid  <= '1';
        rw_en          <= '0';
        if(s0_axi_bready = '1') then
          next_status_write <= IDLE;
        else
          next_status_write <= WOK;
        end if;

      when WERR =>
        s0_axi_awready <= '1';
        s0_axi_wready  <= '1';
        s0_axi_bresp   <= axi_resp_decerr;
        s0_axi_bvalid  <= '1';
        rw_en          <= '0';
        if(s0_axi_bready = '1') then
          next_status_write <= IDLE;
        else
          next_status_write <= WERROK;
        end if;

      when WERROK =>
        s0_axi_awready <= '0';
        s0_axi_wready  <= '0';
        s0_axi_bresp   <= axi_resp_decerr;
        s0_axi_bvalid  <= '1';
        rw_en          <= '0';
        if(s0_axi_bready = '1') then
          next_status_write <= IDLE;
        else
          next_status_write <= WERROK;
        end if;

      when WRO =>
        s0_axi_awready <= '1';
        s0_axi_wready  <= '1';
        s0_axi_bresp   <= axi_resp_slverr;
        s0_axi_bvalid  <= '1';
        rw_en          <= '0';
        if(s0_axi_bready = '1') then
          next_status_write <= IDLE;
        else
          next_status_write <= WROOK;
        end if;

      when WROOK =>
        s0_axi_awready <= '0';
        s0_axi_wready  <= '0';
        s0_axi_bresp   <= axi_resp_slverr;
        s0_axi_bvalid  <= '1';
        rw_en          <= '0';
        if(s0_axi_bready = '1') then
          next_status_write <= IDLE;
        else
          next_status_write <= WROOK;
        end if;

      when others =>
        s0_axi_awready <= '0';
        s0_axi_wready  <= '0';
        s0_axi_bresp   <= axi_resp_okay;
        s0_axi_bvalid  <= '0';
        rw_en          <= '1';
        if(s0_axi_awvalid = '1' and s0_axi_wvalid = '1' and to_integer(unsigned(s0_axi_awaddr)) < (NSTATUS*4)) then
          next_status_write <= WRO;
        elsif(s0_axi_awvalid = '1' and s0_axi_wvalid = '1' and to_integer(unsigned(s0_axi_awaddr)) >= (ADDRESS_RANGE)) then
          next_status_write <= WERR;
        elsif(s0_axi_awvalid = '1' and s0_axi_wvalid = '1' and to_integer(unsigned(s0_axi_awaddr)) >= NSTATUS*4 and to_integer(unsigned(s0_axi_awaddr)) < ADDRESS_RANGE) then
          next_status_write <= WACK;
        else
          next_status_write <= IDLE;
        end if;

    end case;
  end process control_write;

  --------------------------------DATAPATH--------------------------------
  waddress <= to_integer(unsigned(s0_axi_awaddr(11 downto 2)));

  data_en <= rw_en and s0_axi_wvalid and s0_axi_awvalid;

  wreg : process(aclk)
  begin
    if(RISING_EDGE(aclk)) then
      -- Data registers
      if(aresetn = '1' and data_en = '1') then
        if(waddress >= NSTATUS and waddress < NSTATUS+NDATA) then
          if(s0_axi_wstrb(0) = '1') then
            data_reg(waddress)(7 downto 0) <= s0_axi_wdata(7 downto 0);
          end if;
          if(s0_axi_wstrb(1) = '1') then
            data_reg(waddress)(15 downto 8) <= s0_axi_wdata(15 downto 8);
          end if;
          if(s0_axi_wstrb(2) = '1') then
            data_reg(waddress)(23 downto 16) <= s0_axi_wdata(23 downto 16);
          end if;
          if(s0_axi_wstrb(3) = '1') then
            data_reg(waddress)(31 downto 24) <= s0_axi_wdata(31 downto 24);
          end if;
        end if;
      elsif(aresetn = '0' or done = '1') then
        for I in NSTATUS to (NSTATUS+NDATA-1) loop
          data_reg(I) <= (others => '0');
        end loop;
      end if;
      -- Hash registers
      if(aresetn = '0') then
        for I in 0 to 7 loop
          data_reg(I) <= (others => '0');
        end loop;
      elsif(done = '1') then
        data_reg(0) <= H0;
        data_reg(1) <= H1;
        data_reg(2) <= H2;
        data_reg(3) <= H3;
        data_reg(4) <= H4;
        data_reg(5) <= H5;
        data_reg(6) <= H6;
        data_reg(7) <= H7;
      end if;
      -- Status register
      if(aresetn = '0' or (aresetn = '1' and data_en = '1' and (waddress = 9 or waddress = 10))) then
        data_reg(8) <= (others => '0');
      else
        if(done = '1') then
          data_reg(8)(0) <= '1';
        end if;
        data_reg(8)(6 downto 1)   <= std_ulogic_vector(to_unsigned(nwrites, 6));
        data_reg(8)(12 downto 7)  <= std_ulogic_vector(to_unsigned(nround, 6));
        data_reg(8)(18 downto 13) <= std_ulogic_vector(to_unsigned(nblocks, 6));
        data_reg(8)(19)           <= stall;
        data_reg(8)(31 downto 20) <= H0(11 downto 0);
      end if;
    end if;
  end process wreg;

  data_cnt : process(aclk)
  begin
    if(RISING_EDGE(aclk)) then
      if(aresetn = '0' or done = '1') then
        nwrites <= 0;
      elsif(data_en = '1' and waddress > 10 and waddress < NSTATUS+NDATA) then
        nwrites <= nwrites + 1;
      end if;
    end if;
  end process data_cnt;

  raddress <= to_integer(unsigned(s0_axi_araddr(11 downto 2)));

  rdata_reg : process(aclk)
  begin
    if(RISING_EDGE(aclk)) then
      if(aresetn = '0') then
        s0_axi_rdata <= (others => '0');
      else
        if(s0_axi_arvalid = '1' and rdata_en = '1' and raddress < (NSTATUS+NDATA-1)) then
          s0_axi_rdata <= data_reg(raddress);
        elsif(s0_axi_rready = '1' and rdata_en = '0') then
          s0_axi_rdata <= (others => '0');
        end if;
      end if;
    end if;
  end process rdata_reg;

  nblocks <= to_integer(unsigned(data_reg(9)));

  M_select : process(nround, data_reg, cblock)
  begin
    if(nround+cblock*16 < (NDATA-1)) then
      -- LITTLE ENDIAN ONLY
      M(7 downto 0) <= data_reg(nround+cblock*16+11)(31 downto 24);
      M(15 downto 8) <= data_reg(nround+cblock*16+11)(23 downto 16);
      M(23 downto 16) <= data_reg(nround+cblock*16+11)(15 downto 8);
      M(31 downto 24) <= data_reg(nround+cblock*16+11)(7 downto 0);
    else
      M <= (others => '0');
    end if;
  end process M_select;

  stall_proc : process(nround, cblock, nwrites, data_reg(9))
  begin
    if nwrites < 1 then
      stall <= '1';
    elsif(nround < 16 and (nround + cblock*16) = nwrites-1 and nwrites < (to_integer(unsigned(data_reg(9)))*16)) then
      stall <= '1';
    else
      stall <= '0';
    end if;
  end process stall_proc;

  sha256cu : entity work.sha256_cu(behavioural)
    port map(
      clk     => aclk,
      sresetn => aresetn,
      nblocks => nblocks,
      stall   => stall,
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

end architecture behavioural;
