-- MASTER-ONLY: DO NOT MODIFY THIS FILE
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package rnd_pkg is

    type rnd_generator is protected
        procedure rnd_init(seed1, seed2: integer);
        impure function rnd_boolean return boolean;
        impure function rnd_bit return bit;
        impure function rnd_bit_vector(size: positive) return bit_vector;
        impure function rnd_std_ulogic return std_ulogic;
        impure function rnd_std_ulogic_vector(size: positive) return std_ulogic_vector;
        impure function rnd_integer(min, max: integer) return integer;
        impure function rnd_time(min, max: time) return time;
    end protected rnd_generator;

end package rnd_pkg;

package body rnd_pkg is

    type rnd_generator is protected body

        variable s1:  integer := 1;
        variable s2:  integer := 1;
        variable rnd: real;

        procedure throw is
        begin
            uniform(s1, s2, rnd);
        end procedure throw;

        procedure rnd_init(seed1, seed2: integer) is
        begin
            s1 := seed1;
            s2 := seed2;
        end procedure rnd_init;

        impure function rnd_boolean return boolean is
        begin
            throw;
            return rnd < 0.5;
        end function rnd_boolean;

        impure function rnd_bit return bit is
            variable res: bit := '0';
        begin
            if rnd_boolean then
                res := '1';
            end if;
            return res;
        end function rnd_bit;
    
        impure function rnd_bit_vector(size: positive) return bit_vector is
            variable res: bit_vector(1 to size);
        begin
            for i in 1 to size loop
                res(i) := rnd_bit;
            end loop;
            return res;
        end function rnd_bit_vector;

        impure function rnd_std_ulogic return std_ulogic is
        begin
            return to_stdulogic(rnd_bit);
        end function rnd_std_ulogic;
    
        impure function rnd_std_ulogic_vector(size: positive) return std_ulogic_vector is
        begin
            return to_stdulogicvector(rnd_bit_vector(size));
        end function rnd_std_ulogic_vector;

        impure function rnd_integer(min, max: integer) return integer is
        begin
            throw;
            return min + integer(real(max - min + 1) * rnd - 0.5);
        end function rnd_integer;

        impure function rnd_time(min, max: time) return time is
            variable res: time;
        begin
            throw;
            return min + (max - min) * rnd;
        end function rnd_time;

    end protected body rnd_generator;

end package body rnd_pkg;

