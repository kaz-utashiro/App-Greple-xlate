=encoding utf-8

=head1 NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.25

=head1 DESCRIPTION

B<Greple> B<xlate> module vindt tekstblokken en vervangt ze door de vertaalde tekst. Momenteel wordt alleen DeepL service ondersteund door de B<xlate::deepl> module.

Als je normale tekstblokken in L<pod> style document wilt vertalen, gebruik dan B<greple> commando met C<xlate::deepl> en C<perl> module zoals dit:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Patroon C<^(\w.*\n)+> betekent opeenvolgende regels die beginnen met een alfa-numerieke letter. Dit commando toont het te vertalen gebied. Optie B<--all> wordt gebruikt om de hele tekst te produceren.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Voeg dan de optie C<--xlate> toe om het geselecteerde gebied te vertalen. Het zal ze vinden en vervangen door de uitvoer van het B<deepl> commando.

Standaard worden originele en vertaalde tekst afgedrukt in het "conflict marker" formaat dat compatibel is met L<git(1)>. Door C<ifdef> formaat te gebruiken, kunt u gemakkelijk het gewenste deel krijgen met het L<unifdef(1)> commando. Het formaat kan gespecificeerd worden met de optie B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Als u de hele tekst wilt vertalen, gebruik dan de optie B<--match-all>. Dit is een snelkoppeling om aan te geven dat het patroon overeenkomt met de hele tekst C<(?s).+>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Roep het vertaalproces op voor elk gematcht gebied.

Zonder deze optie gedraagt B<greple> zich als een normaal zoekcommando. U kunt dus controleren welk deel van het bestand zal worden vertaald voordat u het eigenlijke werk uitvoert.

Commandoresultaat gaat naar standaard out, dus redirect naar bestand indien nodig, of overweeg L<App::Greple::update> module te gebruiken.

Optie B<--xlate> roept B<--xlate-kleur> aan met B<--color=never> optie.

Met de optie B<--xlate-fold> wordt geconverteerde tekst gevouwen met de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met de optie B<--xlate-fold-width>. Vier kolommen zijn gereserveerd voor inloopoperaties, zodat elke regel maximaal 74 tekens kan bevatten.

=item B<--xlate-engine>=I<engine>

Specificeer de te gebruiken vertaalmachine. U hoeft deze optie niet te gebruiken omdat module C<xlate::deepl> deze verklaart als C<--xlate-engine=deepl>.

=item B<--xlate-labor>

=item B<--xlabor>

In plaats van de vertaalmachine op te roepen, wordt van u verwacht dat u voor werkt. Na het voorbereiden van te vertalen tekst, worden ze gekopieerd naar het klembord. Van u wordt verwacht dat u ze in het formulier plakt, het resultaat naar het klembord kopieert en op return drukt.

=item B<--xlate-to> (Default: C<EN-US>)

Geef de doeltaal op. U kunt de beschikbare talen krijgen met het commando C<deepl languages> wanneer u de engine B<DeepL> gebruikt.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Specificeer het uitvoerformaat voor originele en vertaalde tekst.

=over 4

=item B<conflict>, B<cm>

Print originele en vertaalde tekst in L<git(1)> conflictmarker formaat.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

U kunt het originele bestand herstellen met de volgende L<sed(1)> opdracht.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Originele en vertaalde tekst afdrukken in L<cpp(1)> C<#ifdef> formaat.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

U kunt alleen Japanse tekst terughalen met het commando B<unifdef>:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Originele en vertaalde tekst afdrukken, gescheiden door een enkele lege regel.

=item B<xtxt>

Als het formaat C<xtxt> (vertaalde tekst) of onbekend is, wordt alleen vertaalde tekst afgedrukt.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Specificeer de maximale lengte van de tekst die in één keer naar de API moet worden gestuurd. De standaardwaarde is ingesteld zoals voor de gratis accountdienst: 128K voor de API (B<--xlate>) en 5000 voor de klembordinterface (B<--xlate-labor>). U kunt deze waarde wijzigen als u de Pro-service gebruikt.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Zie het resultaat van de vertaling in real time in de STDERR uitvoer.

=item B<--match-all>

Stel de hele tekst van het bestand in als doelgebied.

=back

=head1 CACHE OPTIONS

De module B<xlate> kan de tekst van de vertaling voor elk bestand in de cache opslaan en lezen vóór de uitvoering om de overhead van het vragen aan de server te elimineren. Met de standaard cache strategie C<auto>, onderhoudt het alleen cache gegevens wanneer het cache bestand bestaat voor het doelbestand.

=over 7

=item --cache-clear

De optie B<--cache-clear> kan worden gebruikt om het beheer van de cache te starten of om alle bestaande cache-gegevens te vernieuwen. Eenmaal uitgevoerd met deze optie, wordt een nieuw cachebestand aangemaakt als er geen bestaat en daarna automatisch onderhouden.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Onderhoud het cachebestand als het bestaat.

=item C<create>

Maak een leeg cache bestand en sluit af.

=item C<always>, C<yes>, C<1>

Cache-bestand toch behouden voor zover het doelbestand een normaal bestand is.

=item C<clear>

Wis eerst de cachegegevens.

=item C<never>, C<no>, C<0>

Cache-bestand nooit gebruiken, zelfs niet als het bestaat.

=item C<accumulate>

Standaard worden ongebruikte gegevens uit het cachebestand verwijderd. Als u ze niet wilt verwijderen en in het bestand wilt houden, gebruik dan C<accumuleren>.

=back

=back

=head1 COMMAND LINE INTERFACE

U kunt deze module gemakkelijk gebruiken vanaf de commandoregel met het commando C<xlate> dat in het archief is opgenomen. Zie de C<xlate> help informatie voor gebruik.

=head1 EMACS

Laad het F<xlate.el> bestand in het archief om het C<xlate> commando te gebruiken vanuit de Emacs editor. C<xlate-region> functie vertaalt de gegeven regio. De standaardtaal is C<EN-US> en u kunt de taal specificeren met het prefix argument.

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Stel uw authenticatiesleutel in voor DeepL service.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L<App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Python bibliotheek en CLI commando.

=item L<App::Greple>

Zie de B<greple> handleiding voor de details over het doeltekstpatroon. Gebruik B<--inside>, B<--outside>, B<--include>, B<--exclude> opties om het overeenkomende gebied te beperken.

=item L<App::Greple::update>

U kunt de module C<-Mupdate> gebruiken om bestanden te wijzigen door het resultaat van het commando B<greple>.

=item L<App::sdif>

Gebruik B<sdif> om het formaat van de conflictmarkering naast de optie B<-V> te tonen.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
