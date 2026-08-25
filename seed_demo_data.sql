-- Farmora Demo Seed Data
-- For Firestore import via Firebase Console or CLI

-- ============================================
-- MARKET PRICES (Dambulla & Manning Market)
-- ============================================
INSERT INTO market_prices (crop, emoji, price_per_kg, market, recorded_date) VALUES
('Tomato', '🍅', 95, 'Dambulla', CURRENT_DATE),
('Green Chilli', '🌶️', 220, 'Dambulla', CURRENT_DATE),
('Carrot', '🥕', 145, 'Dambulla', CURRENT_DATE),
('Leeks', '🥬', 180, 'Dambulla', CURRENT_DATE),
('Capsicum', '🫑', 260, 'Dambulla', CURRENT_DATE),
('Brinjal', '🍆', 75, 'Dambulla', CURRENT_DATE),
('Beans', '🫘', 130, 'Dambulla', CURRENT_DATE),
('Cabbage', '🥬', 60, 'Dambulla', CURRENT_DATE),
('Pumpkin', '🎃', 85, 'Dambulla', CURRENT_DATE),
('Bitter Gourd', '🥒', 120, 'Dambulla', CURRENT_DATE),
('Beetroot', '🟣', 100, 'Manning Market', CURRENT_DATE),
('Lettuce', '🥬', 90, 'Manning Market', CURRENT_DATE);

-- ============================================
-- FARMERS (10 accounts)
-- ============================================
INSERT INTO users (id, display_name, role, phone, location, is_onboarding_complete) VALUES
('farmer-001', 'Kamal Perera', 'farmer', '+94771234567', 'Nuwara Eliya', true),
('farmer-002', 'Nimal Silva', 'farmer', '+94772345678', 'Kandy', true),
('farmer-003', 'Sunil Fernando', 'farmer', '+94773456789', 'Badulla', true),
('farmer-004', 'Lakshmi Devi', 'farmer', '+94774567890', 'Jaffna', true),
('farmer-005', 'Ranjith Bandara', 'farmer', '+94775678901', 'Matale', true),
('farmer-006', 'Chaminda Wickramasinghe', 'farmer', '+94776789012', 'Gampaha', true),
('farmer-007', 'Priya Rajendran', 'farmer', '+94777890123', 'Kilinochchi', true),
('farmer-008', 'Mohamed Faisal', 'farmer', '+94778901234', 'Batticaloa', true),
('farmer-009', 'Dilshan Bandara', 'farmer', '+94779012345', 'Monaragala', true),
('farmer-010', 'Anjali Perera', 'farmer', '+94770123456', 'Ratnapura', true);

-- ============================================
-- BUYERS (3 accounts)
-- ============================================
INSERT INTO users (id, display_name, role, phone, location, is_onboarding_complete) VALUES
('buyer-001', 'Hotel Lanka', 'buyer', '+94112345678', 'Colombo', true),
('buyer-002', 'Fresh Mart Supermarket', 'buyer', '+94113456789', 'Kurunegala', true),
('buyer-003', 'City Supermarket', 'buyer', '+94114567890', 'Gampaha', true);

