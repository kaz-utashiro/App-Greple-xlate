use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::Greple::xlate
    App::Greple::xlate::deepl
    App::Greple::xlate::gpt3
    App::Greple::xlate::gpt4
    App::Greple::xlate::Cache
);

done_testing;

