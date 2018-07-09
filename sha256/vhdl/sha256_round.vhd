library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity sha256_round is
  port(
    clk           : in  std_ulogic;
    DM_sresetn    : in  std_ulogic;
    alpha_sresetn : in  std_ulogic;
    stall         : in  std_ulogic;
    DM_en         : in  std_ulogic;
    DM0_en        : in  std_ulogic;
    DM4_en        : in  std_ulogic;
    DM_sel        : in  std_ulogic;
    alpha_en      : in  std_ulogic;
    AE_en         : in  std_ulogic;
    H_sel         : in  std_ulogic;
    alpha_sel     : in  std_ulogic;
    loadwi        : in  std_ulogic;
    nround        : in  natural range 0 to 64;
    M             : in  word;
    H0            : out word;
    H1            : out word;
    H2            : out word;
    H3            : out word;
    H4            : out word;
    H5            : out word;
    H6            : out word;
    H7            : out word
    );
end entity sha256_round;

architecture behavioural of sha256_round is

  type shrtype is array (0 to 15) of word;

  signal Qshr                           : shrtype;
  signal Aq, Bq, Cq, Dq, Eq, Fq, Gq, Hq : word;
  signal Ad, Ed                         : word;
  signal DM0, DM1, DM2, DM3             : word;
  signal DM4, DM5, DM6, DM7             : word;
  signal W, KJ                          : word;
  signal deltaj_S                       : word;
  signal deltaj_cout                    : word;
  signal adder1_A, adder1_B             : word;
  signal adder1_CA, adder1_CE           : word;
  signal adder1_SA, adder1_CoutA        : word;
  signal adder1_SE, adder1_CoutE        : word;
  signal adder2_AA, adder2_BA           : word;
  signal adder2_AE, adder2_BE           : word;
  signal Maj_buf, Ch_buf                : word;
  signal Sigma0_buf, Sigma1_buf         : word;
  signal shr_en                         : std_ulogic;

