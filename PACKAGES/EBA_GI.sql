--------------------------------------------------------
--  DDL for Package EBA_GI
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."EBA_GI" as
    -------------------------------------------------------------------------
    -- Generates a unique Identifier
    -------------------------------------------------------------------------
    function gen_id return number;
	
end eba_gi;

/
