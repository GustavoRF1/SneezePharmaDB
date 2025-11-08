USE SneezePharma
GO

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
        FROM Medicine me
        JOIN inserted i ON me.CDB = i.CDB
        WHERE me.IDSituacao <> 1
    )
    BEGIN
        RAISERROR('O medicamento deve estar ativo', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    IF EXISTS (
        SELECT 1
        FROM SalesItems si
        JOIN inserted i ON si.IDVenda = i.IDVenda
        GROUP BY si.IDVenda
        HAVING COUNT(*) > 3
    )
    BEGIN
        RAISERROR('O limite máximo de venda é de 3 itens', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
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



CREATE TRIGGER trg_SalesItems_TotalItem
ON SalesItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE SalesItems

    SET
        TotalItem = inserted.Quantidade * Medicine.ValorVenda
    FROM SalesItems
    INNER JOIN inserted ON SalesItems.IDItemVenda = inserted.IDItemVenda
    INNER JOIN Medicine ON inserted.CDB = Medicine.CDB
END
GO

CREATE TRIGGER trg_SalesItems_Sales
ON SalesItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.ValorTotal = si.TotalPorVenda
    FROM Sales s
    INNER JOIN (
        SELECT IDVenda, SUM(TotalItem) AS TotalPorVenda
        FROM SalesItems
        GROUP BY IDVenda
    ) AS si ON s.IDVenda = si.IDVenda
    WHERE s.IDVenda IN (SELECT DISTINCT IDVenda FROM inserted);
END;
GO

CREATE TRIGGER trg_PurchaseItem_Purchases
ON PurchaseItem
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.ValorTotal = pui.TotalPorCompra
    FROM Purchases p
    INNER JOIN (
        SELECT IDCompra, SUM(TotalItem) AS TotalPorCompra
        FROM PurchaseItem
        GROUP BY IDCompra
    ) AS pui ON p.IDCompra = pui.IDCompra
    WHERE pui.IDCompra IN (SELECT DISTINCT IDCompra FROM inserted);
END;
GO

CREATE TRIGGER trg_PurchaseItem_Purchases
ON PurchaseItem
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Purchases
    SET ValorTotal = (
        SELECT SUM(ValorTotal)
        FROM PurchaseItem
        WHERE PurchaseItem.IDCompra = Purchases.IDCompra
        )
    WHERE IDCompra IN (SELECT DISTINCT IDCompra FROM inserted)
END
GO