begin
  --DATAPATH
  alphabet_reg : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      --H register
      if(alpha_sresetn = '0') then
        Hq <= DM7;
      elsif(alpha_en = '1' and stall='0') then
        if(alpha_sel = '0' or H_sel = '1') then
          Hq <= DM6;
        elsif(alpha_sel = '1') then
          Hq <= Fq;
        end if;
      end if;
      --Registers G, F, D, C and B
      if(alpha_sresetn = '0') then
        Gq <= (others => '0');
        Fq <= (others => '0');
        Dq <= (others => '0');
        Cq <= (others => '0');
        Bq <= (others => '0');
      elsif(alpha_en = '1' and stall='0') then
        if(alpha_sel = '0') then
          Gq <= DM6;
          Fq <= DM5;
          Dq <= DM3;
          Cq <= DM2;
          Bq <= DM1;
        elsif(alpha_sel = '1') then
          Gq <= Fq;
          Fq <= Eq;
          Dq <= Cq;
          Cq <= Bq;
          Bq <= Aq;
        end if;
      end if;
      --Registers A and E
      if(alpha_sresetn = '0') then
        Eq <= (others => '0');
        Aq <= (others => '0');
      elsif(AE_en = '1' and stall='0') then
        Eq <= Ed;
        Aq <= Ad;
      end if;
    end if;
  end process alphabet_reg;

  WMUX : process(loadwi, M, Qshr(1), Qshr(6), Qshr(14), Qshr(15))
  begin
    if(loadwi = '0') then
      W <= M;
    else
      W <= std_ulogic_vector(unsigned(sig1(Qshr(1)))+unsigned(Qshr(6))+unsigned(sig0(Qshr(14)))+unsigned(Qshr(15)));
    end if;
  end process WMUX;

  shr_en <= not(stall) and alpha_en;

  shr0 : entity work.regNbit(behavioural)
    generic map(N => 32)
    port map(clk, W, shr_en, alpha_sresetn, Qshr(0));

  gen_shr : for i in 1 to 14 generate
    shr : entity work.regNbit(behavioural)
      generic map(N => 32)
      port map(clk, Qshr(i-1), shr_en, alpha_sresetn, Qshr(i));
  end generate gen_shr;

  shr15 : entity work.regNbit(behavioural)
    generic map(N => 32)
    port map(clk, Qshr(14), shr_en, alpha_sresetn, Qshr(15));

  KJselect : process(nround)
  begin
    if nround < 64 then
      KJ <= K(nround);
    else
      KJ <= (others => '0');
    end if;
  end process KJselect;

  Maj_buf    <= Maj(Aq, Bq, Cq);
  Ch_buf     <= Ch(Eq, Fq, Gq);
  Sigma0_buf <= Sigma0(Aq);
  Sigma1_buf <= Sigma1(Eq);

  deltaj_csa : entity work.carry_save_adder(behavioural)
    generic map(
      N => 32
      )
    port map(
      A    => KJ,
      B    => W,
      Cin  => Hq,
      S    => deltaj_S,
      cout => deltaj_Cout
      );

  with alpha_sresetn select adder1_A <= (others => '0') when '0',
                                        deltaj_S        when '1',
                                        (others => '0') when others;

  with alpha_sresetn select adder1_B <= (others => '0') when '0',
                                        deltaj_Cout(30 downto 0)&'0' when '1',
                                        (others => '0') when others;

  DM_MUX : process(DM_SEL, nround, DM4, DM0)
  begin
    if(DM_SEL = '0') then
      adder1_CE <= DM4;
      adder1_CA <= DM0;
    else
      adder1_CE <= (others => '0');
      adder1_CA <= (others => '0');
    end if;
  end process;

  adder1E_csa : entity work.carry_save_adder(behavioural)
    generic map(
      N => 32
      )
    port map(
      A    => adder1_A,
      B    => adder1_B,
      Cin  => adder1_CE,
      S    => adder1_SE,
      Cout => adder1_CoutE
      );

  adder2E_ff : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      if(stall='0') then
        adder2_AE <= adder1_SE;
        adder2_BE <= adder1_CoutE(30 downto 0)&'0';
      end if;
    end if;
  end process;

  adder2E : entity work.adder6(behavioural)
    generic map(
      N => 32
      )
    port map(
      A => adder2_AE,
      B => adder2_BE,
      C => Dq,
      D => Ch_buf,
      E => Sigma1_buf,
      F => X"00000000",
      S => Ed
      );

  adder2A_csa : entity work.carry_save_adder(behavioural)
    generic map(
      N => 32
      )
    port map(
      A    => adder1_A,
      B    => adder1_B,
      Cin  => adder1_CA,
      S    => adder1_SA,
      cout => adder1_CoutA
      );

  adder2A_ff : process(clk)
  begin
    if(RISING_EDGE(clk)) then
      if(stall='0') then
        adder2_AA <= adder1_SA;
        adder2_BA <= adder1_CoutA(30 downto 0)&'0';
      end if;
    end if;
  end process adder2A_ff;

  adder2A : entity work.adder6(behavioural)
    generic map(
      N => 32
      )
    port map(
      A => adder2_AA,
      B => adder2_BA,
      C => Maj_buf,
      D => Sigma0_buf,
      E => Ch_buf,
      F => Sigma1_buf,
      S => Ad
      );

  DM_reg : process(clk)
  begin
    if (RISING_EDGE(clk)) then
      if (DM_sresetn = '0') then
        DM0 <= H_init(0);
      elsif(DM0_en = '1') then
        DM0 <= Aq;
      end if;
      if (DM_sresetn = '0') then
        DM4 <= H_init(4);
      elsif(DM4_en = '1') then
        DM4 <= Eq;
      end if;
      if (DM_sresetn = '0') then
        DM1 <= H_init(1);
        DM2 <= H_init(2);
        DM3 <= H_init(3);
        DM5 <= H_init(5);
        DM6 <= H_init(6);
        DM7 <= H_init(7);
      elsif (DM_en = '1') then
        DM1 <= std_ulogic_vector(unsigned(Aq)+unsigned(DM3));
        DM2 <= DM1;
        DM3 <= DM2;
        DM5 <= std_ulogic_vector(unsigned(Eq)+unsigned(DM7));
        DM6 <= DM5;
        DM7 <= DM6;
      end if;
    end if;
  end process DM_reg;

  H0 <= DM0;
  H1 <= DM1;
  H2 <= DM2;
  H3 <= DM3;
  H4 <= DM4;
  H5 <= DM5;
  H6 <= DM6;
  H7 <= DM7;

end architecture behavioural;
