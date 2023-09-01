
if exists(select name from sys.procedures where name = 'spct_cad_custodia') drop procedure spct_cad_custodia;
go

CREATE procedure [dbo].[spct_cad_custodia](  
  @dt_referencia smalldatetime
  )  
as  

begin try  
  
set ansi_warnings off
  
set nocount on  
  
declare @cd_carga int;
declare @caminho varchar(200);
declare @MySQL  varchar(max);

 select @caminho = vl_campo from dbo.tsv_server_status_9 where cd_campo = 3;

 DECLARE @nome_arquivo nvarchar(50) = convert(varchar(8), @dt_referencia, 112) + 'CAD_CUSTODIA.TXT';

--- Insere registro na tgr_carga - Inicio da Carga

   insert into dbo.tgr_cargas (cd_produto, dt_referencia, nm_arquivo, nm_package, dt_inicio, dt_termino, id_termino)  
	values(9, @dt_referencia, @nome_arquivo , 'spct_cad_custodia', getdate(), getdate(), 0)  
	select @cd_carga = @@IDENTITY;

 -- Apaga temporaria  dbo.ttp_cadastro_custodia

   truncate table dbo.ttp_cadastro_custodia

 -- 01. Inserindo Registros da dbo.ttp_linha_cadastro_custodia na tabela dbo.ttp_cadastro_custodia

   Insert into dbo.ttp_cadastro_custodia
   select SUBSTRING (dc_linha, 2, 14) as DC_PES,         -- DC_PES - Documento (CPF/CNPJ) da Pessoa/Empresa
   SUBSTRING (dc_linha, 16, 1) as TP_PES,                -- TP_PES - Tipo da Pessoa
   SUBSTRING (dc_linha, 17, 100) as NM_PES,              -- NM_PES - Nome da Pessoa/Empresa
   SUBSTRING (dc_linha, 117, 8) as CD_CEP,               -- CD_CEP - Código do CEP da Pessoa/Empresa
   SUBSTRING (dc_linha, 125, 50) as DS_LOG,              -- DS_LOG - Descrição do Logradouro da Pessoa/Empresa
   SUBSTRING (dc_linha, 175, 50) as DS_CPL,              -- DS_CPL - Descrição do complemento do Logradouro da Pessoa/Empresa
   SUBSTRING (dc_linha, 225, 50) as DS_BAI,              -- DS_BAI - Descrição do Bairro da Pessoa/Empresa
   SUBSTRING (dc_linha, 275, 50) as DS_LOC,              -- DS_LOC - Descrição da Localidade/Cidade da Pessoa/Empresa
   SUBSTRING (dc_linha, 325, 2) as DS_UFE,               -- DS_UFE - Sigla da UF da Pessoa/Empresa
   SUBSTRING (dc_linha, 327, 15) as NU_TEL,              -- NU_TEL - Número do Telefone da Pessoa/Empresa
   SUBSTRING (dc_linha, 342, 1) as nm_razaosocial,       -- TP_PEP - Indicativo de PEP – Pessoa Exposta Politicamente
   SUBSTRING (dc_linha, 343, 50) as DS_EMT,              -- DS_EMT - Empresa onde a Pessoa Trabalha
   CONVERT(datetime, convert(varchar(8), 
   SUBSTRING (dc_linha, 393, 8))) as DT_NAS,             -- DT_NAS - Data de Nascimento da Pessoa/Constituição da Empresa
   SUBSTRING (dc_linha, 401, 1) as CD_PRF,               -- CD_PRF - Código do Porte da Empresa na Receita Federal
   SUBSTRING (dc_linha, 402, 3) as CD_NJU,               -- CD_NJU - Código da Natureza Jurídica da Empresa
   SUBSTRING (dc_linha, 405, 4) as CD_RAT,               -- CD_RAT - Código do Ramo de Atividade da Empresa
   SUBSTRING (dc_linha, 409, 5) as CD_ETB,               -- CD_ETB - Código do Estabelecimento Comercial da Empresa
   SUBSTRING (dc_linha, 414, 4) as CD_ERA,               -- CD_ERA - Código do Ramo de Atividade do Estabelecimento Comercial da Empresa
   SUBSTRING (dc_linha, 418, 25) as DS_ETB,              -- DS_ETB - Descrição do Estabelecimento Comercial da Empresa
   CAST(CAST(SUBSTRING (dc_linha, 443, 14) 
   AS DECIMAL)/100 AS DECIMAL(14,2))as VL_FAT,           -- VL_FAT - Faturamento da Empresa
   CONVERT(datetime, convert(varchar(8),
   SUBSTRING (dc_linha, 459, 8))) as DT_CAD,             -- DT_CAD - Data de Cadastro da Pessoa/Empresa
   @cd_carga  as CD_Carga                                -- Código da Carga
   from dbo.ttp_linha_cadastro_custodia
   where left(dc_linha,1) = '2'

