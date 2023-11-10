USE [master]
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'GestaoFridgeUp')
BEGIN

CREATE DATABASE [GestaoFridgeUp]

END
GO

USE [GestaoFridgeUp]
GO

CREATE TABLE Utilizadores(
UtilizadorId INT IDENTITY (1,1) not null,
Nome nvarchar(100) not null,
Email nvarchar(100) not null,
Senha nvarchar(12) not null,
Morada nvarchar(500) not null,
Telefone nvarchar (9),

PRIMARY KEY (UtilizadorId),
UNIQUE (Email),
);
GO

CREATE TABLE CadeiaSupermercado(
CadeiaSupermercadoId INT IDENTITY (1,1) not null,
NomeCadeia nvarchar (60) not null,
URL nvarchar (500) not null,

PRIMARY KEY (CadeiaSupermercadoId),
UNIQUE (URL)
);
GO

Create table MarcaProdutos(
	MarcaId INT IDENTITY (1,1) NOT NULL,
	NomeMarca nvarchar(60) NOT NULL,

	Primary key (MarcaId)
)
GO

CREATE TABLE CategoriaProduto(
	CategoriaProdutoId INT IDENTITY (1,1) NOT NULL,
	NomeCategoria nvarchar(100) NOT NULL,
	Descricao nvarchar(150) NOT NULL,

	Primary Key (CategoriaProdutoId)
)
GO

CREATE TABLE Unidade(
	UnidadeId INT IDENTITY (1,1) NOT NULL,
	Descricao nvarchar(150) NOT NULL,
	UnidadeMedida char(2),

	Primary Key (UnidadeId)
)
GO

CREATE TABLE TipoArmazem(
	TipoArmazemId INT IDENTITY (1,1) NOT NULL,
	Descricao nvarchar(150) NOT NULL,

	Primary Key (TipoArmazemId)
)
GO

Create table Armazem(
	ArmazemId INT IDENTITY (1,1) NOT NULL,
	TipoArmazemId INT NOT NULL,
	Descricao nvarchar(60) NOT NULL,

	Primary key (ArmazemId),
	Foreign Key (TipoArmazemId) references TipoArmazem(TipoArmazemId)
)
GO

CREATE TABLE Lojas(
LojasId INT IDENTITY (1,1),
CadeiaSupermercadoId INT not null,
NomeLoja nvarchar (10) not null,
Morada nvarchar(200) not null,
Telefone nvarchar(9),

PRIMARY KEY (LojasId),
FOREIGN KEY (CadeiaSupermercadoId) REFERENCES CadeiaSupermercado(CadeiaSupermercadoId)
);
GO

CREATE TABLE ListasCompras(
	ListasComprasId INT IDENTITY (1,1) NOT NULL,
	UtilizadorId INT NOT NULL,
	CadeiaSupermercadoId INT NOT NULL,
	NomeLista nvarchar(60) NOT NULL,
	DataCriacao datetime NOT NULL,

	Primary Key (ListasComprasId),
	Foreign Key (UtilizadorId) references Utilizadores(UtilizadorId),
	Foreign Key (CadeiaSupermercadoId) references CadeiaSupermercado(CadeiaSupermercadoId)
)
GO

Create table Produtos(
	ProdutosId INT IDENTITY (1,1) NOT NULL,
	MarcaId INT NOT NULL,
	UnidadeId INT NOT NULL,
	CategoriaProdutoId INT NOT NULL,
	NomeProduto nvarchar (60) NOT NULL,
	Descricao nvarchar (100) NOT NULL,
	Promocao BIT 

	Primary key (ProdutosId),
	Foreign key(MarcaId) references MarcaProdutos(MarcaId),
	Foreign key(UnidadeId) references Unidade(UnidadeId),
	Foreign key(CategoriaProdutoId) references CategoriaProduto(CategoriaProdutoId),
)
GO

Create table Stock(
	StockId INT IDENTITY (1,1) NOT NULL,
	ArmazemId INT NOT NULL,
	ProdutosId INT NOT NULL,
	Quantidade int,
	QuantidadeMinima int,
	QuantidadeMaxima int,

	Primary key (StockId),
	Foreign Key (ArmazemId) references Armazem(ArmazemId),
	Foreign Key (ProdutosId) references Produtos(ProdutosId)
)
GO

