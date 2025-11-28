
CREATE DATABASE IF NOT EXISTS seijaku_pilates2 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE seijaku_pilates;

-- =============================================
-- TABLE 1: users
-- =============================================
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role ENUM('admin', 'member', 'instructor') DEFAULT 'member',
    status ENUM('active', 'inactive', 'blocked') DEFAULT 'active',
    profile_picture VARCHAR(255) DEFAULT 'default-avatar.png',
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other'),
    address TEXT,
    emergency_contact VARCHAR(20),
    
    -- Membership
    membership_type ENUM('3_months', '6_months', '12_months') DEFAULT '3_months',
    membership_start DATE,
    membership_end DATE,
    
    -- Preferences
    preferred_language ENUM('id', 'en') DEFAULT 'id',
    dark_mode BOOLEAN DEFAULT FALSE,
    email_notifications BOOLEAN DEFAULT TRUE,
    
    -- Tracking
    total_bookings INT DEFAULT 0,
    total_classes_attended INT DEFAULT 0,
    total_videos_watched INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_status (status),
    INDEX idx_membership_end (membership_end)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 2: instructors
-- =============================================
CREATE TABLE instructors (
    instructor_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE NOT NULL,
    specialization VARCHAR(255),
    bio TEXT,
    years_experience INT,
    certification TEXT,
    instagram VARCHAR(100),
    rating DECIMAL(3,2) DEFAULT 5.00,
    total_ratings INT DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================
-- TABLE 3: class_types
-- =============================================
CREATE TABLE class_types (
    class_type_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    description TEXT,
    description_en TEXT,
    icon VARCHAR(50),
    difficulty_level ENUM('beginner', 'intermediate', 'advanced', 'all') DEFAULT 'all',
    benefits TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_class_name (name)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 4: class_schedules
-- =============================================
CREATE TABLE class_schedules (
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    class_type_id INT NOT NULL,
    instructor_id INT NOT NULL,
    day_of_week ENUM('Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    duration_minutes INT NOT NULL,
    level ENUM('Beginner', 'Intermediate', 'Advanced') NOT NULL,
    capacity INT DEFAULT 5,
    price DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (class_type_id) REFERENCES class_types(class_type_id),
    FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id),
    
    INDEX idx_day (day_of_week),
    INDEX idx_time (start_time),
    INDEX idx_level (level),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 5: class_instances
-- =============================================
CREATE TABLE class_instances (
    instance_id INT PRIMARY KEY AUTO_INCREMENT,
    schedule_id INT NOT NULL,
    class_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    current_bookings INT DEFAULT 0,
    capacity INT NOT NULL,
    status ENUM('scheduled', 'ongoing', 'completed', 'cancelled') DEFAULT 'scheduled',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (schedule_id) REFERENCES class_schedules(schedule_id),
    
    INDEX idx_date (class_date),
    INDEX idx_status (status),
    UNIQUE KEY unique_schedule_date (schedule_id, class_date)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 6: bookings
-- =============================================
CREATE TABLE bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    instance_id INT NOT NULL,
    booking_status ENUM('pending', 'approved', 'rejected', 'cancelled', 'completed') DEFAULT 'pending',
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_by INT NULL,
    approved_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    cancellation_reason TEXT,
    notes TEXT,
    
    -- Attendance tracking
    checked_in BOOLEAN DEFAULT FALSE,
    check_in_time TIMESTAMP NULL,
    attended BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (instance_id) REFERENCES class_instances(instance_id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(user_id),
    
    INDEX idx_user (user_id),
    INDEX idx_status (booking_status),
    INDEX idx_date (booking_date),
    UNIQUE KEY unique_user_instance (user_id, instance_id)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 7: waiting_list (INNOVATIVE FEATURE)
-- =============================================
CREATE TABLE waiting_list (
    waiting_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    instance_id INT NOT NULL,
    position INT,
    status ENUM('waiting', 'notified', 'expired') DEFAULT 'waiting',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notified_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (instance_id) REFERENCES class_instances(instance_id) ON DELETE CASCADE,
    
    INDEX idx_status (status),
    UNIQUE KEY unique_user_waiting (user_id, instance_id)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 8: video_tutorials
-- =============================================
CREATE TABLE video_tutorials (
    video_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    title_en VARCHAR(255),
    description TEXT,
    description_en TEXT,
    video_file VARCHAR(255) NOT NULL,
    thumbnail VARCHAR(255),
    duration_minutes INT,
    class_type_id INT,
    level ENUM('Beginner', 'Intermediate', 'Advanced'),
    instructor_id INT,
    
    -- Engagement metrics
    view_count INT DEFAULT 0,
    like_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    
    -- Features
    has_subtitles BOOLEAN DEFAULT FALSE,
    has_chapters BOOLEAN DEFAULT FALSE,
    
    is_published BOOLEAN DEFAULT TRUE,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (class_type_id) REFERENCES class_types(class_type_id),
    FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id),
    
    INDEX idx_level (level),
    INDEX idx_published (is_published),
    FULLTEXT KEY ft_title_desc (title, description)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 9: video_interactions
-- =============================================
CREATE TABLE video_interactions (
    interaction_id INT PRIMARY KEY AUTO_INCREMENT,
    video_id INT NOT NULL,
    user_id INT NOT NULL,
    interaction_type ENUM('view', 'like', 'comment', 'bookmark') NOT NULL,
    comment_text TEXT,
    timestamp_seconds INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (video_id) REFERENCES video_tutorials(video_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    
    INDEX idx_video (video_id),
    INDEX idx_type (interaction_type)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 10: video_bookmarks (INNOVATIVE FEATURE)
-- =============================================
CREATE TABLE video_bookmarks (
    bookmark_id INT PRIMARY KEY AUTO_INCREMENT,
    video_id INT NOT NULL,
    user_id INT NOT NULL,
    timestamp_seconds INT NOT NULL,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (video_id) REFERENCES video_tutorials(video_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================
-- TABLE 11: achievements (GAMIFICATION)
-- =============================================
CREATE TABLE achievements (
    achievement_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    description TEXT,
    description_en TEXT,
    icon VARCHAR(50),
    points INT DEFAULT 0,
    category ENUM('classes', 'videos', 'consistency', 'social', 'milestone') DEFAULT 'classes',
    requirement_type ENUM('count', 'streak', 'special') DEFAULT 'count',
    requirement_value INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =============================================
-- TABLE 12: user_achievements (GAMIFICATION)
-- =============================================
CREATE TABLE user_achievements (
    user_achievement_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    achievement_id INT NOT NULL,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (achievement_id) REFERENCES achievements(achievement_id),
    
    UNIQUE KEY unique_user_achievement (user_id, achievement_id)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 13: notifications
-- =============================================
CREATE TABLE notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    type ENUM('booking_confirmed', 'booking_rejected', 'class_reminder', 
              'membership_expiring', 'achievement_earned', 'waiting_list', 
              'class_cancelled') NOT NULL,
    title VARCHAR(255),
    message TEXT,
    data JSON,
    is_read BOOLEAN DEFAULT FALSE,
    email_sent BOOLEAN DEFAULT FALSE,
    push_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    
    INDEX idx_user (user_id),
    INDEX idx_read (is_read),
    INDEX idx_type (type)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 14: reviews
-- =============================================
CREATE TABLE reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    booking_id INT NOT NULL,
    instructor_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    is_published BOOLEAN DEFAULT TRUE,
    admin_reply TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id),
    
    UNIQUE KEY unique_booking_review (booking_id)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 15: progress_tracking (INNOVATIVE)
-- =============================================
CREATE TABLE progress_tracking (
    progress_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    week_start DATE NOT NULL,
    classes_attended INT DEFAULT 0,
    videos_watched INT DEFAULT 0,
    total_minutes INT DEFAULT 0,
    calories_burned INT DEFAULT 0,
    achievement_points INT DEFAULT 0,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_user_week (user_id, week_start)
) ENGINE=InnoDB;

-- =============================================
-- TABLE 16: system_settings
-- =============================================
CREATE TABLE system_settings (
    setting_id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description VARCHAR(255),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =============================================
-- INSERT DEFAULT DATA
-- =============================================

-- Admin User (password: admin123)
INSERT INTO users (email, password_hash, full_name, phone, role, status, membership_end) VALUES
('admin@seijaku.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 
 'Admin Seijaku', '081234567890', 'admin', 'active', '2099-12-31');

-- Class Types
INSERT INTO class_types (name, name_en, description, description_en, icon, difficulty_level) VALUES
('Pilates Klasik', 'Classic Pilates', 'Metode tradisional yang terbukti efektif', 
 'Traditional proven effective method', '🌸', 'all'),
('Pilates Klinis', 'Clinical Pilates', 'Untuk rehabilitasi dan pemulihan', 
 'For rehabilitation and recovery', '⚕️', 'beginner'),
('Pilates Kontemporer', 'Contemporary Pilates', 'Metode modern yang inovatif', 
 'Modern innovative method', '✨', 'intermediate'),
('Mat Pilates', 'Mat Pilates', 'Latihan dengan matras', 
 'Exercise with mat', '🧘', 'beginner'),
('Pilates Reformer', 'Reformer Pilates', 'Menggunakan alat reformer', 
 'Using reformer equipment', '🏋️', 'intermediate'),
('Stott Pilates', 'Stott Pilates', 'Fokus pada postur anatomi', 
 'Focus on anatomical posture', '💫', 'advanced'),
('Pilates Winsor', 'Winsor Pilates', 'Untuk pembentukan tubuh', 
 'For body sculpting', '🌟', 'all');

-- Achievements (Gamification)
INSERT INTO achievements (name, name_en, description, description_en, icon, points, category, requirement_type, requirement_value) VALUES
('Pemula Sejati', 'True Beginner', 'Selesaikan kelas pertama Anda', 'Complete your first class', '🌱', 10, 'milestone', 'count', 1),
('Konsisten!', 'Consistent!', 'Hadiri 5 kelas dalam sebulan', 'Attend 5 classes in a month', '🔥', 25, 'consistency', 'count', 5),
('Atlet Pilates', 'Pilates Athlete', 'Selesaikan 10 kelas', 'Complete 10 classes', '🏆', 50, 'classes', 'count', 10),
('Pecinta Video', 'Video Lover', 'Tonton 10 video tutorial', 'Watch 10 tutorial videos', '📺', 20, 'videos', 'count', 10),
('Minggu Sempurna', 'Perfect Week', 'Hadiri kelas 3x dalam seminggu', 'Attend class 3x in a week', '⭐', 30, 'consistency', 'streak', 3),
('Master Pilates', 'Pilates Master', 'Selesaikan 50 kelas', 'Complete 50 classes', '👑', 100, 'milestone', 'count', 50),
('Early Bird', 'Early Bird', 'Booking 7 hari sebelumnya', 'Book 7 days in advance', '🌅', 15, 'special', 'special', 0),
('Influencer', 'Influencer', 'Bagikan 5 video di sosial media', 'Share 5 videos on social media', '💬', 20, 'social', 'count', 5);

-- System Settings
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('studio_name', 'Seijaku Pilates Studio', 'Nama studio'),
('studio_address', 'Purbalingga, Jawa Tengah', 'Alamat studio'),
('studio_phone', '081234567890', 'Nomor telepon'),
('studio_email', 'seijaku.pilates@gmail.com', 'Email kontak'),
('instagram', '@seijaku.pilates', 'Instagram handle'),
('operating_days', 'Jumat, Sabtu, Minggu', 'Hari operasional'),
('operating_hours', '08:00-10:00, 15:00-17:00, 19:00-21:00', 'Jam operasional'),
('booking_advance_days', '7', 'Maksimal booking ke depan (hari)'),
('cancel_hours_before', '2', 'Minimal cancel sebelum kelas (jam)'),
('max_daily_bookings', '1', 'Maksimal booking per hari per user'),
('auto_generate_classes', '1', 'Auto generate class instances'),
('email_notification_enabled', '1', 'Enable email notifications'),
('waiting_list_enabled', '1', 'Enable waiting list feature');

-- =============================================
-- STORED PROCEDURES
-- =============================================

DELIMITER //

-- Generate Class Instances for next 7 days
CREATE PROCEDURE sp_generate_class_instances()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_schedule_id INT;
    DECLARE v_day_of_week VARCHAR(20);
    DECLARE v_start_time TIME;
    DECLARE v_duration INT;
    DECLARE v_capacity INT;
    DECLARE v_date DATE;
    DECLARE cur CURSOR FOR 
        SELECT schedule_id, day_of_week, start_time, duration_minutes, capacity 
        FROM class_schedules 
        WHERE is_active = TRUE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_schedule_id, v_day_of_week, v_start_time, v_duration, v_capacity;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET v_date = CURDATE();
        WHILE v_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY) DO
            IF DAYNAME(v_date) = v_day_of_week THEN
                INSERT IGNORE INTO class_instances (schedule_id, class_date, start_time, end_time, capacity)
                VALUES (v_schedule_id, v_date, v_start_time, 
                        ADDTIME(v_start_time, SEC_TO_TIME(v_duration * 60)), v_capacity);
            END IF;
            SET v_date = DATE_ADD(v_date, INTERVAL 1 DAY);
        END WHILE;
    END LOOP;
    CLOSE cur;
END//

-- Check and Award Achievements
CREATE PROCEDURE sp_check_achievements(IN p_user_id INT)
BEGIN
    -- First Class Achievement
    IF (SELECT COUNT(*) FROM bookings WHERE user_id = p_user_id AND attended = TRUE) = 1 THEN
        INSERT IGNORE INTO user_achievements (user_id, achievement_id)
        SELECT p_user_id, achievement_id FROM achievements WHERE name = 'Pemula Sejati';
    END IF;
    
    -- 10 Classes Achievement
    IF (SELECT COUNT(*) FROM bookings WHERE user_id = p_user_id AND attended = TRUE) >= 10 THEN
        INSERT IGNORE INTO user_achievements (user_id, achievement_id)
        SELECT p_user_id, achievement_id FROM achievements WHERE name = 'Atlet Pilates';
    END IF;
    
    -- Add more achievement checks here
END//

DELIMITER ;

-- =============================================
-- TRIGGERS
-- =============================================

DELIMITER //

-- Update booking count when booking approved
CREATE TRIGGER trg_booking_approved
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF NEW.booking_status = 'approved' AND OLD.booking_status = 'pending' THEN
        UPDATE class_instances 
        SET current_bookings = current_bookings + 1
        WHERE instance_id = NEW.instance_id;
        
        UPDATE users 
        SET total_bookings = total_bookings + 1
        WHERE user_id = NEW.user_id;
        
        -- Send notification
        INSERT INTO notifications (user_id, type, title, message)
        VALUES (NEW.user_id, 'booking_confirmed', 
                'Booking Disetujui', 'Booking kelas Anda telah disetujui!');
    END IF;
    
    -- Handle cancellation
    IF NEW.booking_status = 'cancelled' AND OLD.booking_status = 'approved' THEN
        UPDATE class_instances 
        SET current_bookings = current_bookings - 1
        WHERE instance_id = NEW.instance_id;
        
        -- Check waiting list
        CALL sp_process_waiting_list(NEW.instance_id);
    END IF;
END//

-- Process waiting list when slot available
CREATE PROCEDURE sp_process_waiting_list(IN p_instance_id INT)
BEGIN
    DECLARE v_user_id INT;
    
    SELECT user_id INTO v_user_id
    FROM waiting_list
    WHERE instance_id = p_instance_id AND status = 'waiting'
    ORDER BY created_at LIMIT 1;
    
    IF v_user_id IS NOT NULL THEN
        INSERT INTO notifications (user_id, type, title, message)
        VALUES (v_user_id, 'waiting_list', 
                'Slot Tersedia!', 'Kelas yang Anda tunggu sekarang tersedia!');
        
        UPDATE waiting_list
        SET status = 'notified', notified_at = NOW()
        WHERE user_id = v_user_id AND instance_id = p_instance_id;
    END IF;
END//

DELIMITER ;

-- =============================================
-- VIEWS FOR REPORTING
-- =============================================

-- Active members view
CREATE VIEW v_active_members AS
SELECT 
    u.user_id,
    u.full_name,
    u.email,
    u.membership_type,
    u.membership_end,
    DATEDIFF(u.membership_end, CURDATE()) AS days_remaining,
    u.total_classes_attended,
    COUNT(DISTINCT ua.achievement_id) AS achievements_earned
FROM users u
LEFT JOIN user_achievements ua ON u.user_id = ua.user_id
WHERE u.role = 'member' AND u.status = 'active'
GROUP BY u.user_id;

-- Upcoming classes with availability
CREATE VIEW v_upcoming_classes AS
SELECT 
    ci.instance_id,
    ci.class_date,
    ci.start_time,
    ci.end_time,
    ct.name AS class_type,
    cs.level,
    u.full_name AS instructor_name,
    ci.capacity,
    ci.current_bookings,
    (ci.capacity - ci.current_bookings) AS available_slots
FROM class_instances ci
JOIN class_schedules cs ON ci.schedule_id = cs.schedule_id
JOIN class_types ct ON cs.class_type_id = ct.class_type_id
JOIN instructors i ON cs.instructor_id = i.instructor_id
JOIN users u ON i.user_id = u.user_id
WHERE ci.class_date >= CURDATE() AND ci.status = 'scheduled'
ORDER BY ci.class_date, ci.start_time;

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX idx_booking_user_status ON bookings(user_id, booking_status);
CREATE INDEX idx_class_date_status ON class_instances(class_date, status);
CREATE INDEX idx_notification_unread ON notifications(user_id, is_read);

-- =============================================
-- END OF SCHEMA
-- =============================================