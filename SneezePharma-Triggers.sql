CREATE TRIGGER trg_Sales_Insert
on Sales
INSTEAD OF INSERT
AS
BEGIN
IF EXISTS (SELECT 1 FROM RestrictedCustomers rc JOIN inserted i ON rc.IDCliente = i.IDCliente)
	BEGIN
		RAISERROR('Você não pode realizar a inserção de uma venda para um cliente restrito', 1,1)
	END
ELSE
	BEGIN
		INSERT INTO Sales (DataVenda, IDCliente, ValorTotal)
		SELECT DataVenda, IDCliente, ValorTotal FROM inserted
	END
END
GO

CREATE TRIGGER trg_SalesItem_Insert
ON SalesItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM SalesItems s
        JOIN inserted i ON s.IDVenda = i.IDVenda
        GROUP BY s.IDVenda
        HAVING COUNT(*) > 3
    )
    BEGIN
        IF EXISTS (SELECT 1 FROM Medicine me JOIN inserted i ON me.IDSituacao = 1)
            BEGIN
                INSERT SalesItems (CDB, Quantidade, ValorUnitario, TotalItem) SELECT CDB, Quantidade, ValorUnitario, TotalItem FROM inserted  
            END
        ELSE
            BEGIN
                RAISERROR('O medicamento deve ser ativo', 16, 1);
		        ROLLBACK TRANSACTION
		        RETURN
            END
    END
    ELSE
        BEGIN
            RAISERROR('O medicamento deve ser ativo', 16, 1);
		    ROLLBACK TRANSACTION
		    RETURN
        END
END;
GO

CREATE TRIGGER trg_Pucharse_Insert
on Purchases
INSTEAD OF INSERT
AS
IF EXISTS (SELECT 1 FROM RestrictedSuppliers rs JOIN inserted i ON rs.IDFornecedor = i.IDFornecedor)
	BEGIN
		RAISERROR('Você não pode realizar a inserção de uma venda para um cliente restrito', 1,1)
	END
ELSE
	BEGIN
		INSERT INTO Purchases(IDFornecedor, ValorTotal)
		SELECT IDFornecedor, ValorTotal FROM inserted
	END
GO

CREATE TRIGGER trg_PurchaseItem_Insert
ON PurchaseItem
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM Ingredients ing
        JOIN inserted i ON ing.IDIngrediente = i.IDIngrediente
        WHERE ing.IDSituacao <> 1
    )
    BEGIN
        RAISERROR('O ingrediente deve estar ativo', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    IF EXISTS (
        SELECT 1
        FROM PurchaseItem pui
        JOIN inserted i ON pui.IDCompra = i.IDCompra
        GROUP BY pui.IDCompra
        HAVING COUNT(*) > 3
    )
    BEGIN
        RAISERROR('O limite máximo de compra é de 3 itens', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

CREATE TRIGGER trg_Produce_Insert
ON Produce
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
IF EXISTS (SELECT 1 FROM Medicine me JOIN inserted i ON me.CDB = i.CDB AND me.IDSituacao = 1)
    BEGIN
        INSERT INTO Produce(CDB, Quantidade) SELECT CDB, Quantidade FROM inserted
    END
ELSE
    BEGIN
        RAISERROR('O medicamento deve estar ativo', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END
END
GO

CREATE TRIGGER trg_ProduceItem_Insert
ON ProduceItem
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
IF EXISTS (SELECT 1 FROM Ingredients ing JOIN inserted i ON ing.IDIngrediente = i.IDIngrediente AND ing.IDSituacao = 1)
    BEGIN
        INSERT INTO ProduceItem(IDProducao, IDIngrediente, QuantidadePrincipio) SELECT IDProducao, IDIngrediente, QuantidadePrincipio FROM inserted
    END
ELSE
    BEGIN
        RAISERROR('O ingrediente deve estar ativo', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END
END
GO