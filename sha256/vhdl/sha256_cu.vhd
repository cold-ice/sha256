library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity sha256_cu is
  port(
    clk     : in  std_ulogic;
    sresetn : in  std_ulogic;
    nblocks : in  natural range 0 to 2048;
    stall   : in  std_ulogic;
    M       : in  word;
    nround  : out natural range 0 to 65;
    cblock  : out natural range 0 to 2048;
    done    : out std_ulogic;
    H0      : out word;
    H1      : out word;
    H2      : out word;
    H3      : out word;
    H4      : out word;
    H5      : out word;
    H6      : out word;
    H7      : out word
    );
end entity sha256_cu;

architecture behavioural of sha256_cu is

  type word_array is array (0 to 15) of word;
  type states is (RESET, IDLE, INIT, HASH0, HASH1, UPDATE0, UPDATE1, UPDATE2,
                  UPDATE3, HASH_COMPLETE);

  constant MAX_BLOCKS : natural range 0 to 2048 := 2048;

  signal STATE, NEXTSTATE                 : states;
  signal DM_sresetn, alpha_sresetn, AE_en : std_ulogic;
  signal DM_en, DM0_en, DM4_en, DM_SEL    : std_ulogic;
  signal alpha_en, alpha_SEL, H_sel       : std_ulogic;
  signal count_en, loadwi, add_block      : std_ulogic;
  signal nround_buff                      : natural range 0 to 64;
  signal proc_blocks                      : natural range 0 to MAX_BLOCKS;

begin

  nround <= nround_buff;
  cblock <= proc_blocks;

  sha256round : entity work.sha256_round(behavioural)
    port map(
      clk           => clk,
      DM_sresetn    => DM_sresetn,
      alpha_sresetn => alpha_sresetn,
      stall         => stall,
      DM_en         => DM_en,
      DM0_en        => DM0_en,
      DM4_en        => DM4_en,
      DM_SEL        => DM_SEL,
      alpha_en      => alpha_en,
      AE_en         => AE_en,
      H_sel         => H_sel,
      alpha_sel     => alpha_sel,
      loadwi        => loadwi,
      nround        => nround_buff,
      M             => M,
      H0            => H0,
      H1            => H1,
      H2            => H2,
      H3            => H3,
      H4            => H4,
      H5            => H5,
      H6            => H6,
      H7            => H7
      );

  nround_update : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      if(alpha_sresetn = '0' or nround_buff = 64) then
        nround_buff <= 0;
      elsif(count_en = '1' and nround_buff < 64 and stall = '0') then
        nround_buff <= nround_buff+1;
      end if;
    end if;
  end process nround_update;

  proc_blocks_update : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      if(DM_sresetn = '0') then
        proc_blocks <= 0;
      elsif(add_block = '1' and proc_blocks < MAX_BLOCKS and stall = '0') then
        proc_blocks <= proc_blocks+1;
      end if;
    end if;
  end process proc_blocks_update;

  updatestate : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      if(sresetn = '0') then
        STATE <= RESET;
      elsif(stall = '0') then
        STATE <= NEXTSTATE;
      end if;
    end if;
  end process updatestate;

	-- Please notice that the pleonastic signal assignments present in the various case statements of the currentstate process are purely present to keep track of important signal switchings, e.g. DM_sel being set to 0 inside the state UPDATE1.

  currentstate : process(nround_buff, STATE, proc_blocks, nblocks)
  begin
    count_en      <= '0';
    alpha_sresetn <= '1';
    DM_sresetn    <= '1';
    alpha_en      <= '0';
    AE_en         <= '0';
    alpha_sel     <= '0';
    loadwi        <= '0';
    DM_SEL        <= '0';
    DM_en         <= '0';
    DM0_en        <= '0';
    DM4_en        <= '0';
    add_block     <= '0';
    H_sel         <= '0';
    done          <= '0';
    case STATE is
      when RESET =>
        alpha_sresetn <= '0';
        DM_sresetn    <= '0';
        NEXTSTATE     <= IDLE;

      when IDLE =>
        alpha_sresetn <= '0';
        if nblocks /= 0 then
          NEXTSTATE <= INIT;
        else
          NEXTSTATE <= IDLE;
        end if;

      when INIT =>
        alpha_en  <= '1';
        AE_en     <= '1';
        DM_SEL    <= '1';
        count_en  <= '1';
        NEXTSTATE <= HASH0;

      when HASH0 =>
        alpha_en  <= '1';
        AE_en     <= '1';
        alpha_sel <= '1';
        DM_SEL    <= '1';
        count_en  <= '1';
        if nround_buff = 15 then
          NEXTSTATE <= HASH1;
        else
          NEXTSTATE <= HASH0;
        end if;

      when HASH1 =>
        alpha_en  <= '1';
        AE_en     <= '1';
        alpha_sel <= '1';
        DM_SEL    <= '1';
        count_en  <= '1';
        loadwi    <= '1';
        if nround_buff = 61 then
          NEXTSTATE <= UPDATE0;
        else
          NEXTSTATE <= HASH1;
        end if;

      when UPDATE0 =>
        alpha_en  <= '1';
        AE_en     <= '1';
        alpha_sel <= '1';
        DM_SEL    <= '1';
        count_en  <= '1';
        loadwi    <= '1';
        DM_en     <= '1';
        NEXTSTATE <= UPDATE1;

      when UPDATE1 =>
        alpha_en  <= '1';
        AE_en     <= '1';
        alpha_sel <= '1';
        DM_SEL    <= '0';
        count_en  <= '1';
        loadwi    <= '1';
        DM_en     <= '1';
        NEXTSTATE <= UPDATE2;

      when UPDATE2 =>
        alpha_en  <= '1';
        AE_en     <= '1';
        alpha_sel <= '1';
        DM_SEL    <= '1';
        DM_en     <= '1';
        add_block <= '1';
        H_sel     <= '1';
        count_en  <= '1';
        NEXTSTATE <= UPDATE3;

      when UPDATE3 =>
        alpha_en <= '1';
        DM_SEL   <= '1';
        count_en <= '1';
        DM0_en   <= '1';
        DM4_en   <= '1';
        if nblocks = proc_blocks then
          NEXTSTATE <= HASH_COMPLETE;
        else
          NEXTSTATE <= HASH0;
        end if;

      when HASH_COMPLETE =>
        alpha_sresetn <= '0';
        DM_sresetn    <= '0';
        done          <= '1';
        NEXTSTATE     <= IDLE;

      when others =>
        alpha_sresetn <= '0';
        DM_sresetn    <= '0';
        NEXTSTATE     <= IDLE;

    end case;
  end process currentstate;

end architecture behavioural;
