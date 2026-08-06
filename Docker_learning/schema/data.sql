INSERT INTO USERS (username, email, password_hash) VALUES
('john_doe', 'john.doe@example.com', '$2b$12$...' /* bcrypt hash of 'password123' */),
('jane_smith', 'jane.smith@example.com', '$2b$12$...' /* bcrypt hash of 'password123' */),
('alice_jones', 'alice.jones@example.com', '$2b$12$...' /* bcrypt hash of 'password123' */),
('bob_brown', 'bob.brown@example.com', '$2b$12$...' /* bcrypt hash of 'password123' */);
