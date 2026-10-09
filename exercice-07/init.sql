CREATE DATABASE IF NOT EXISTS kennelDB;
USE kennelDB;

CREATE TABLE clients (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nom VARCHAR(100) NOT NULL,
  prenom VARCHAR(100) NOT NULL,
  date_naissance DATE,
  pseudonyme VARCHAR(100)
);

CREATE TABLE adresses (
  id INT PRIMARY KEY AUTO_INCREMENT,
  numero VARCHAR(10) NOT NULL,
  rue VARCHAR(150) NOT NULL,
  code_postal VARCHAR(10) NOT NULL,
  commune VARCHAR(100) NOT NULL
);

CREATE TABLE clients_adresses (
  client_id INT NOT NULL,
  adresse_id INT NOT NULL,
  PRIMARY KEY (client_id, adresse_id),
  FOREIGN KEY (client_id) REFERENCES clients(id),
  FOREIGN KEY (adresse_id) REFERENCES adresses(id)
);

CREATE TABLE chiens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nom VARCHAR(100) NOT NULL,
  date_naissance DATE,
  race VARCHAR(100),
  sterilise BOOLEAN
);

CREATE TABLE chats (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nom VARCHAR(100) NOT NULL,
  date_naissance DATE,
  race VARCHAR(100),
  sterilise BOOLEAN
);

INSERT INTO clients (nom, prenom, date_naissance, pseudonyme) VALUES
  ('Gerardot', 'Enzo', '2004-09-05', 'enzo'),
  ('Test', 'TestPrenom', '1985-11-03', 'SIU');

INSERT INTO adresses (numero, rue, code_postal, commune) VALUES
  ('12', 'Rue des Lilas', '69001', 'Lyon'),
  ('4', 'Avenue Victor Hugo', '75016', 'Paris'),
  ('8', 'Rue du Port', '44000', 'Nantes');

INSERT INTO clients_adresses (client_id, adresse_id) VALUES
  (1, 1),
  (1, 3),
  (2, 2);

INSERT INTO chiens (nom, date_naissance, race, sterilise) VALUES
  ('Rex', '2018-06-01', 'Berger allemand', TRUE),
  ('Nala', '2020-02-14', 'Labrador', FALSE);

INSERT INTO chats (nom, date_naissance, race, sterilise) VALUES
  ('Minou', '2019-09-09', 'Europeen', TRUE),
  ('Pixel', '2021-01-20', 'Siamois', FALSE);
