-- Script Opsional Seed Data Awal Huniya (Jalankan setelah server Go melakukan AutoMigrate)
-- Password untuk kedua akun di bawah adalah: password123 (Bcrypt hash)

INSERT INTO users (name, email, password_hash, phone, role, created_at, updated_at)
VALUES
  ('Budi Santoso (Owner)', 'owner@huniya.com', '$2a$10$7EqJtq98hPqEX7fNZaFWoOHi6M1T6r0/H2S8.y7N4N0mX/7p6V92K', '6281234567890', 'owner', NOW(), NOW()),
  ('Andi Pratama (User)', 'user@huniya.com', '$2a$10$7EqJtq98hPqEX7fNZaFWoOHi6M1T6r0/H2S8.y7N4N0mX/7p6V92K', '6289876543210', 'user', NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

INSERT INTO properties (owner_id, title, type, description, price_monthly, room_available, is_available, address, city, latitude, longitude, facilities, images, created_at, updated_at)
VALUES
  (1, 'Kos Eksklusif Melati Residence', 'kost_putri', 'Kos putri nyaman dekat stasiun dan kampus. Bebas banjir, akses 24 jam dengan kartu akses.', 1650000, 3, true, 'Jl. Kebon Sirih Raya No. 18, Menteng', 'Jakarta Pusat', -6.182800, 106.829200, '["WiFi", "AC", "K. Mandi Dalam", "Kasur", "CCTV 24 Jam"]', '[]', NOW(), NOW()),
  (1, 'Kos Putra Griya Mandiri', 'kost_putra', 'Kos putra strategis dekat perkantoran Sudirman-Thamrin. Termasuk listrik air standar.', 1350000, 2, true, 'Jl. K.H. Wahid Hasyim No. 45', 'Jakarta Pusat', -6.188500, 106.823500, '["WiFi", "Kasur", "Lemari", "Parkir Motor"]', '[]', NOW(), NOW()),
  (1, 'Kontrakan 2 Kamar Harmoni Asri', 'kontrakan', 'Kontrakan 2 kamar tidur, ruang tamu luas, dapur pribadi, dan carport mobil.', 3200000, 1, true, 'Jl. Tanah Abang II No. 12, Cideng', 'Jakarta Pusat', -6.171200, 106.814300, '["AC", "Parkir Mobil", "Dapur Bersama", "WiFi"]', '[]', NOW(), NOW());
