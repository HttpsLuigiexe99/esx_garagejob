SET @job_name = 'import';
SET @society_name = 'society_import';
SET @job_Name_Caps = 'import';



INSERT INTO `addon_account` (name, label, shared) VALUES
  (@society_name, @job_Name_Caps, 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
  (@society_name, @job_Name_Caps, 1),
  ('society_import_fridge', 'import (frigo)', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES 
    (@society_name, @job_Name_Caps, 1)
;

INSERT INTO `jobs` (name, label, whitelisted) VALUES
  (@job_name, @job_Name_Caps, 1)
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
  (@job_name, 0, 'barman', 'Guardia Del Corpo', 300, '{}', '{}'),
  (@job_name, 1, 'dancer', 'Venditore', 300, '{}', '{}'),
  (@job_name, 2, 'viceboss', 'Venditore Esperto', 500, '{}', '{}'),
  (@job_name, 3, 'boss', 'DIrettore', 600, '{}', '{}')
;