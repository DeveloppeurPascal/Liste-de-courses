-- Généré le : lun. 21 mars 2022 à 17:02
-- Version du serveur : 10.4.24-MariaDB
-- Version de PHP : 8.1.4

CREATE TABLE `courses` (
  `produit` varchar(50) NOT NULL,
  `quantite` int(11) NOT NULL DEFAULT 0
);

CREATE TABLE `modifs` (
  `sequence` int(10) UNSIGNED NOT NULL,
  `idclient` varchar(50) NOT NULL,
  `produit` varchar(50) NOT NULL,
  `quantite` int(11) NOT NULL DEFAULT 0
);

CREATE TABLE `clients` (
  `idclient` varchar(50) NOT NULL
);

ALTER TABLE `clients`
  ADD PRIMARY KEY (`idclient`);

ALTER TABLE `courses`
  ADD PRIMARY KEY (`produit`);

ALTER TABLE `modifs`
  ADD PRIMARY KEY (`sequence`);

ALTER TABLE `modifs`
  MODIFY `sequence` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;
COMMIT;
