-- ****************************************************************************
--	Author   : Rimom Costa
--	Date     : 01-09-2018
--	Version  : 1.0
--	Ticket   : mySQL_procedure_example-01
-- ****************************************************************************
USE db_magento;

SELECT @@hostname                       AS 'DEPLOYMENT SERVER';
SELECT DATABASE()                       AS 'DEPLOYMENT DB';
SELECT USER()                           AS 'DEPLOYER';
SELECT 'mySQL_procedure_example-01.sql' AS 'DEPLOYMENT FILE';
-- ***************************************************************************
DELIMITER //
DROP PROCEDURE IF EXISTS deleteTestVouchers;
//
USE db_magento//
CREATE PROCEDURE deleteTestVouchers()
  BEGIN

    START TRANSACTION;

    -- Table for logs
    CREATE TABLE IF NOT EXISTS Log (
      TableName        varchar(200),
      LogDate          datetime,
      RowCountAffected int,
      Description      varchar(1000)
    );

    -- Create a bkp of the Vouchers that will be deleted
    CREATE TABLE IF NOT EXISTS mage_voucher_list_backup_2018_09_01 AS
      SELECT
        entity_id,
        voucher,
        coalesce(dlu, '0000-00-00 00:00:00')              as dlu,
        customer_entity_id,
        sku_version,
        coalesce(creation_time, '0000-00-00 00:00:00')    as creation_time,
      FROM mage_voucher_list AS ps
      WHERE voucher in (
        '012345670',
        '012345671',
        '012345672',
        '012345673',
        '012345674',
        '012345675',
        '012345676',
        '012345677',
        '012345678',
        '012345679'
        );
    SET @cntr = @cntr + ROW_COUNT();

    -- Save row count of the table mage_voucher_list_backup_2018_10_01
    INSERT INTO Log (TableName, LogDate, RowCountAffected, Description)
      SELECT
        'mage_voucher_list_backup_2018_09_01' as TableName,
        now()                                 as LogDate,
        IFNULL(@cntr, 0),
        'LOG BACKED-UP'                       as Description;
    SET @cntr = 0;

    -- Begin of my main operation --------------------------------|

    -- Unregister the Vouchers from voucher table
    UPDATE mage_voucher_list as v
    SET
      v.customer_entity_id = 0
    WHERE voucher in (
        '012345670',
        '012345671',
        '012345672',
        '012345673',
        '012345674',
        '012345675',
        '012345676',
        '012345677',
        '012345678',
        '012345679'
        );
    SET @cntr = @cntr + ROW_COUNT();

    -- save row count of the table mage_voucher_list already modified
    INSERT INTO Log (TableName, LogDate, RowCountAffected, Description)
      SELECT
        'mage_voucher_list' as TableName,
        now()               as LogDate,
        IFNULL(@cntr, 0),
        'LOG DELETED'       as Description;
    SET @cntr = 0;

    COMMIT;

  END;
//
CALL deleteTestVouchers();
//
DROP PROCEDURE deleteTestVouchers;
//

-- rollback section, uncoment in case need it
-- USE db_magento;
-- START TRANSACTION;

-- UPDATE mage_voucher_list AS target
--    INNER JOIN mage_voucher_list_backup_2018_09_01 AS source
--      ON target.voucher = source.voucher
--  SET
--    target.customer_entity_id = source.customer_entity_id
--  WHERE source.voucher = target.voucher;

-- COMMIT;