Create table Alertas(
	AlertaId INT IDENTITY (1,1) NOT NULL,
	StockId INT NOT NULL,
	Descricao nvarchar(150) NOT NULL,
	DataAlerta datetime NOT NULL,
	Visto bit,

	Primary key (AlertaId),
	Foreign Key (StockId) references Stock(StockId)
)
GO

CREATE TABLE Precos(
CadeiaSupermercadoId INT not null,
ProdutosId INT not null,
Preco decimal(10, 2) NOT NULL,
DataEmissaoPreco datetime NOT NULL default GetDate(),

FOREIGN KEY (CadeiaSupermercadoId) REFERENCES CadeiaSupermercado(CadeiaSupermercadoId),
FOREIGN KEY (ProdutosId) REFERENCES Produtos(ProdutosId)
);
GO

Create table ListaComprasProdutos(
	ListasComprasId  INT NOT NULL,
	ProdutosId INT NOT NULL,
	NomeProduto nvarchar (60) NOT NULL,
	Preco decimal(10, 2) NOT NULL,
	Quantidade INT NOT NULL,

	Foreign key(ListasComprasId) references ListasCompras(ListasComprasId),
	Foreign key(ProdutosId) references Produtos(ProdutosId)
)
GO

-- CONSTRAINT´s --

-- Garantir que uma Loja esteja associada a uma Cadeia de Supermercados na tabela "Lojas":
ALTER TABLE Lojas
ADD CONSTRAINT FK_Lojas_CadeiaSupermercado
FOREIGN KEY (CadeiaSupermercadoId) REFERENCES CadeiaSupermercado(CadeiaSupermercadoId);
GO

-- Restringir a tabela "Produtos" para que o preço seja sempre maior que zero:
ALTER TABLE Precos
ADD CONSTRAINT CHK_Preco CHECK (Preco > 0);
GO

-- VIEW´s --

-- Criar uma view para obter todas as informações dos produtos, incluindo o nome da marca, preco e a descrição da categoria:
CREATE OR ALTER VIEW VW_InformacoesProdutos 
AS
SELECT P.ProdutosId, P.NomeProduto, M.NomeMarca, PR.Preco, C.Descricao AS CategoriaDescricao
FROM Produtos P
JOIN MarcaProdutos M ON P.MarcaId = M.MarcaId
JOIN CategoriaProduto C ON P.CategoriaProdutoId = C.CategoriaProdutoId
JOIN Precos PR ON PR.ProdutosId = P.ProdutosId;
GO

-- View para todos os produtos que estão no limite de stock (incompleta)--
--CREATE OR ALTER VIEW VW_ListaStockLimiteUtilizador
--AS
--SELECT lc.ListasComprasId, lc.NomeLista, lc.DataCriacao, cs.NomeCadeia AS SupermarketChain
--FROM Armazem
--JOIN CadeiaSupermercado cs ON lc.CadeiaSupermercadoId = cs.CadeiaSupermercadoId
--WHERE i.Quantidade <= i.QuantidadeMinima
--Go

--Permite uma view de todos os Precos dos  produtos de diferentes supermercados--
CREATE OR ALTER VIEW VW_PrecoProdutos
AS
SELECT p.NomeProduto AS Nome_de_Produto, m.NomeMarca, cp.Descricao,
       c.NomeCadeia AS CadeiaSupermercados, pr.Preco
FROM Produtos as p
JOIN MarcaProdutos as m ON p.MarcaId = m.MarcaId
JOIN CategoriaProduto as cp ON p.CategoriaProdutoId = cp.CategoriaProdutoId
JOIN Precos as pr ON pr.ProdutosId = p.ProdutosId
JOIN CadeiaSupermercado c ON pr.CadeiaSupermercadoId = c.CadeiaSupermercadoId;
GO

--UMA VIEW PARA AS INFORMAÇôes de todas as Lojas de Supermercado--
CREATE OR ALTER VIEW VW_ListaLojaCadeiaSupermercados
AS
SELECT CadeiaSupermercadoId, NomeCadeia as ListaCadeiaSupermercados
FROM CadeiaSupermercado;
GO

