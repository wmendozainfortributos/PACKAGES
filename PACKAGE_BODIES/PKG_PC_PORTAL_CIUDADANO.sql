--------------------------------------------------------
--  DDL for Package Body PKG_PC_PORTAL_CIUDADANO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_PC_PORTAL_CIUDADANO" as

    procedure prc_sg_autenticar( p_cdgo_clnte   in  number 
                               , p_username     in  varchar2
                               , p_password     in  varchar2 
                               , o_cdgo_rspsta  out number
                               , o_mnsje_rspsta out varchar2
                               , o_tken         out varchar2
                               , o_id_usrio     out number
                               , o_nmbre_trcro  out varchar2)
    as 

        v_undad_drcion  df_c_definiciones_cliente.vlor%type;
        v_drcion        df_c_definiciones_cliente.vlor%type;  
        v_time          number;
        v_session       varchar2(4000); 

    begin 
        o_cdgo_rspsta := 0;
        begin
            pkg_sg_autenticacion.prc_sg_autenticar( p_cdgo_clnte   => p_cdgo_clnte
                                                  , p_username     => p_username
                                                  , p_password     => p_password
                                                  , o_cdgo_rspsta  => o_cdgo_rspsta
                                                  , o_mnsje_rspsta => o_mnsje_rspsta);
            if(o_cdgo_rspsta != 0) then       
                return;
            end if;

            --CONSULTAMOS LOS DATOS DEL USUARIO
            begin
                select id_usrio
                     , nmbre_trcro
                  into o_id_usrio
                     , o_nmbre_trcro
                  from v_sg_g_usuarios 
                 where cdgo_clnte = p_cdgo_clnte 
                   and lower(user_name) = lower(p_username);
            exception
                when others then
                    o_cdgo_rspsta  := 1;
                    o_mnsje_rspsta := 'No se pudo realizar el proceso de autenticación';
            end;

            --Consultamos las definiciones
            v_undad_drcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte            => p_cdgo_clnte,
                                                                              p_cdgo_dfncion_clnte_ctgria => 'SGR',
                                                                              p_cdgo_dfncion_clnte        => 'UTP');

            --Valor por Defecto Hora
            v_undad_drcion := ( case when v_undad_drcion <> '-1' then v_undad_drcion else 'HR' end );

            v_drcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte        => p_cdgo_clnte,
                                                                        p_cdgo_dfncion_clnte_ctgria => 'SGR',
                                                                        p_cdgo_dfncion_clnte    => 'DTP');

            --Valor por Defecto 24 horas
            v_drcion := ( case when v_drcion <> '-1' then v_drcion else '24' end );

            --Calcula el Tiempo en Segundo
            v_time := round(( cast( pk_util_calendario.fnc_cl_fecha_final( p_fecha_inicial => systimestamp
                                                                         , p_undad_drcion  => v_undad_drcion
                                                                         , p_drcion        => v_drcion ) as date ) - sysdate ) * (24 * 3600));

            --Genaramos el token
            o_tken := apex_jwt.encode( p_iss           => p_username
                                     , p_sub           => p_cdgo_clnte
                                     , p_aud           => o_id_usrio
                                     , p_exp_sec       => v_time
                                     , p_other_claims  => '"cdgo_clnte": '||apex_json.stringify(p_cdgo_clnte)
                                     , p_signature_key => pkg_sg_autenticacion.g_signature_key ); 
        exception 
            when others then 
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := 'No se pudo realizar el proceso de autenticación ' ||  sqlerrm;
        end;
    end prc_sg_autenticar;

    procedure prc_rg_usuario( p_id_trcro_prtal  in  number
                            , p_password        in  varchar2
                            , p_password_re     in  varchar2 
                            , o_cdgo_rspsta     out number
                            , o_mnsje_rspsta    out varchar2)
    as        
        v_tp            		si_c_terceros_portal%rowtype;
        v_id_trcro      		number;
		v_count_trcro			number;
		v_cdgo_idntfccion_tpo	si_c_terceros.cdgo_idntfccion_tpo%type;
        v_password      		varchar2(500);
        v_count         		number;
        v_fcha_exprcion 		date        := sysdate + 365;   

    begin
        o_cdgo_rspsta := 0;

        --VERIFICAMOS QUE LAS CONTRASEÑAS SEAN IGUALES.
        if (p_password != p_password_re) then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Las contraseñas no coinciden.';
            return;
        end if;

        --VERIFICAMOS QUE EL PORTAL DEL TERCERO NO HA SIDO PROCESADO
        begin
            select *
              into v_tp
              from si_c_terceros_portal a
             where a.id_trcro_prtal = p_id_trcro_prtal
               and a.indcdor_prcsdo = 'N';
        exception
            when others then
                o_cdgo_rspsta   := 2;
                o_mnsje_rspsta  := 'No se encontraron datos del tercero.';
                return;
        end;

        --VERIFICAMOS SI EL TERCERO EXISTE
        begin
            select id_trcro
              into v_id_trcro
              from si_c_terceros 
             where cdgo_clnte          = v_tp.cdgo_clnte
               and cdgo_idntfccion_tpo = v_tp.cdgo_idntfccion_tpo
               and idntfccion          = v_tp.idntfccion;
        exception
            when no_data_found then 
				-- Consultamos si el tercero existe solo con la identificacion 
				begin					
					select id_trcro
					  into v_id_trcro
					  from si_c_terceros 
					 where cdgo_clnte          = v_tp.cdgo_clnte					  
					   and idntfccion          = v_tp.idntfccion
					   and cdgo_idntfccion_tpo = 'X';

					-- Actualizamos el tercero con los datos actuales.
					begin
						update si_c_terceros
				           set cdgo_idntfccion_tpo = v_tp.cdgo_idntfccion_tpo , idntfccion  		 = v_tp.idntfccion 
							 , prmer_nmbre         = v_tp.prmer_nmbre         , sgndo_nmbre 		 = v_tp.sgndo_nmbre          , prmer_aplldo       = v_tp.prmer_aplldo
							 , sgndo_aplldo        = v_tp.sgndo_aplldo        , drccion     		 = v_tp.drccion              , id_pais            = v_tp.id_pais
							 , id_dprtmnto  	   = v_tp.id_dprtmnto         , id_mncpio            = v_tp.id_mncpio            , drccion_ntfccion   = v_tp.drccion_ntfccion
							 , id_pais_ntfccion    = v_tp.id_pais_ntfccion    , id_dprtmnto_ntfccion = v_tp.id_dprtmnto_ntfccion , id_mncpio_ntfccion = v_tp.id_mncpio_ntfccion
							 , email               = v_tp.email               , tlfno                = v_tp.tlfno                , gnro               = v_tp.gnro 
							 , ncnldad             = v_tp.ncnldad             , fcha_ncmnto          = v_tp.fcha_ncmnto          , id_pais_orgn       = v_tp.id_pais_orgn
							 , cllar               = v_tp.cllar 
						where id_trcro = v_id_trcro;
					exception
						when others then 
							o_cdgo_rspsta   := 6;
							o_mnsje_rspsta  := 'No se pudo actualizar el tercero. ' || v_tp.idntfccion;
							return;						
					end;
				exception 
					when no_data_found then
						--REGISTRAMOS LOS DATOS DEL TERCERO.
						begin
							insert into si_c_terceros( cdgo_clnte           , cdgo_idntfccion_tpo      , idntfccion 
													 , prmer_nmbre          , sgndo_nmbre              , prmer_aplldo 
													 , sgndo_aplldo         , drccion                  , id_pais 
													 , id_dprtmnto          , id_mncpio                , drccion_ntfccion 
													 , id_pais_ntfccion     , id_dprtmnto_ntfccion     , id_mncpio_ntfccion 
													 , email                , tlfno                    , gnro 
													 , ncnldad              , fcha_ncmnto              , id_pais_orgn
													 , cllar                , indcdor_cntrbynte        , indcdr_fncnrio )
											   values( v_tp.cdgo_clnte      , v_tp.cdgo_idntfccion_tpo , v_tp.idntfccion 
													 , v_tp.prmer_nmbre     , v_tp.sgndo_nmbre         , v_tp.prmer_aplldo 
													 , v_tp.sgndo_aplldo    , v_tp.drccion             , v_tp.id_pais 
													 , v_tp.id_dprtmnto     , v_tp.id_mncpio           , v_tp.drccion_ntfccion 
													 , v_tp.id_pais_ntfccion, v_tp.id_dprtmnto_ntfccion, v_tp.id_mncpio_ntfccion 
													 , v_tp.email           , v_tp.tlfno               , v_tp.gnro 
													 , v_tp.ncnldad         , v_tp.fcha_ncmnto         , v_tp.id_pais_orgn
													 , v_tp.cllar           , 'S'                      , 'N')
											 returning id_trcro 
												  into v_id_trcro;
						exception
							when others then
								o_cdgo_rspsta   := 3;
								o_mnsje_rspsta  := 'No se pudo registrar el tercero. ' || v_tp.idntfccion;
								return; 
						end;					
				end;

        end;
        --REGISTRAMOS LOS DATOS DEL USUARIO.
        begin
            v_password := pkg_sg_autenticacion.fnc_sg_hash(lower(v_tp.idntfccion), p_password);
            insert into sg_g_usuarios( user_name      , id_trcro       , actvo 
                                     , fcha_crcion    , admin          , admin_rnion 
                                     , password       , fcha_exprcion  )
                               values( v_tp.idntfccion, v_id_trcro     , 'S'
                                     , systimestamp   , 0              , 0 
                                     , v_password     , v_fcha_exprcion);
        exception
            when others then
                rollback;
                o_cdgo_rspsta   := 4;
                o_mnsje_rspsta  := 'No se pudo registrar el usuario. ' || sqlerrm;
                return; 
        end;

        begin
            update si_c_terceros_portal
               set indcdor_prcsdo = 'S'
             where id_trcro_prtal = p_id_trcro_prtal;             
        exception
            when others then
                rollback;
                o_cdgo_rspsta   := 5;
                o_mnsje_rspsta  := 'No se pudo actualizar el registro.';
                return; 
        end;
    end prc_rg_usuario;

    procedure prc_rg_restablecer( p_id_trcro        in  number
                                , p_password        in  varchar2
                                , p_password_re     in  varchar2 
                                , o_cdgo_rspsta     out number
                                , o_mnsje_rspsta    out varchar2)
    as
        v_password      varchar2(500);
        v_fcha_exprcion date        := sysdate + 365; 
        v_idntfccion    si_c_terceros.idntfccion%type; 

    begin
        o_cdgo_rspsta := 0;
        --1. VERIFICAMOS QUE LAS CONTRASEÑAS SEAN IGUALES.
        if (p_password != p_password_re) then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Las contraseñas no coinciden.';
            return;
        end if;

        --2. OBTENEMOS LOS DATOS DEL TERCERO
        begin
            select idntfccion
              into v_idntfccion
              from si_c_terceros a
             where a.id_trcro = p_id_trcro;
        exception
            when others then
                o_cdgo_rspsta   := 2;
                o_mnsje_rspsta  := 'No se encontraron datos del tercero.';
                return;
        end;

        --3. ACTUALIZAMOS LA CONTRASEÑA
        begin
            v_password := pkg_sg_autenticacion.fnc_sg_hash(lower(v_idntfccion), p_password);
            update sg_g_usuarios
               set password = v_password
             where id_trcro = p_id_trcro;
             --Invalidar Token
        exception
            when others then
                rollback;
                o_cdgo_rspsta   := 3;
                o_mnsje_rspsta  := 'No se pudo actualizar el usuario. ' || sqlerrm;
                return; 
        end;

    end prc_rg_restablecer;


    -- Procedimiento que registra un usuario portal
    procedure prc_rg_usuario_portal(
              p_cdgo_clnte				in number
            , p_cdgo_idntfccion_tpo		in varchar2
            , p_idntfccion				in varchar2
            , p_prmer_nmbre				in varchar2
            , p_sgndo_nmbre				in varchar2
            , p_prmer_aplldo			in varchar2
            , p_sgndo_aplldo			in varchar2
            , p_drccion					in varchar2
            , p_id_pais					in number	default null
            , p_id_dprtmnto				in number
            , p_id_mncpio				in number
            , p_drccion_ntfccion		in varchar2	default null
            , p_id_pais_ntfccion		in number	default null
            , p_id_dprtmnto_ntfccion	in number	default null
            , p_id_mncpio_ntfccion		in number	default null
            , p_email					in varchar2
            , p_tlfno					in varchar2			
            , p_gnro					in varchar2
            , p_ncnldad					in varchar2
            , p_fcha_ncmnto				in varchar2 default null
            , p_id_pais_orgn			in number	default null
            , p_cllar					in number
            , o_cdgo_rspsta				out number
            , o_mnsje_rspsta			out varchar2		
    )
    as
        v_idntfccion_tpo_i 	varchar2(100);
        v_email_i		   	varchar2(320);
        v_count				number;
        v_id_trcro_prtal	number;	
        v_id_pais			number;
        v_id_usrio          number;
        v_id_trcro          number;
    begin
        -- Respuesta Exitosa
        o_cdgo_rspsta := 0;

        -- Consultamos el Pais
        begin
        select id_pais
          into v_id_pais
          from df_s_departamentos
         where id_dprtmnto = p_id_dprtmnto;
        exception
            when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'Error al consultar el Pais';			
                return;
        end;
        -- Consultamos si existe intento de registro
        begin
            select lower(b.dscrpcion_idntfccion_tpo)			 
                 , a.email
              into v_idntfccion_tpo_i			 
                 , v_email_i 
              from si_c_terceros_portal       a
              join df_s_identificaciones_tipo b on a.cdgo_idntfccion_tpo = b.cdgo_idntfccion_tpo
             where a.cdgo_clnte          = p_cdgo_clnte
               and a.cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo
               and a.idntfccion          = p_idntfccion
               and a.indcdor_prcsdo      = 'N';

                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'El usuario con '||v_idntfccion_tpo_i|| ' No. '|| p_idntfccion|| ' ya se encuentra en proceso de registro con cuenta de correo electronico '||v_email_i|| '.';			
                return;
        exception when 
            no_data_found then
                null;
        end;

        -- Consultamos si existe un tercero registrado
        begin
            select id_trcro
              into v_id_trcro
              from si_c_terceros
             where cdgo_clnte          = p_cdgo_clnte
               and cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo
               and idntfccion          = p_idntfccion; 

            -- Consultamos si el tercero tiene un usario asociado           
            begin
                select id_usrio
                  into v_id_usrio
                  from sg_g_usuarios
                 where id_trcro =  v_id_trcro;

                 -- Si encontramos usuario salimos de la Up y decimos que ya existe registrado que intente inciar sesion 
                o_cdgo_rspsta  := 20;
                o_mnsje_rspsta := 'Ya existe información registrada para esta identificación, por favor intente iniciar sesión en el portal ciudadano.';
                return;                 
            exception
                when no_data_found then 
                    -- Si no encontramos usuario creamos el registro 
                    insert into si_c_terceros_portal( cdgo_clnte       , cdgo_idntfccion_tpo  , idntfccion         , prmer_nmbre 
                                                    , sgndo_nmbre      , prmer_aplldo         , sgndo_aplldo       , drccion
                                                    , id_pais          , id_dprtmnto          , id_mncpio          , drccion_ntfccion
                                                    , id_pais_ntfccion , id_dprtmnto_ntfccion , id_mncpio_ntfccion , email
                                                    , tlfno            , gnro                 , ncnldad            , fcha_ncmnto
                                                    , id_pais_orgn     , cllar                ) 
                                              values( p_cdgo_clnte       , p_cdgo_idntfccion_tpo  , p_idntfccion         , p_prmer_nmbre 
                                                    , p_sgndo_nmbre      , p_prmer_aplldo         , p_sgndo_aplldo       , p_drccion
                                                    , v_id_pais          , p_id_dprtmnto          , p_id_mncpio          , p_drccion
                                                    , v_id_pais 		 , p_id_dprtmnto 		  , p_id_mncpio			 , p_email
                                                    , p_tlfno            , p_gnro                 , p_ncnldad            , p_fcha_ncmnto
                                                    , v_id_pais		     , p_cllar                ) 
                                            returning id_trcro_prtal 
                                                 into v_id_trcro_prtal;

                    commit;                 

            end;              

        exception
            when no_data_found then 
                -- Si no encontramos tercero creamos el registro
                insert into si_c_terceros_portal( cdgo_clnte       , cdgo_idntfccion_tpo  , idntfccion         , prmer_nmbre 
                                                , sgndo_nmbre      , prmer_aplldo         , sgndo_aplldo       , drccion
                                                , id_pais          , id_dprtmnto          , id_mncpio          , drccion_ntfccion
                                                , id_pais_ntfccion , id_dprtmnto_ntfccion , id_mncpio_ntfccion , email
                                                , tlfno            , gnro                 , ncnldad            , fcha_ncmnto
                                                , id_pais_orgn     , cllar                ) 
                                          values( p_cdgo_clnte       , p_cdgo_idntfccion_tpo  , p_idntfccion         , p_prmer_nmbre 
                                                , p_sgndo_nmbre      , p_prmer_aplldo         , p_sgndo_aplldo       , p_drccion
                                                , v_id_pais          , p_id_dprtmnto          , p_id_mncpio          , p_drccion
                                                , v_id_pais 		 , p_id_dprtmnto 		  , p_id_mncpio			 , p_email
                                                , p_tlfno            , p_gnro                 , p_ncnldad            , p_fcha_ncmnto
                                                , v_id_pais		     , p_cllar                ) 
                                        returning id_trcro_prtal 
                                             into v_id_trcro_prtal;

                commit;                 
        end;          

        --CONSULTAMOS SI HAY ENVIOS PROGRAMADOS
        pkg_ma_envios.prc_co_envio_programado( p_cdgo_clnte     => p_cdgo_clnte
                                             , p_idntfcdor      => 'SeguridadPortal.registro'
                                             , p_json_prmtros   => json_object( key 'p_id_trcro_prtal'  value  v_id_trcro_prtal )
                                             );

        o_mnsje_rspsta := 'Se ha enviado un correo a su dirección electrónica, para que Usted proceda con la activación de su usuario.';

    exception
        when others then
            o_cdgo_rspsta  := 30;
            o_mnsje_rspsta := 'No se pudo realizar el registro, por favor intente nuevamente.'||sqlerrm;
    end prc_rg_usuario_portal;

end pkg_pc_portal_ciudadano;

/