-- ============================================
-- PRODUCTS (20+ listings)
-- ============================================
INSERT INTO products (id, farmer_id, name, category, description, quantity_available, unit, price_minor, location, availability) VALUES
('prod-001', 'farmer-001', 'Organic Tomatoes', 'vegetables', 'Freshly picked organic tomatoes from Nuwara Eliya highlands', 200, 'kg', 420, 'Nuwara Eliya', 'available'),
('prod-002', 'farmer-001', 'Green Chilli', 'vegetables', 'Hot and fresh green chillies', 150, 'kg', 520, 'Nuwara Eliya', 'available'),
('prod-003', 'farmer-002', 'Fresh Carrots', 'vegetables', 'Sweet carrots from Kandy gardens', 300, 'kg', 340, 'Kandy', 'available'),
('prod-004', 'farmer-002', 'Cabbage Heads', 'vegetables', 'Crisp cabbage heads, perfect for cooking', 500, 'kg', 150, 'Kandy', 'available'),
('prod-005', 'farmer-003', 'Brinjal (Eggplant)', 'vegetables', 'Fresh brinjals from Badulla farms', 250, 'kg', 280, 'Badulla', 'available'),
('prod-006', 'farmer-003', 'Green Beans', 'vegetables', 'Tender green beans, hand-picked', 180, 'kg', 320, 'Badulla', 'available'),
('prod-007', 'farmer-004', 'Jaffna Brinjal', 'vegetables', 'Special Jaffna variety brinjal', 200, 'kg', 300, 'Jaffna', 'available'),
('prod-008', 'farmer-004', 'Drumstick', 'vegetables', 'Fresh drumstick pods', 100, 'kg', 250, 'Jaffna', 'limited'),
('prod-009', 'farmer-005', 'Curry Leaves', 'herbs', 'Fresh curry leaves, aromatic', 200, 'bunch', 40, 'Matale', 'available'),
('prod-010', 'farmer-005', 'Gotukola Bunches', 'herbs', 'Fresh gotukola for salads and juices', 300, 'bunch', 90, 'Matale', 'available'),
('prod-011', 'farmer-006', 'King Coconut', 'fruits', 'Fresh king coconuts, sweet water', 100, 'unit', 50, 'Gampaha', 'available'),
('prod-012', 'farmer-006', 'Cavendish Bananas', 'fruits', 'Ripe Cavendish bananas', 450, 'kg', 280, 'Gampaha', 'available'),
('prod-013', 'farmer-007', 'Pumpkin', 'vegetables', 'Large pumpkins for curries', 400, 'kg', 85, 'Kilinochchi', 'available'),
('prod-014', 'farmer-007', 'Bitter Gourd', 'vegetables', 'Fresh bitter gourds', 150, 'kg', 120, 'Kilinochchi', 'available'),
('prod-015', 'farmer-008', 'Capsicum', 'vegetables', 'Colorful capsicums (red, green)', 200, 'kg', 260, 'Batticaloa', 'available'),
('prod-016', 'farmer-008', 'Leeks', 'vegetables', 'Fresh leeks for cooking', 180, 'kg', 180, 'Batticaloa', 'available'),
('prod-017', 'farmer-009', 'Beetroot', 'vegetables', 'Fresh beetroot for juices and cooking', 250, 'kg', 100, 'Monaragala', 'available'),
('prod-018', 'farmer-009', 'Lettuce', 'vegetables', 'Crisp lettuce leaves for salads', 120, 'kg', 90, 'Monaragala', 'limited'),
('prod-019', 'farmer-010', 'Rambutan', 'fruits', 'Fresh rambutan in season', 80, 'kg', 600, 'Ratnapura', 'available'),
('prod-020', 'farmer-010', 'Mangosteen', 'fruits', 'Sweet mangosteens', 60, 'kg', 800, 'Ratnapura', 'limited');

-- ============================================
-- ORDERS (sample orders with status history)
-- ============================================
INSERT INTO orders (id, buyer_id, farmer_id, product_id, quantity, total_minor, status, delivery_address, created_at) VALUES
('ord-001', 'buyer-001', 'farmer-001', 'prod-001', 20, 8400, 'in_transit', 'Hotel Lanka, Galle Road, Colombo', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('ord-002', 'buyer-002', 'farmer-002', 'prod-003', 15, 5100, 'delivered', 'Fresh Mart, Kurunegala', CURRENT_TIMESTAMP - INTERVAL '3 days'),
('ord-003', 'buyer-003', 'farmer-003', 'prod-005', 10, 2800, 'pending', 'City Supermarket, Gampaha', CURRENT_TIMESTAMP),
('ord-004', 'buyer-001', 'farmer-005', 'prod-010', 50, 4500, 'confirmed', 'Hotel Lanka, Galle Road, Colombo', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('ord-005', 'buyer-002', 'farmer-006', 'prod-012', 25, 7000, 'delivered', 'Fresh Mart, Kurunegala', CURRENT_TIMESTAMP - INTERVAL '5 days');

-- ============================================
-- TRANSPORT JOBS (sample)
-- ============================================
INSERT INTO transport_jobs (id, farmer_id, title, origin, destination, weight_kg, pickup_time, fee_minor, status) VALUES
('job-001', 'farmer-001', 'Coconut harvest transport', 'Kaduwela', 'Colombo', 250, CURRENT_TIMESTAMP + INTERVAL '1 day', 3500, 'available'),
('job-002', 'farmer-002', 'Fresh vegetables delivery', 'Nuwara Eliya', 'Kandy', 80, CURRENT_TIMESTAMP + INTERVAL '2 days', 5200, 'available'),
('job-003', 'farmer-003', 'Brinjal shipment', 'Badulla', 'Colombo', 120, CURRENT_TIMESTAMP + INTERVAL '1 day', 4800, 'accepted');

-- ============================================
-- REVIEWS (sample)
-- ============================================
INSERT INTO reviews (id, reviewer_id, target_id, rating, comment, created_at) VALUES
('rev-001', 'buyer-001', 'farmer-001', 5, 'Excellent quality tomatoes! Will order again.', CURRENT_TIMESTAMP - INTERVAL '2 days'),
('rev-002', 'buyer-002', 'farmer-002', 4, 'Good carrots, fresh and sweet.', CURRENT_TIMESTAMP - INTERVAL '4 days'),
('rev-003', 'buyer-003', 'farmer-003', 4, 'Brinjal was fresh, delivery was on time.', CURRENT_TIMESTAMP - INTERVAL '1 week');