SELECT*
FROM VW_ListaLojaCadeiaSupermercados
go
-- VIEW para todos os produtos de determinado supermercado--
CREATE OR ALTER PROCEDURE ListaSupermercados
    @NomeCadeia NVARCHAR(100)
AS
BEGIN
    SELECT P.NomeProduto AS NomeProduto, M.NomeMarca AS Marca, P.Descricao AS Descricao
    FROM Produtos P
    JOIN MarcaProdutos M ON P.MarcaId = M.MarcaId
    JOIN Precos PR ON P.ProdutosId = PR.ProdutosId
    JOIN CadeiaSupermercado C ON PR.CadeiaSupermercadoId = C.CadeiaSupermercadoId
    WHERE C.NomeCadeia = @NomeCadeia;
END;
GO

--Seletor para cada supermercado--
EXEC  ListaSupermercados @NomeCadeia = 'SuperMart';

-- Para ver produtos em promoção de determinada Cadeiasupermercado--
CREATE OR ALTER PROCEDURE ListaProdutosPromocoes
    @NomeCadeia NVARCHAR(100)
AS
BEGIN
    SELECT P.NomeProduto AS NomeProduto, M.NomeMarca AS Marca, P.Descricao AS Descricao
    FROM Produtos P
    JOIN MarcaProdutos M ON P.MarcaId = M.MarcaId
    JOIN Precos PR ON P.ProdutosId = PR.ProdutosId
    JOIN CadeiaSupermercado C ON PR.CadeiaSupermercadoId = C.CadeiaSupermercadoId
    WHERE C.NomeCadeia = (SELECT NomeCadeia FROM CadeiaSupermercado WHERE NomeCadeia = @NomeCadeia) AND P.Promocao = 1;
END;
GO

-- INDEX´s --
-- Index para Email de Utilizadores
CREATE INDEX IX_Utilizadores_Email ON Utilizadores (Email);

-- Index de Cadeia de Supermercados
CREATE INDEX IX_CadeiaSupermercado_NomeCadeia ON CadeiaSupermercado (NomeCadeia);

-- Index de atributos de Produto
CREATE INDEX IX_Produtos_MarcaId ON Produtos (MarcaId);
CREATE INDEX IX_Produtos_CategoriaProdutoId ON Produtos (CategoriaProdutoId);
CREATE INDEX IX_Produtos_Promocao ON Produtos (Promocao);

-- Index de Produtos em stock
CREATE INDEX IX_Stock_ProdutosId ON Stock (ProdutosId);

-- Index de Precos sobre Produtos
CREATE INDEX IX_Precos_ProdutosId ON Precos (ProdutosId);

-- Criar um índice na coluna "NomeLoja" na tabela "Lojas" para melhorar o desempenho de consultas que envolvam essa coluna:
CREATE INDEX IDX_Lojas_NomeLoja ON Lojas (NomeLoja);
GO

-- TRIGGER´s --

-- Criar um Trigger que atualize automaticamente a coluna "Preco" na tabela "ListaComprasProdutos" sempre que um novo preço for atualizado:
CREATE TRIGGER TG_UpdatePrecos
ON Precos
AFTER UPDATE
AS
BEGIN
    UPDATE ListaComprasProdutos
    SET Preco = i.Preco
    FROM inserted i
    INNER JOIN ListasCompras lc ON lc.CadeiaSupermercadoId = i.CadeiaSupermercadoId
    WHERE ListaComprasProdutos.ProdutosId = i.ProdutosId
END;
GO