--- 02. Inserindo caso o DC_PES - Documento (CPF/CNPJ) da Pessoa/Empresa não exista

--- Inserindo Tabela definitiva

  Insert into dbo.tct_cadastro_custodia (DC_PES,               -- Documento (CPF/CNPJ) da Pessoa/Empresa
                                         TP_PES,               -- Tipo Pessoa
                                         NM_PES,               -- Nome da Pessoa/Empresa
                                         CD_CEP,               -- Código do CEP da Pessoa/Empresa
                                         DS_LOG,               -- Descrição do Logradouro Pessoa/Empresa
                                         DS_CPL,               -- Descrição do complemento Logradouro Pessoa/Empresa
                                         DS_BAI,               -- Descrição do Bairro da Pessoa/Empresa
                                         DS_LOC,               -- Descrição da Localidade/Cidade da Pessoa/Empresa
                                         DS_UFE,               -- Sigla da UF da Pessoa/Empresa
                                         NU_TEL,               -- Valor Contratado
                                         TP_PEP,               -- Indicativo de PEP – Pessoa Exposta Politicamente
                                         DS_EMT,               -- Empresa onde a Pessoa Trabalha
                                         DT_NAS,               -- Data de Nascimento da Pessoa/Constituição da Empresa
                                         CD_PRF,               -- Código do Porte da Empresa na Receita Federal
                                         CD_NJU,               -- Código da Natureza Jurídica da Empresa
                                         CD_RAT,               -- Código do Ramo de Atividade da Empresa
                                         CD_ETB,               -- Código do Estabelecimento Comercial da Empresa
                                         CD_ERA,               -- Código do Ramo de Atividade do Estabelecimento Comercial da Empresa
                                         DS_ETB,               -- Descrição do Estabelecimento Comercial da Empresa 
                                         VL_FAT,               -- Faturamento da Empresa 
                                         DT_CAD,               -- Data de Cadastro da Pessoa/Empresa
                                         cd_carga,             -- Codigo Carga
                                         dt_cadastro,          -- Data de Cadastro do Registro
                                         dt_atualizacao)       -- Data de Cadastro do Registro              
									
	select   ori.DC_PES,               -- Documento (CPF/CNPJ) da Pessoa/Empresa
            ori.TP_PES,               -- Tipo Pessoa
            ori.NM_PES,               -- Nome da Pessoa/Empresa
            ori.CD_CEP,               -- Código do CEP da Pessoa/Empresa
            ori.DS_LOG,               -- Descrição do Logradouro Pessoa/Empresa
            ori.DS_CPL,               -- Descrição do complemento Logradouro Pessoa/Empresa
            ori.DS_BAI,               -- Descrição do Bairro da Pessoa/Empresa
            ori.DS_LOC,               -- Descrição da Localidade/Cidade da Pessoa/Empresa
            ori.DS_UFE,               -- Sigla da UF da Pessoa/Empresa
            ori.NU_TEL,               -- Número do Telefone da Pessoa/Empresa
            ori.TP_PEP,               -- Indicativo de PEP – Pessoa Exposta Politicamente
            ori.DS_EMT,               -- Empresa onde a Pessoa Trabalha
            ori.DT_NAS,               -- Data de Nascimento da Pessoa/Constituição da Empresa
            ori.CD_PRF,               -- Código do Porte da Empresa na Receita Federal
            ori.CD_NJU,               -- Código da Natureza Jurídica da Empresa
            ori.CD_RAT,               -- Código do Ramo de Atividade da Empresa
            ori.CD_ETB,               -- Código do Estabelecimento Comercial da Empresa
            ori.CD_ERA,               -- Código do Ramo de Atividade do Estabelecimento Comercial da Empresa
            ori.DS_ETB,               -- Descrição do Estabelecimento Comercial da Empresa 
            ori.VL_FAT,               -- Faturamento da Empresa 
            ori.DT_CAD,               -- Data de Cadastro da Pessoa/Empresa
            ori.cd_carga,             -- Codigo Carga
            getdate(),
            getdate()
	from  ttp_cadastro_custodia ori
    left join dbo.tct_cadastro_custodia des on ori.DC_PES = des.DC_PES
	where  des.DC_PES is null

