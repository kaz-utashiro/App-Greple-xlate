=encoding utf-8

=head1 NAME

App::Greple::xlate - module d'aide à la traduction pour greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.25

=head1 DESCRIPTION

Le module B<Greple> B<xlate> trouve des blocs de texte et les remplace par le texte traduit. Actuellement, seul le service DeepL est pris en charge par le module B<xlate::deepl>.

Si vous voulez traduire un bloc de texte normal dans un document de style L<pod>, utilisez la commande B<greple> avec le module C<xlate::deepl> et C<perl> comme ceci :

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Le motif C<^(\w.*\n)+> signifie des lignes consécutives commençant par une lettre alpha-numérique. Cette commande montre la zone à traduire. L'option B<--all> est utilisée pour produire le texte entier.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Ensuite, ajoutez l'option C<--xlate> pour traduire la zone sélectionnée. Elle les trouvera et les remplacera par la sortie de la commande B<deepl>.

Par défaut, le texte original et traduit est imprimé dans le format "marqueur de conflit" compatible avec L<git(1)>. En utilisant le format C<ifdef>, vous pouvez obtenir facilement la partie souhaitée par la commande L<unifdef(1)>. Le format peut être spécifié par l'option B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Si vous souhaitez traduire un texte entier, utilisez l'option B<--match-all>. Il s'agit d'un raccourci pour spécifier que le motif correspond au texte entier C<(?s).+>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Invoquez le processus de traduction pour chaque zone appariée.

Sans cette option, B<greple> se comporte comme une commande de recherche normale. Vous pouvez donc vérifier quelle partie du fichier fera l'objet de la traduction avant d'invoquer le travail réel.

Le résultat de la commande va vers la sortie standard, donc redirigez vers le fichier si nécessaire, ou envisagez d'utiliser le module L<App::Greple::update>.

L'option B<--xlate> appelle l'option B<--xlate-color> avec l'option B<--color=never>.

Avec l'option B<--xlate-fold>, le texte converti est plié selon la largeur spécifiée. La largeur par défaut est de 70 et peut être définie par l'option B<--xlate-fold-width>. Quatre colonnes sont réservées à l'opération de rodage, de sorte que chaque ligne peut contenir 74 caractères au maximum.

=item B<--xlate-engine>=I<engine>

Spécifiez le moteur de traduction à utiliser. Vous n'avez pas à utiliser cette option car le module C<xlate::deepl> le déclare comme C<--xlate-engine=deepl>.

=item B<--xlate-labor>

=item B<--xlabor>

Au lieu d'appeler le moteur de traduction, vous êtes censé travailler pour. Après avoir préparé les textes à traduire, ils sont copiés dans le presse-papiers. Vous êtes censé les coller dans le formulaire, copier le résultat dans le presse-papiers et appuyer sur la touche retour.

=item B<--xlate-to> (Default: C<EN-US>)

Spécifiez la langue cible. Vous pouvez obtenir les langues disponibles par la commande C<deepl languages> lorsque vous utilisez le moteur B<DeepL>.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Spécifiez le format de sortie pour le texte original et le texte traduit.

=over 4

=item B<conflict>, B<cm>

Imprimez le texte original et traduit au format de marqueur de conflit L<git(1)>.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Vous pouvez récupérer le fichier original par la commande L<sed(1)> suivante.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Impression du texte original et du texte traduit au format C<#ifdef> de L<cpp(1)>.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

Vous pouvez récupérer uniquement le texte japonais par la commande B<unifdef> :

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Imprimer le texte original et le texte traduit séparés par une seule ligne blanche.

=item B<xtxt>

Si le format est C<xtxt> (texte traduit) ou inconnu, seul le texte traduit est imprimé.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Spécifie la longueur maximale du texte à envoyer à l'API en une seule fois. La valeur par défaut est la même que pour le service de compte gratuit : 128K pour l'API (B<--xlate>) et 5000 pour l'interface du presse-papiers (B<--xlate-labor>). Vous pouvez modifier ces valeurs si vous utilisez le service Pro.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Voir le résultat de la traduction en temps réel dans la sortie STDERR.

=item B<--match-all>

Définissez l'ensemble du texte du fichier comme zone cible.

=back

=head1 CACHE OPTIONS

Le module B<xlate> peut stocker le texte de la traduction en cache pour chaque fichier et le lire avant l'exécution pour éliminer les frais généraux de demande au serveur. Avec la stratégie de cache par défaut C<auto>, il maintient les données de cache uniquement lorsque le fichier de cache existe pour le fichier cible.

=over 7

=item --cache-clear

L'option B<--cache-clear> peut être utilisée pour initier la gestion du cache ou pour rafraîchir toutes les données du cache existant. Une fois exécutée avec cette option, un nouveau fichier de cache sera créé s'il n'en existe pas, puis automatiquement maintenu par la suite.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Maintenir le fichier de cache s'il existe.

=item C<create>

Créer un fichier cache vide et quitter.

=item C<always>, C<yes>, C<1>

Maintenir le cache de toute façon tant que la cible est un fichier normal.

=item C<clear>

Effacer d'abord les données du cache.

=item C<never>, C<no>, C<0>

Ne jamais utiliser le fichier cache même s'il existe.

=item C<accumulate>

Par défaut, les données inutilisées sont supprimées du fichier cache. Si vous ne voulez pas les supprimer et les conserver dans le fichier, utilisez C<accumulate>.

=back

=back

=head1 COMMAND LINE INTERFACE

Vous pouvez facilement utiliser ce module à partir de la ligne de commande en utilisant la commande C<xlate> incluse dans le référentiel. Voir l'aide de C<xlate> pour l'utilisation.

=head1 EMACS

Chargez le fichier F<xlate.el> inclus dans le dépôt pour utiliser la commande C<xlate> à partir de l'éditeur Emacs. La fonction C<xlate-region> traduit la région donnée. La langue par défaut est C<EN-US> et vous pouvez spécifier la langue en l'invoquant avec l'argument prefix.

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Définissez votre clé d'authentification pour le service DeepL.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L<App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Bibliothèque Python et commande CLI.

=item L<App::Greple>

Voir le manuel B<greple> pour les détails sur le modèle de texte cible. Utilisez les options B<--inside>, B<--outside>, B<--include>, B<--exclude> pour limiter la zone de correspondance.

=item L<App::Greple::update>

Vous pouvez utiliser le module C<-Mupdate> pour modifier les fichiers par le résultat de la commande B<greple>.

=item L<App::sdif>

Utilisez B<sdif> pour afficher le format des marqueurs de conflit côte à côte avec l'option B<-V>.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