-- Criar um Trigger na tabela "Alertas" para verificar se a quantidade de um produto na tabela "Stock" atingiu a quantidade mínima e, em caso afirmativo, 
-- inserir um novo alerta na tabela "Alertas":
-- O trigger TR_Alertas_QuantidadeMinima será disparado após uma atualização na tabela "Stock", verificando se a coluna "Quantidade" foi atualizada. 
-- Se a quantidade atualizada for menor ou igual à quantidade mínima definida na tabela "Stock" para o produto específico, um novo alerta será inserido na tabela 
-- "Alertas" com a descrição "Quantidade mínima atingida para o produto na tabela Stock", a data e hora atuais e o campo "Visto" definido como 0.
CREATE TRIGGER TG_Stock_MinimumQuantity_Alert
ON Stock
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
	-- Verificar se a quantidade de algum produto atualizado é < ou = à quantidade mínima
    IF EXISTS (
        SELECT *
        FROM inserted i
        JOIN deleted d ON i.StockId = d.StockId
        WHERE i.Quantidade <= i.QuantidadeMinima
         -- AND d.Quantidade > d.QuantidadeMinima
    )
    BEGIN
	    -- Inserir um novo registro de alerta na tabela "Alertas"
        INSERT INTO Alertas (StockId, Descricao, DataAlerta, Visto)
        SELECT i.StockId, 'Stock quantity reached minimum level', GETDATE(), 0
        FROM inserted i
    END
END
GO

-- INSERT NAS TABELAS --
CREATE OR ALTER PROCEDURE InsertUtilizadores
	@Nome nvarchar(100),
	@Email nvarchar(100),
	@Senha nvarchar(12),
	@Morada nvarchar(500),
	@Telefone nvarchar(9)
AS BEGIN
	BEGIN TRY
		INSERT into Utilizadores(Nome, Email, Senha, Morada, Telefone)
		VALUES(@Nome, @Email, @Senha, @Morada, @Telefone);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertCadeiaSupermercado
	@NomeCadeia nvarchar(60),
	@URL nvarchar (500)
AS BEGIN
	BEGIN TRY
		INSERT into CadeiaSupermercado(NomeCadeia, URL)
		VALUES(@NomeCadeia, @URL);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertMarcaProdutos
	@NomeMarca nvarchar(60)
AS BEGIN
	BEGIN TRY
		INSERT into MarcaProdutos(NomeMarca)
		VALUES(@NomeMarca);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertCategoriaProduto
	@Descricao nvarchar(150)
AS BEGIN
	BEGIN TRY
		INSERT into CategoriaProduto(Descricao)
		VALUES(@Descricao);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertUnidade
	@Descricao nvarchar(150),
	@UnidadeMedida char(2)
AS BEGIN
	BEGIN TRY
		INSERT into Unidade(Descricao, UnidadeMedida)
		VALUES(@Descricao, @UnidadeMedida);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertTipoArmazem
	@Descricao nvarchar(150)
AS BEGIN
	BEGIN TRY
		INSERT into TipoArmazem(Descricao)
		VALUES(@Descricao);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertArmazem
	@TipoArmazemId INT,
	@Descricao nvarchar (150)
AS BEGIN
	BEGIN TRY
		INSERT into Armazem(TipoArmazemId, Descricao)
		VALUES (@TipoArmazemId, @Descricao);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertLojas
	@CadeiaSupermercadoId INT,
	@NomeLoja nvarchar(10),
	@Morada nvarchar(200),
	@Telefone nvarchar(9)
AS BEGIN
	BEGIN TRY
		INSERT into Lojas(CadeiaSupermercadoId, NomeLoja, Morada, Telefone)
		VALUES(@CadeiaSupermercadoId, @NomeLoja, @Morada, @Telefone);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertListasCompras
	@UtilizadorId INT,
	@CadeiaSupermercadosId INT,
	@NomeLista nvarchar(60),
	@DataCriacao datetime
AS BEGIN
	BEGIN TRY
		INSERT into ListasCompras(UtilizadorId, CadeiaSupermercadoId, NomeLista, DataCriacao)
		VALUES(@UtilizadorId, @CadeiaSupermercadosId, @NomeLista, @DataCriacao);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertProdutos
	@MarcaId INT,
	@UnidadeId INT,
	@CategoriaProdutoId INT,
	@NomeProduto nvarchar(60),
	@Descricao nvarchar(100),
	@Promocao BIT
AS BEGIN
	BEGIN TRY
		INSERT into Produtos(MarcaId, UnidadeId, CategoriaProdutoId, NomeProduto, Descricao,Promocao)
		VALUES(@MarcaId, @UnidadeId, @CategoriaProdutoId, @NomeProduto, @Descricao,@Promocao);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertStock
	@ArmazemId INT,
	@ProdutosId INT,
	@Quantidade int,
	@QuantidadeMinima int,
	@QuantidadeMaxima int
