--------------------------------------------------------
--  DDL for Package Body EBA_GI
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."EBA_GI" as  
    -------------------------------------------------------------------------
    -- Generates a unique Identifier
    -------------------------------------------------------------------------
    function gen_id
        return number
    is
        l_id  number;
    begin
        select to_number(sys_guid(), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
          into l_id
          from dual;
    
        return l_id;
    end gen_id;
end;

/
