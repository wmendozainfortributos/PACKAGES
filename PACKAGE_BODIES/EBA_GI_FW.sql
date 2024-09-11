--------------------------------------------------------
--  DDL for Package Body EBA_GI_FW
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."EBA_GI_FW" as
	function compress_int (
        n in integer )
        return varchar2
    as
        ret varchar2(30);
        quotient integer;
        remainder integer;
        digit char(1);
    begin
        ret := '';
        quotient := n;
        while quotient > 0
        loop
            remainder := mod(quotient, 10 + 26);
            quotient := floor(quotient  / (10 + 26));
            if remainder < 26 then
                digit := chr(ascii('A') + remainder);
            else
                digit := chr(ascii('0') + remainder - 26);
            end if;
            ret := digit || ret;
        end loop ;
        if length(ret) < 5 then
            ret := lpad(ret, 4, 'A');
        end if ;
        return upper(ret);
    end compress_int;

end;

/