AS BEGIN
	BEGIN TRY
		INSERT into Stock(ArmazemId, ProdutosId, Quantidade, QuantidadeMinima, QuantidadeMaxima)
		VALUES(@ArmazemId, @ProdutosId, @Quantidade, @QuantidadeMinima, @QuantidadeMaxima);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertAlertas
	@StockId INT,
	@Descricao nvarchar(150),
	@DataAlerta datetime,
	@Visto bit
AS BEGIN
	BEGIN TRY
		INSERT into Alertas(StockId, Descricao, DataAlerta, Visto)
		VALUES(@StockId, @Descricao, @DataAlerta, @Visto);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertPrecos
	@CadeiaSupermercadoId INT,
	@ProdutosId INT,
	@Preco decimal(10, 2),
	@DataEmissaoPreco datetime
AS BEGIN
	BEGIN TRY
		INSERT into Precos(CadeiaSupermercadoId, ProdutosId, Preco, DataEmissaoPreco)
		VALUES(@CadeiaSupermercadoId, @ProdutosId, @Preco, @DataEmissaoPreco);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE InsertListasComprasProdutos
	@ListasComprasId INT,
	@ProdutosId INT,
	@Preco decimal(10, 2),
	@Quantidade int
AS BEGIN
	BEGIN TRY
		INSERT into ListaComprasProdutos(ListasComprasId, ProdutosId, Preco, Quantidade)
		VALUES(@ListasComprasId, @ProdutosId, @Preco, @Quantidade);
	END TRY
	BEGIN CATCH
		RAISERROR('Erro', 16, 1);
	END CATCH
END
GO

/* UPDATE DE TABELAS*/

/*UPDATE Utilizadores*/
CREATE OR ALTER PROCEDURE UpdateUtilizador
@UtilizadorId INT,
@Nome nvarchar(100),
@Email nvarchar(100),
@Senha nvarchar(12),
@Morada nvarchar(500),
@Telefone nvarchar(9)
AS
BEGIN
    BEGIN TRY
        UPDATE Utilizadores
        SET Nome = @Nome,
            Email = @Email,
            Senha = @Senha,
            Morada = @Morada,
            Telefone = @Telefone
        WHERE UtilizadorId = @UtilizadorId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/*UPDATE CadeiaSupermercado*/
CREATE OR ALTER PROCEDURE UpdateCadeiaSupermercado
@CadeiaSupermercadoId INT,
@NomeCadeia nvarchar(60),
@URL nvarchar(500)
AS
BEGIN
    BEGIN TRY
        UPDATE CadeiaSupermercado
        SET NomeCadeia = @NomeCadeia,
            URL = @URL
        WHERE CadeiaSupermercadoId = @CadeiaSupermercadoId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/*UPDATE MarcaProdutos*/ 
CREATE OR ALTER PROCEDURE UpdateMarcaProdutos
@MarcaId INT,
@NomeMarca nvarchar(60)
AS
BEGIN
    BEGIN TRY
        UPDATE MarcaProdutos
        SET NomeMarca = @NomeMarca
        WHERE MarcaId = @MarcaId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/*UPDATE CategoriaProduto*/
CREATE OR ALTER PROCEDURE UpdateCategoriaProduto
@CategoriaProdutoId INT,
@Descricao nvarchar(150)
AS
BEGIN
    BEGIN TRY
        UPDATE CategoriaProduto
        SET Descricao = @Descricao
        WHERE CategoriaProdutoId = @CategoriaProdutoId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/*UPDATE de unidades*/
CREATE OR ALTER PROCEDURE UpdateUnidade
@UnidadeId INT,
@Descricao nvarchar(150),
@UnidadeMedida char(2)
AS
BEGIN
    BEGIN TRY
        UPDATE Unidade
        SET Descricao = @Descricao,
            UnidadeMedida = @UnidadeMedida
        WHERE UnidadeId = @UnidadeId AND UnidadeMedida IN ('Kg', 'litros', 'Gramas');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/* UPDATE TIPO DE ARMAZEM*/
