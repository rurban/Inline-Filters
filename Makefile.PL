use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Inline::Filters',
  VERSION_FROM => 'Filters.pm',
  PREREQ_PM => {
    Inline    => 0.42,
    Inline::C => 0.42,
  },
  clean => {FILES => '_Inline/'},
  SIGN => 1,
  );
