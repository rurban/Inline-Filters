use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'Inline::Filters',
	      VERSION_FROM => 'Filters.pm',
	      clean => {FILES => '_Inline/'},
	     );
