# Tests avancés - API PLATFORM CON 2022

Ce repository contient tous les exemples mentionnés pendant la conférenc "Tests avancés"
que j'ai eu l'occasion de produire pendant l'API Platform Con les 15 et 16 septembre 2022.


Tester une API distante sans l'appeler
-------------------------------------
Tout est très bien expliqué dans cet article écrit par Loïc qui a justement implémenté cela chez nous : 
https://www.strangebuzz.com/en/blog/simple-api-mocking-with-the-symfony-http-client


Réécrire une partie de la spec OpenAPI
--------------------------------------
Je suis en fait partie de cette documentation d'APIP, qui ajoute une authentification JWT dans la spec OpenAPI : https://api-platform.com/docs/core/jwt/


Tester les ACLs
---------------
Voilà quelques exemples de codes utilisés chez nous : 
```
$response = $this->getAdminClient()->request('GET', '/flavors');
self::assertResponseIsSuccessful();
self::assertCount(6, $response->toArray()['hydra:member']);
self::assertEquals(6, $response->toArray()['hydra:totalItems']);
// si entité classique
self::assertMatchesResourceCollectionJsonSchema(Flavor::class);

// si entité complexe (champs additionnels en fonction du rôle)
foreach ($response->toArray()['hydra:member'] as $flav) {
    
    self::assertEqualsCanonicalizing(['@id', '@type', 'id', 'name', 'ram', 'core', 'disk', 'isPublic'], array_keys($flav));
    self::assertTrue($flav['isPublic'], 'isPublic is always true for admin user');
}
```

Configuration de Rector pour upgrades facile en PHP8 / Symfony6
--------------------------------------------------
Ajoutez un fichier `rector.php` à la racine de votre repository avec : 
```
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Doctrine\Set\DoctrineSetList;
use Rector\Set\ValueObject\SetList;
use Rector\Symfony\Set\SensiolabsSetList;
use Rector\Symfony\Set\SymfonySetList;

return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->import(SetList::PHP_80); // use SetList::PHP_81 at migration and rerun
    $rectorConfig->import(DoctrineSetList::ANNOTATIONS_TO_ATTRIBUTES);
    $rectorConfig->import(SymfonySetList::ANNOTATIONS_TO_ATTRIBUTES);
    $rectorConfig->import(SensiolabsSetList::FRAMEWORK_EXTRA_61);
};
```

CI/CD rapide
------------
Lisez `.gitlab-ci.yml` ; 
Notamment les lignes de lancement des principaux outils présentés :)


Accès facile à la toolbox en local
---------------------------------
Inspirez vous du fichier `Makefile` ici, à copier à la racine de votre repository.
Pour voir les possibilités, lancez `make help` dans le répertoire.
