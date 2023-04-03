GRANT USAGE ON *.* TO `java_middleware`@`localhost` IDENTIFIED BY PASSWORD '*EE66B92B5EDA940DD5156746E0696720F73FA193';

GRANT SELECT, EXECUTE ON `pisid`.* TO `java_middleware`@`localhost`;

GRANT EXECUTE ON PROCEDURE `pisid`.`writemov` TO `java_middleware`@`localhost`;

GRANT EXECUTE ON PROCEDURE `pisid`.`writetemp` TO `java_middleware`@`localhost`;

GRANT EXECUTE ON FUNCTION `pisid`.`getongoingexpid` TO `java_middleware`@`localhost`;

GRANT EXECUTE ON FUNCTION `pisid`.`ongoingexp` TO `java_middleware`@`localhost`;