--------------------------------------------------------
--  DDL for Package EBA_GI_FW
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."EBA_GI_FW" as
    function compress_int (
        n in integer )
        return varchar2;
end;

/
