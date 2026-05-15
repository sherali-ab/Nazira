CREATE TABLE IF NOT EXISTS users (
  telegram_id BIGINT UNSIGNED PRIMARY KEY COMMENT 'ID пользователя в MAX',
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  username VARCHAR(255),
  phone VARCHAR(20),
  email VARCHAR(255),
  max_profile_link VARCHAR(1024) NULL COMMENT 'Ссылка на профиль MAX из «Поделиться» (обязательна для оплаты/заявок)',
  preferred_contact ENUM('phone', 'email', 'telegram') DEFAULT 'telegram',
  query_type ENUM('consultation', 'question', 'other') DEFAULT 'other',
  consent_personal_data BOOLEAN DEFAULT FALSE,
  consent_offer BOOLEAN DEFAULT FALSE,
  consent_newsletter BOOLEAN DEFAULT FALSE,
  referred_by_user_id BIGINT UNSIGNED NULL,
  referral_10_eligible BOOLEAN DEFAULT FALSE,
  referral_10_used BOOLEAN DEFAULT FALSE,
  referral_30_eligible BOOLEAN DEFAULT FALSE,
  referral_30_used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  product_id VARCHAR(64) NOT NULL,
  amount INT UNSIGNED NOT NULL,
  status ENUM('pending', 'paid', 'cancelled') DEFAULT 'pending',
  paid_at TIMESTAMP NULL DEFAULT NULL,
  tochka_operation_id VARCHAR(128) NULL,
  tochka_payment_link_id CHAR(36) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_payments_tochka_operation (tochka_operation_id),
  FOREIGN KEY (user_id) REFERENCES users(telegram_id)
);

CREATE TABLE IF NOT EXISTS tochka_pending_checkouts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  product_id VARCHAR(64) NOT NULL,
  charge_amount INT UNSIGNED NOT NULL,
  payment_link_uuid CHAR(36) NOT NULL,
  referral_discount VARCHAR(8) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fulfilled_at TIMESTAMP NULL DEFAULT NULL,
  KEY idx_tochka_pending_link (payment_link_uuid, fulfilled_at),
  KEY idx_tochka_pending_user (user_id, fulfilled_at),
  FOREIGN KEY (user_id) REFERENCES users(telegram_id)
);

CREATE TABLE IF NOT EXISTS consultation_pay_preapprovals (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  product_id VARCHAR(64) NOT NULL,
  charge_amount INT UNSIGNED NOT NULL,
  referral_discount VARCHAR(8) NULL,
  status ENUM('awaiting_client', 'staff_pending', 'approved', 'rejected') NOT NULL DEFAULT 'awaiting_client',
  staff_notice_mid VARCHAR(191) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL DEFAULT NULL,
  KEY idx_cpp_user_status (user_id, status),
  FOREIGN KEY (user_id) REFERENCES users(telegram_id)
);

CREATE TABLE IF NOT EXISTS consultation_entitlements (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  payment_id INT UNSIGNED NOT NULL,
  product_id VARCHAR(50) NOT NULL,
  mode ENUM('credits', 'month_pass') NOT NULL,
  credits_remaining INT UNSIGNED NULL,
  pass_valid_until DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_entitlement_payment (payment_id),
  FOREIGN KEY (user_id) REFERENCES users(telegram_id),
  FOREIGN KEY (payment_id) REFERENCES payments(id)
);

CREATE TABLE IF NOT EXISTS consultations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  product_id VARCHAR(50) NULL,
  format ENUM('individual', 'family') NOT NULL,
  type ENUM('single', 'pack6', 'pack10', 'intro') NOT NULL,
  desired_date VARCHAR(50),
  desired_time VARCHAR(50),
  status ENUM('new', 'pending', 'approved', 'rejected', 'cancelled') DEFAULT 'new',
  entitlement_id INT UNSIGNED NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(telegram_id),
  FOREIGN KEY (entitlement_id) REFERENCES consultation_entitlements(id)
);

CREATE TABLE IF NOT EXISTS reviews (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  text TEXT NOT NULL,
  rating TINYINT UNSIGNED DEFAULT 5,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(telegram_id)
);

CREATE TABLE IF NOT EXISTS questions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  question TEXT NOT NULL,
  admin_notice_mid VARCHAR(191) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(telegram_id)
);

CREATE TABLE IF NOT EXISTS intro_sessions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  month_year VARCHAR(7) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(telegram_id)
);

CREATE TABLE IF NOT EXISTS monthly_digest_sent (
  user_id BIGINT UNSIGNED NOT NULL,
  month_period CHAR(7) NOT NULL,
  sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, month_period),
  FOREIGN KEY (user_id) REFERENCES users(telegram_id)
);

CREATE TABLE IF NOT EXISTS admin_main_menu_buttons (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sort_order INT NOT NULL DEFAULT 0,
  label VARCHAR(255) NOT NULL,
  action_type ENUM('callback', 'link') NOT NULL DEFAULT 'callback',
  callback_payload VARCHAR(128) NULL,
  url VARCHAR(1024) NULL,
  requires_paid_bookable TINYINT(1) NOT NULL DEFAULT 0,
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS admin_products (
  product_id VARCHAR(64) PRIMARY KEY,
  display_order INT NOT NULL DEFAULT 0,
  name VARCHAR(255) NOT NULL,
  button_caption VARCHAR(255) NOT NULL,
  amount INT UNSIGNED NOT NULL,
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS admin_text_snippets (
  snippet_key VARCHAR(64) PRIMARY KEY,
  body_html MEDIUMTEXT NOT NULL,
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warmup_config (
  id INT UNSIGNED PRIMARY KEY DEFAULT 1,
  scheduled_date DATE NULL,
  last_sent_at TIMESTAMP NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT IGNORE INTO warmup_config (id, scheduled_date) VALUES (1, NULL);