CREATE OR ALTER PROCEDURE UpdateTipoArmazem
@TipoArmazemId INT,
@Descricao nvarchar(150)
AS
BEGIN
    BEGIN TRY
        UPDATE TipoArmazem
        SET Descricao = @Descricao
        WHERE TipoArmazemId = @TipoArmazemId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/* UPDATE ARMAZEM*/
CREATE OR ALTER PROCEDURE UpdateArmazem
@ArmazemId INT,
@TipoArmazemId INT,
@Descricao nvarchar(60)
AS
BEGIN
    BEGIN TRY
        UPDATE Armazem
        SET TipoArmazemId = @TipoArmazemId,
            Descricao = @Descricao
        WHERE ArmazemId = @ArmazemId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/*UPDATE LOJAS*/
CREATE OR ALTER PROCEDURE UpdateLojas
@LojasId INT,
@CadeiaSupermercadoId INT,
@NomeLoja nvarchar(10),
@Morada nvarchar(200),
@Telefone nvarchar(9)
AS
BEGIN
    BEGIN TRY
        UPDATE Lojas
        SET CadeiaSupermercadoId = @CadeiaSupermercadoId,
            NomeLoja = @NomeLoja,
            Morada = @Morada,
            Telefone = @Telefone
        WHERE LojasId = @LojasId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/*UPdate Lista de Compras*/
CREATE OR ALTER PROCEDURE UpdateListasCompras
@ListasComprasId INT,
@UtilizadorId INT,
@CadeiaSupermercadoId INT,
@NomeLista nvarchar(60),
@DataCriacao datetime
AS
BEGIN
    BEGIN TRY
        UPDATE ListasCompras
        SET UtilizadorId = @UtilizadorId,
            CadeiaSupermercadoId = @CadeiaSupermercadoId,
            NomeLista = @NomeLista,
            DataCriacao = @DataCriacao
        WHERE ListasComprasId = @ListasComprasId;
		    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/*Update Produtos*/
CREATE OR ALTER PROCEDURE UpdateProdutos
	@ProdutosId INT,
	@MarcaId INT,
	@UnidadeId INT,
	@CategoriaProdutoId INT,
	@NomeProduto nvarchar(60),
	@Descricao nvarchar(100),
	@Promocao BIT
AS BEGIN
	BEGIN TRY
		UPDATE Produtos
		SET MarcaId = @MarcaId,
			UnidadeId = @UnidadeId,
			CategoriaProdutoId = @CategoriaProdutoId,
			NomeProduto = @NomeProduto,
			Descricao = @Descricao,
			Promocao = @Promocao
		WHERE ProdutosId = @ProdutosId;
			END TRY
		BEGIN CATCH
			THROW;
		END CATCH;
END;
GO

/*Update Stock*/
CREATE OR ALTER PROCEDURE UpdateStock
	@StockId INT,
	@ArmazemId INT,
	@ProdutosId INT,
	@Quantidade int,
	@QuantidadeMinima int,
	@QuantidadeMaxima int
AS BEGIN
	BEGIN TRY
		UPDATE Stock
		SET ArmazemId = @ArmazemId,
			ProdutosId = @ProdutosId,
			Quantidade = @Quantidade,
			QuantidadeMinima = @QuantidadeMinima,
			QuantidadeMaxima = @QuantidadeMaxima
		WHERE StockId = @StockId;
			END TRY
		BEGIN CATCH
			THROW;
		END CATCH;
END;
GO

/*Update Alertas*/
CREATE OR ALTER PROCEDURE UpdateAlertas
	@AlertaId INT,
	@StockId INT,
	@Descricao nvarchar(150),
	@DataAlerta datetime,
	@Visto bit
AS BEGIN
	BEGIN TRY
		UPDATE Alertas
		SET StockId = @StockId,
			Descricao = @Descricao,
			DataAlerta = @DataAlerta,
			Visto = @Visto
		WHERE AlertaId = @AlertaId;
			END TRY
		BEGIN CATCH
			THROW;
		END CATCH;
END;
GO

