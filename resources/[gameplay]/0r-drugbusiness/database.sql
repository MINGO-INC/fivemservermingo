CREATE TABLE
    IF NOT EXISTS `0r_drugbusiness_warehouses` (
        id INT AUTO_INCREMENT PRIMARY KEY,
        warehouse_index INT NOT NULL,
        name VARCHAR(64) NOT NULL,
        owner_id VARCHAR(255) NOT NULL,
        business_theme ENUM ('weed', 'cocaine', 'meth') NOT NULL DEFAULT 'weed',
        experience INT NOT NULL DEFAULT 0,
        managers MEDIUMTEXT NOT NULL DEFAULT '{}',
        meta MEDIUMTEXT NOT NULL DEFAULT '{}',
        water_stock INT NOT NULL DEFAULT 0,
        gas_stock INT NOT NULL DEFAULT 0,
        electricity_stock INT NOT NULL DEFAULT 0,
        packaged_product_stock INT NOT NULL DEFAULT 0,
        employee_count INT NOT NULL DEFAULT 0,
        raw_materials_stock INT NOT NULL DEFAULT 0,
        last_processed VARCHAR(50) NULL DEFAULT NULL,
        clean_money DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
        dirty_money DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (warehouse_index),
        UNIQUE (owner_id, warehouse_index)
    );

CREATE TABLE
    IF NOT EXISTS `0r_drugbusiness_warehouse_logs` (
        id INT AUTO_INCREMENT PRIMARY KEY,
        warehouse_id INT NOT NULL,
        log_message TEXT NOT NULL,
        log_type ENUM (
            'info',
            'warning',
            'error',
            'transaction',
            'security'
        ) NOT NULL DEFAULT 'info',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (warehouse_id) REFERENCES `0r_drugbusiness_warehouses` (id) ON DELETE CASCADE
    );