---- Atualiza informações de Cadastro de CPF/CNPJ

update  des
	set	des.NM_PES	= ori.NM_PES,         -- Nome da Pessoa/Empresa
			des.CD_CEP  = ori.CD_CEP,         -- Código do CEP da Pessoa/Empresa
			des.DS_LOG  = ori.DS_LOG,         -- Descrição do Logradouro Pessoa/Empresa
			des.DS_CPL  = ori.DS_CPL,         -- Descrição do complemento Logradouro Pessoa/Empresa
         des.DS_BAI  = ori.DS_BAI,  		 -- Descrição do Bairro da Pessoa/Empresa
         des.DS_LOC  = ori.DS_LOC,         -- Descrição da Localidade/Cidade da Pessoa/Empresa
         des.DS_UFE  = ori.DS_UFE,         -- Sigla da UF da Pessoa/Empresa
         des.NU_TEL  = ori.NU_TEL,         -- Número do Telefone da Pessoa/Empresa
         des.TP_PEP  = ori.TP_PEP,         -- Indicativo de PEP – Pessoa Exposta Politicamente
         des.DS_EMT  = ori.DS_EMT,         -- Empresa onde a Pessoa Trabalha
         des.DT_NAS =  ori.DT_NAS,         -- Data de Nascimento da Pessoa/Constituição da Empresa
         des.CD_PRF =  ori.CD_PRF,         -- Código do Porte da Empresa na Receita Federal
         des.CD_NJU =  ori.CD_NJU,         -- Código da Natureza Jurídica da Empresa
         des.CD_RAT =  ori.CD_RAT,         -- Código do Ramo de Atividade da Empresa
         des.CD_ETB =  ori.CD_ETB,         -- Código do Estabelecimento Comercial da Empresa
         des.CD_ERA =  ori.CD_ERA,         -- Código do Ramo de Atividade do Estabelecimento Comercial da Empresa
         des.DS_ETB =  ori.DS_ETB,         -- Descrição do Estabelecimento Comercial da Empresa 
         des.VL_FAT =  ori.VL_FAT,         -- Faturamento da Empresa 
         des.DT_CAD =  ori.DT_CAD,         -- Data de Cadastro da Pessoa/Empresa
         dt_atualizacao = getdate()
	from	dbo.tct_cadastro_custodia des
	join	dbo.ttp_cadastro_custodia ori on des.DC_PES = ori.DC_PES

--FIM CARGA TABELA GERAL
update dbo.tgr_cargas  set dt_termino = getdate(),  id_termino = 1  where cd_carga = @cd_carga;  

end try 
begin catch
	
--ERRO CARGA TABELA GERAL

exec dbo.spgr_tratar_erro;     

end catch
