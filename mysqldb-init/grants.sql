-- Initialize grants for the Drupal user.

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON drupal_docker.* TO 'drupal'@'localhost' IDENTIFIED BY 'drupal';