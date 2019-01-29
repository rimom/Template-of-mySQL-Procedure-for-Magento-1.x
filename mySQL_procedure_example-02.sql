-- ****************************************************************************
--	Author   : Rimom Costa
--	Date     : 01-10-2018
--	Version  : 1.0
--	Ticket   : mySQL_procedure_example-02
-- ****************************************************************************
USE db_magento;

SELECT @@hostname AS 'DEPLOYMENT SERVER';
SELECT DATABASE() AS 'DEPLOYMENT DB';
SELECT USER() AS 'DEPLOYER';
SELECT 'mySQL_procedure_example-02.sql' AS 'DEPLOYMENT FILE';
-- ***************************************************************************
DELIMITER //
DROP PROCEDURE IF EXISTS doSetClassTaxId;
//
USE db_magento//
CREATE PROCEDURE doSetClassTaxId()
  BEGIN

    CREATE TABLE IF NOT EXISTS Log (
      TableName        varchar(200),
      LogDate          datetime,
      RowCountAffected int,
      Description      varchar(1000)
    );

    START TRANSACTION;

    -- 1-get attribute ID of 'tax_class_id'
    SET @attributeId = 0;
    SELECT @attributeId := attribute_id
    FROM mage_eav_attribute
    WHERE attribute_code = 'tax_class_id';

    -- create a bkp of the attributes that will be changed for all products
    SET @cntr = 0;
    CREATE TABLE if not exists mage_catalog_product_entity_int_backup_01_October_2018 AS
      SELECT ps.*
      FROM mage_catalog_product_entity_int AS ps
      WHERE attribute_id = @attributeId AND value != 0;
    SET @cntr = @cntr + ROW_COUNT();

    -- save row count of the table to be modified
    INSERT INTO Log (TableName, LogDate, RowCountAffected, Description)
      SELECT
        'mage_catalog_product_entity_int_backup_01_October_2018'  as TableName,
        now()                                                     as LogDate,
        IFNULL(@cntr, 0),
        'LOG BACKED-UP'                                           as Description;

    -- 3-apply the data changes
    SET @cntr = 0;
    UPDATE mage_catalog_product_entity_int
    SET value = 0
    WHERE attribute_id = @attributeId AND value != 0;
    SET @cntr = @cntr + ROW_COUNT();

    -- save row count of the table already modified
    INSERT INTO Log (TableName, LogDate, RowCountAffected, Description)
      SELECT
        'mage_catalog_product_entity_int' as TableName,
        now()                             as LogDate,
        IFNULL(@cntr, 0),
        'LOG MODIFIED'                    as Description;

    COMMIT;
  END;
//
CALL doSetClassTaxId();
//
DROP PROCEDURE doSetClassTaxId;
//

-- rollback section
# USE db_magento;
# START TRANSACTION;
#
#
# SELECT @attributeId := attribute_id
# FROM mage_eav_attribute
# WHERE attribute_code = 'tax_class_id';
#
# UPDATE mage_catalog_product_entity_int AS target
#   INNER JOIN mage_catalog_product_entity_int_backup_14_August_2018 AS source
#     ON target.value_id = source.value_id
# SET target.value = source.value
# WHERE source.value_id = target.value_id
#       AND target.attribute_id = @attributeId;
#
# COMMIT;
