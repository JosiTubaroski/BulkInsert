
/****** Object:  StoredProcedure [dbo].[spgr_carga_list_pep]    Script Date: 2023-09-01 15:34:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[spgr_carga_list_pep]
	@dt_carga smalldatetime  
as 

begin try

	--Variaveis
	declare @cd_carga     int;  	
	declare @dt_criacao   date;
	declare @qt_linhas    int;
	declare @nm_arquivo   varchar(250);
	declare @dt_inicio    datetime; 
	declare @dt_termino   datetime; 
	declare @strsql		  varchar(max);
	declare @dc_diretorio varchar(500);

	--Cria tabela temp
	create table #ttp_lista_pep(
		dc_nome				varchar(120) null,
		cd_cpf_cnpj			varchar(15)  null,
		dc_sigla_funcao_pep varchar(10)  null,
		dc_funcao_pep		varchar(100) null,
		cd_nivel_funcao_pep varchar(10)  null,
		nm_orgao_pep		varchar(100) null,
		dt_inicio_exercicio date		 null,
		dt_fim_exercicio	date		 null,
		dt_final_carencia	date		 null
	)	

	--Seta o nome do arquivo
	set @nm_arquivo = 'LISTAPEP' + upper(convert(varchar(8), @dt_carga,112)) + '.TXT';
	set	@dt_inicio  = getdate();
	set	@dt_termino = getdate();

	--Obtem o codigo da carga
	exec @cd_carga = dbo.spgr_obter_cd_carga  9, @dt_carga, @nm_arquivo, 'spgr_carga_list_pep', @dt_inicio, @dt_termino, 0;    
	
	--Obtem o diretório e o nome do arquivo 	
	select	@dc_diretorio = dc_diretorio 
	from	dbo.tgr_diretorio_carga
	where	dc_carga = 'PEP';

	--Limpa tabela temp 
	delete from dbo.ttp_list_pep;

set @strSql = 'bulk insert dbo.ttp_list_pep 
				   from ''' + @dc_diretorio + '''
				   with
				   ( 
					fieldterminator = '';'',
					rowterminator = ''\n'',
					codepage = ''ACP''
				   ) '

	exec (@strsql);

	insert into #ttp_lista_pep
	(
			dc_nome,
			cd_cpf_cnpj,
			dc_sigla_funcao_pep,
			dc_funcao_pep,
			cd_nivel_funcao_pep,
			nm_orgao_pep,
			dt_inicio_exercicio,
			dt_fim_exercicio,
			dt_final_carencia
	)
	select	upper(dc_nome) as dc_nome, 
			right('00000000000'  + cd_cpf_cnpj, 11) as cd_cpf_cnpj,
			upper(dc_sigla_funcao_pep) as dc_sigla_funcao_pep,
			upper(dc_funcao_pep) as dc_funcao_pep,
			cd_nivel_funcao_pep,
			upper(nm_orgao_pep) as nm_orgao_pep,
			cast(right(rtrim(ltrim(dt_inicio_exercicio)), 4) + substring(rtrim(ltrim(dt_inicio_exercicio)), 4, 2) + left(rtrim(ltrim(dt_inicio_exercicio)), 2) as date) as dt_inicio_exercicio,
			cast(right(replace(rtrim(ltrim(dt_fim_exercicio)), '---', ''), 4)    + substring(replace(rtrim(ltrim(dt_fim_exercicio)), '---', ''), 4, 2)  + left(replace(rtrim(ltrim(dt_fim_exercicio)), '---', ''), 2) as date) as dt_fim_exercicio,
			cast(right(replace(rtrim(ltrim(dt_final_carencia)), '---', ''), 4)    + substring(replace(rtrim(ltrim(dt_final_carencia)), '---', ''), 4, 2)  + left(replace(rtrim(ltrim(dt_final_carencia)), '---', ''), 2) as date) as dt_final_carencia
	from	dbo.ttp_list_pep 
	where	rtrim(ltrim(dc_nome)) <> 'Nome_PEP';

	insert into	dbo.tgr_list_pep
	(
			dc_nome, 
			cd_cpf_cnpj,
			dc_sigla_funcao_pep,
			dc_funcao_pep,
			cd_nivel_funcao_pep,
			nm_orgao_pep,
			dt_inicio_exercicio,
			dt_fim_exercicio,
			dt_final_carencia,
			cd_carga 
	)
	select	ori.dc_nome, 
			ori.cd_cpf_cnpj,
			ori.dc_sigla_funcao_pep,
			ori.dc_funcao_pep,
			ori.cd_nivel_funcao_pep,
			ori.nm_orgao_pep,
			ori.dt_inicio_exercicio,
			ori.dt_fim_exercicio,
			ori.dt_final_carencia,
			@cd_carga as cd_carga 
	from	#ttp_lista_pep ori
	left join dbo.tgr_list_pep des on ori.cd_cpf_cnpj = des.cd_cpf_cnpj
	and		ori.dt_inicio_exercicio = des.dt_inicio_exercicio
	and		ori.nm_orgao_pep = des.nm_orgao_pep
	and		ori.dc_sigla_funcao_pep = des.dc_sigla_funcao_pep
	and	    ori.dc_funcao_pep = des.dc_funcao_pep
	where	des.cd_pep is null;

	--Atualiza tabela de lista
	update des
	set	   des.dc_nome			   = ori.dc_nome,
		   des.dc_funcao_pep	   = ori.dc_funcao_pep,
		   des.cd_nivel_funcao_pep = ori.cd_nivel_funcao_pep,
		   des.dt_fim_exercicio    = ori.dt_fim_exercicio,
		   des.dt_final_carencia   = ori.dt_final_carencia,
		   des.id_status		   = 1,
		   des.dt_alteracao		   = getdate()
	from   dbo.tgr_list_pep des    
	join   #ttp_lista_pep   ori on des.cd_cpf_cnpj = ori.cd_cpf_cnpj
	and	   des.dt_inicio_exercicio = ori.dt_inicio_exercicio
	and	   des.nm_orgao_pep = ori.nm_orgao_pep
	and	   des.dc_funcao_pep = ori.dc_funcao_pep
	and	   des.dc_sigla_funcao_pep = des.dc_sigla_funcao_pep
	where (isnull(des.dc_nome, '')			   <> isnull(ori.dc_nome, '')
	or	   isnull(des.dc_funcao_pep, '')	   <> isnull(ori.dc_funcao_pep, '')
	or	   isnull(des.cd_nivel_funcao_pep, '') <> isnull(ori.cd_nivel_funcao_pep, '')
	or	   isnull(des.dt_fim_exercicio, '')    <> isnull(ori.dt_fim_exercicio, '')
	or	   isnull(des.dt_final_carencia, '')   <> isnull(ori.dt_final_carencia, ''));
	
	--Desabilita os nomes excluidos da lista
	update des
	set	   des.id_status = 0	
	from   dbo.tgr_list_pep  des    
	left join #ttp_lista_pep ori on des.cd_cpf_cnpj = ori.cd_cpf_cnpj
	and	   des.dt_inicio_exercicio = ori.dt_inicio_exercicio
	and	   des.nm_orgao_pep = ori.nm_orgao_pep
	and	   des.dc_sigla_funcao_pep = des.dc_sigla_funcao_pep
	and	   des.dc_funcao_pep = ori.dc_funcao_pep
	and    des.id_status = 1  
	where  ori.cd_cpf_cnpj is null;

	--Reativa membro caso o nome tenha sido excluido da lista
	update des
	set	   des.id_status = 1	
	from   dbo.tgr_list_pep  des    
	join   #ttp_lista_pep    ori on des.cd_cpf_cnpj = ori.cd_cpf_cnpj
	and	   des.dt_inicio_exercicio = ori.dt_inicio_exercicio
	and	   des.nm_orgao_pep = ori.nm_orgao_pep
	and	   des.dc_sigla_funcao_pep = des.dc_sigla_funcao_pep
	and	   des.dc_funcao_pep = ori.dc_funcao_pep
	where  des.id_status = 0;


	--Insere na tb generica.
	insert into dbo.twl_lista_membro
	(
			cd_tipo_lista,
			cd_lista,
			cd_membro,
			vl_string_1,
			vl_string_2,
			vl_string_3,
			vl_string_4,
			vl_string_5,
			vl_string_6,
			vl_date_1,
			vl_date_2,
			vl_date_3,
			dt_criacao,
			dt_alteracao,
			id_processar,
			id_status
	)
	select 	2						as cd_tipo_lista,
			2						as cd_lista,
			ori.cd_pep				as cd_membro,
			ori.dc_nome				as vl_string_1,
			ori.cd_cpf_cnpj			as vl_string_2,
			ori.dc_sigla_funcao_pep as vl_string_3,
			ori.dc_funcao_pep		as vl_string_4,
			ori.cd_nivel_funcao_pep as vl_string_5, 
			ori.nm_orgao_pep		as vl_string_6,
			ori.dt_inicio_exercicio as vl_date_1,
			case when ori.dt_fim_exercicio = '1900-01-01' then null else ori.dt_fim_exercicio end as vl_date_2,
			case when ori.dt_final_carencia = '1900-01-01' then null else ori.dt_final_carencia end as vl_date_3,
			getdate()				as dt_criacao,
			getdate()				as dt_alteracao,
			1 as id_processar,
			1 as id_status
	from dbo.tgr_list_pep ori 
	where not exists (select 1 from dbo.twl_lista_membro des 
					  where ori.cd_pep = des.cd_membro
					  and des.cd_lista = 2
					  and des.cd_tipo_lista = 2
					  )
	and ori.id_status = 1		
	



	-- Atualiza membros da lista  
	update des
    set	   des.vl_string_1  = upper(isnull(ori.dc_nome,'')),
		   des.vl_string_2  = ori.cd_cpf_cnpj,
		   des.vl_string_3  = ori.dc_sigla_funcao_pep,
		   des.vl_string_4  = ori.dc_funcao_pep,
		   des.vl_string_5  = ori.cd_nivel_funcao_pep,
		   des.vl_string_6  = ori.nm_orgao_pep, 
   		   des.vl_date_2    = ori.dt_fim_exercicio,
   		   des.vl_date_3    = ori.dt_final_carencia,
		   des.id_status	= 1,
		   des.dt_alteracao = case when isnull(des.vl_string_1, '') = isnull(ori.dc_nome, '') then des.dt_alteracao else getdate() end,
		   des.dt_exclusao	= null
	from   dbo.twl_lista_membro des 
	join   dbo.tgr_list_pep		ori on des.cd_tipo_lista = 2 
	and	   des.cd_lista     = 2 
	and	   des.cd_membro    =  ori.cd_pep
	and	   ori.id_status = 1
	where (isnull(des.vl_string_1, '')  <> isnull(ori.dc_nome,'')
	or	   isnull(des.vl_string_2, '')  <> isnull(ori.cd_cpf_cnpj, '')
	or	   isnull(des.vl_string_3, '')  <> isnull(ori.dc_sigla_funcao_pep, '')
	or	   isnull(des.vl_string_4, '')  <> isnull(ori.dc_funcao_pep, '')
	or	   isnull(des.vl_string_5, '')  <> isnull(ori.cd_nivel_funcao_pep, '')
	or	   isnull(des.vl_string_6, '')  <> isnull(ori.nm_orgao_pep, '') 
	or	   isnull(des.vl_date_2, '')    <> isnull(ori.dt_fim_exercicio, '') 
	or	   isnull(des.vl_date_3, '')    <> isnull(ori.dt_final_carencia, ''));	

	
	--Reativa membro caso o nome tenha sido excluido da lista
	update	des 
	set		des.id_processar = 1,
			des.id_status	 = 1,
			des.dt_exclusao  = null
	from	dbo.twl_lista_membro des
	join    dbo.tgr_list_pep     ori on des.cd_membro = ori.cd_pep
	and		des.cd_tipo_lista = 2 
	and		des.cd_lista	  = 2
	where	des.id_status	  = 0;
	  
	--Desabilita membro caso o nome tenha sido excluido da lista
	update des 
	set	   des.id_processar = 0,
		   des.id_status    = 0,
		   des.dt_exclusao  = @dt_criacao
	from   dbo.twl_lista_membro	des 
	left join dbo.tgr_list_pep  ori on des.cd_membro = ori.cd_pep
	and	 ori.id_status	 = 1
	where  
	   des.cd_tipo_lista = 2 and
	   des.cd_lista		 = 2 and
	   ori.cd_pep is null;

	--Dropa tabela temp
	drop table #ttp_lista_pep;

	--Atualiza registro na tabela de carga tgr_cargas    
	update dbo.tgr_cargas     
	set	   dt_termino = getdate(),     
		   id_termino = 1     
	where  cd_carga = @cd_carga;  


end try
begin catch

	exec dbo.spgr_tratar_erro;

end catch
