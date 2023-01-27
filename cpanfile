requires 'perl', '5.014';

requires 'App::Greple';
requires 'Getopt::EX', '2.1.2';
requires 'JSON';
requires 'App::sdif';
requires 'Text::ANSI::Fold';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