/*Update Preços*/
CREATE OR ALTER PROCEDURE UpdatePrecos
	@CadeiaSupermercadoId INT,
	@ProdutosId INT,
	@Preco decimal(10, 2),
	@DataEmissaoPreco datetime
AS BEGIN
	BEGIN TRY
		UPDATE Precos
		SET Preco = @Preco,
			DataEmissaoPreco = @DataEmissaoPreco
		WHERE CadeiaSupermercadoId = @CadeiaSupermercadoId and ProdutosId = @ProdutosId;
			END TRY
		BEGIN CATCH
			THROW;
		END CATCH;
END;
GO

/*Update Lista de Compras/Produtos*/
CREATE OR ALTER PROCEDURE UpdateListaComprasProdutos
	@ListasComprasId INT,
	@ProdutosId INT,
	@Preco decimal(10, 2),
	@Quantidade int
AS BEGIN
	BEGIN TRY
		UPDATE ListaComprasProdutos
		SET Preco = @Preco,
			Quantidade = @Quantidade
		WHERE ListasComprasId = @ListasComprasId and ProdutosId = @ProdutosId;
			END TRY
		BEGIN CATCH
			THROW;
		END CATCH;
END;
GO


--ELIMINAR ATRIBUTOS DAS TABELAS

--Eliminar From Utilizadores
CREATE or Alter PROCEDURE DeleteFromUtilizadores
    @UtilizadorId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Utilizadores
        WHERE UtilizadorId = @UtilizadorId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From CadeiaSupermercado
CREATE or Alter PROCEDURE DeleteFromCadeiaSupermercado
    @CadeiaSupermercadoId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM CadeiaSupermercado
        WHERE CadeiaSupermercadoId = @CadeiaSupermercadoId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From MarcaProdutos
CREATE or Alter PROCEDURE DeleteFromMarcaProdutos
    @MarcaId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM MarcaProdutos
        WHERE MarcaId = @MarcaId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From CategoriaProduto
CREATE or Alter PROCEDURE DeleteFromCategoriaProduto
    @CategoriaProdutoId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM CategoriaProduto
        WHERE CategoriaProdutoId = @CategoriaProdutoId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From Unidade
CREATE or Alter PROCEDURE DeleteFromUnidade
    @UnidadeId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Unidade
        WHERE UnidadeId = @UnidadeId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From TipoArmazem
CREATE or Alter PROCEDURE DeleteFromTipoArmazem
    @TipoArmazemId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM TipoArmazem
        WHERE TipoArmazemId = @TipoArmazemId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From Armazem
CREATE or Alter PROCEDURE DeleteFromArmazem
    @ArmazemId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Armazem
        WHERE ArmazemId = @ArmazemId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From Lojas
CREATE or Alter PROCEDURE DeleteFromLojas
    @LojasId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Lojas
        WHERE LojasId = @LojasId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From ListasCompras
CREATE or Alter PROCEDURE DeleteFromListasCompras
    @ListasComprasId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM ListasCompras
        WHERE ListasComprasId = @ListasComprasId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From Produtos
CREATE or Alter PROCEDURE DeleteFromProdutos
    @ProdutosId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Produtos
        WHERE ProdutosId = @ProdutosId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From Stock
CREATE or Alter PROCEDURE DeleteFromStock
    @StockId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Stock
        WHERE StockId = @StockId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From Alertas
CREATE or Alter PROCEDURE DeleteFromAlertas
    @AlertaId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Alertas
        WHERE AlertaId = @AlertaId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From Precos
CREATE or Alter PROCEDURE DeleteFromPrecos
    @CadeiaSupermercadoId INT, @ProdutosId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Precos
        WHERE CadeiaSupermercadoId = @CadeiaSupermercadoId and ProdutosId = @ProdutosId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

--Eliminar From ListaComprasProdutos
CREATE or Alter PROCEDURE DeleteFromListaComprasProdutos
    @ListasComprasId INT, @ProdutosId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM ListaComprasProdutos
        WHERE ListasComprasId = @ListasComprasId and ProdutosId = @ProdutosId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         RAISERROR('Error', 16, 1);
            ROLLBACK TRANSACTION;
        -- Tratar o erro conforme necessário
        THROW;
    END CATCH;
END;
GO

