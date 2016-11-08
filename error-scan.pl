#!/usr/bin/perl
#

use warnings;
use strict;

my $TO_FILES = 0;
my $OUTDIR = $ENV{OUTDIR} . "/";

# stub CourseEnvironment otherwise we depend on webwork being installed and configured
{
	package WeBWorK::CourseEnvironment;
	use Exporter;
	our @ISA = qw(Exporter);
	sub new {
		my ($class, $stuff) = @_;
		bless $stuff, $class;
		# for Chromatic
		$stuff->{pg_dir} = $ENV{PG_ROOT};
		$stuff->{webworkDirs}->{DATA} = $ENV{OUTDIR} . "/trash/";
		return $stuff;
	}

	package WeBWorK::Utils;
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw(x);
	our @EXPORT_OK = qw(x path_is_subdir);
	sub path_is_subdir {
		return 1;
	}
	sub x {
		return @_;
	}

	package WeBWorK::PG::IO;
	sub path_is_subdir {
		return 1;
	}

	package WeBWorK::Localize;
	sub x {
		return @_;
	}

#	package WWSafe;
#	sub new {
#		use Safe;
#		return new Safe;
#	}
}

BEGIN {
	$ENV{WEBWORK_ROOT} |= "./webwork2";
	$ENV{PG_ROOT} |= "./pg";
	$ENV{OUTDIR} |= "./output";
	$ENV{OPL_ROOT} |= "./webwork-open-problem-library";

	# stubs
	$INC{"WeBWorK/CourseEnvironment.pm"} = 1;
	$INC{"WeBWorK/Utils.pm"} = 1;
#	$INC{"WeBWorK/Debug.pm"} = 1;
#	$INC{"WWSafe.pm"} = 1;

	# stub these so I don't have to install them
	$INC{"Apache2/Log.pm"} = 1;
	$INC{"APR/Table.pm"} = 1;
}

use lib "$ENV{WEBWORK_ROOT}/lib";
use lib "$ENV{PG_ROOT}/lib";

use Data::Dumper;
use File::Basename;
use File::Path qw(make_path);
use WeBWorK::PG::Translator;
use Parser;
use BSD::Resource;

my $pt = make_pt();

while(<>) {
	chomp;
	my $problem = $_;
	my $pid = fork();
	if($pid) {
		alarm 1;
		$SIG{ALRM} = sub { kill 15, $pid; print "killed $problem\n"; };
		wait;
		alarm 0;
		$SIG{ALRM} = "DEFAULT";
	} else {
		$SIG{TERM} = sub { die "caught sigterm $problem: $!"};
		$SIG{SEGV} = sub { die "caught sigsegv $problem: $!"};
		setrlimit(RLIMIT_VMEM, 1024*1024*500, 1024*1024*500);
		test_problem($pt, $problem);
		exit;
	}
}

sub make_pt {
	my $modules = [
		  [
		    'HTML::Parser'
		  ],
		  [
		    'HTML::Entities'
		  ],
		  [
		    'DynaLoader'
		  ],
		  [
		    'Exporter'
		  ],
		  [
		    'GD'
		  ],
		  [
		    'AlgParser',
		    'AlgParserWithImplicitExpand',
		    'Expr',
		    'ExprWithImplicitExpand',
		    'utf8'
		  ],
		  [
		    'AnswerHash',
		    'AnswerEvaluator'
		  ],
		  [
		    'WWPlot'
		  ],
		  [
		    'Circle'
		  ],
		  [
		    'Complex'
		  ],
		  [
		    'Complex1'
		  ],
		  [
		    'Distributions'
		  ],
		  [
		    'Fraction'
		  ],
		  [
		    'Fun'
		  ],
		  [
		    'Hermite'
		  ],
		  [
		    'Label'
		  ],
		  [
		    'ChoiceList'
		  ],
		  [
		    'Match'
		  ],
		  [
		    'MatrixReal1'
		  ],
		  [
		    'Matrix'
		  ],
		  [
		    'Multiple'
		  ],
		  [
		    'PGrandom'
		  ],
		  [
		    'Regression'
		  ],
		  [
		    'Select'
		  ],
		  [
		    'Units'
		  ],
		  [
		    'VectorField'
		  ],
		  [
		    'Parser',
		    'Value'
		  ],
		  [
		    'Parser::Legacy'
		  ],
		  [
		    'Statistics'
		  ],
		  [
		    'Chromatic'
		  ],
		  [
		    'Applet',
		    'FlashApplet',
		    'JavaApplet',
		    'CanvasApplet',
		    'GeogebraWebApplet'
		  ],
		  [
		    'PGcore',
		    'PGalias',
		    'PGresource',
		    'PGloadfiles',
		    'PGanswergroup',
		    'PGresponsegroup',
		    'Tie::IxHash'
		  ],
		  [
		    'Locale::Maketext'
		  ],
		  [
		    'WeBWorK::Localize'
		  ],
		  [
		    'JSON'
		  ],
		  [
		    'Apache2::Log'
		  ],
		  [
		    'APR::Table'
		  ]
		];

	import WeBWorK::Utils;
	use WeBWorK::Localize;
	my $env = {
	          'studentName' => 'fake',
	          'studentID' => 'fake',
	          'PRINT_FILE_NAMES_PERMISSION_LEVEL' => 10,
	          'QUIZ_PREFIX' => '',
	          'effectivePermissionLevel' => undef,
	          'dueDate' => 1,
	          'CAPA_Graphics_URL' => '/webwork2_files/CAPA_Graphics/',
	          'server_root_url' => 'some-url',
	          'useBaseTenLog' => 0,
	          'functAbsTolDefault' => '0.001',
	          'functULimitDefault' => '0.9999999',
	          'functLLimitDefault' => '1e-07',
	          'functMaxConstantOfIntegration' => '100000000',
	          'functZeroLevelDefault' => '1e-14',
	          'functNumOfPoints' => 3,
	          'functVarDefault' => 'x',
	          'functRelPercentTolDefault' => '0.1',
	          'functZeroLevelTolDefault' => '1e-12',
	          'CAPA_Tools' => "$ENV{OPL_ROOT}/Contrib/CAPA/macros/CAPA_Tools/",
		  'numOfAttempts' => 2000,
		  'language_subroutine' => WeBWorK::Localize::getLoc("en"),
		  'externalGif2PngPath' => '/usr/bin/giftopnm | /usr/bin/pnmtopng',
		  'pdfPath' => [],
		  'outputMode' => 'HTML_MathJax',
		  'htmlDirectory' => "$ENV{OUTDIR}/trash/html/",
		  'probNum' => 10,
		  'fileName' => 'file',
		  'htmlURL' => 'htmlURL',
		  'templateDirectory' => '.',
		  'tempDirectory' => "$ENV{OUTDIR}/trash/",
		  'MathJaxURL' => '/webwork2_files/mathjax/MathJax.js?config=TeX-MML-AM_HTMLorMML-full',
		  'displayMode' => 'HTML_MathJax',
		  'VIEW_PROBLEM_DEBUGGING_INFO' => 5,
		  'imagesPath' => [],
		  'tempURL' => 'tempURL',
		  'pgDirectories' => {
				       'macrosPath' => [
				       			 './webwork2/courses.dist/modelCourse/templates/macros',
							 '.',
							 "$ENV{PG_ROOT}/macros",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/Union",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/Michigan",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/CollegeOfIdaho",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/FortLewis",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/TCNJ",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/NAU",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/Dartmouth",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/WHFreeman",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/UMass-Amherst",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/PCC",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/Alfred",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/Wiley",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/UBC",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/Hope",
							 "$ENV{OPL_ROOT}/OpenProblemLibrary/macros/Mizzou",
						       ],
				       'htmlPath' => [
						       "$ENV{OUTDIR}/trash/",
						     ],
				       'imagesPath' => [
						         "$ENV{OUTDIR}/trash/",
						       ],
				       'pdfPath' => [
						      "$ENV{OUTDIR}/trash/",
						    ],
				       'macros' => "$ENV{PG_ROOT}/macros",
				       'lib' => "$ENV{PG_ROOT}/lib",
				       'root' => "$ENV{PG_ROOT}",
				       'appletPath' => [
							 '/webwork2_files/applets',
							 '/webwork2_files/applets/geogebra_stable',
							 '/webwork2_files/applets/Xgraph',
							 '/webwork2_files/applets/PointGraph',
							 '/webwork2_files/applets/Xgraph',
							 '/webwork2_files/applets/liveJar',
							 '/webwork2_files/applets/Image_and_Cursor_All'
						       ]
				     },
		  'setNumber' => 'Undefined_Set',
		  'macrosPath' => [],
		  'problemValue' => -1,
		  'problemSeed' => '1234',
		  'problemPreamble' => {
					 'HTML' => '',
					 'TeX' => ''
				       },
		  'studentLogin' => 'fake',
		  'problemPostamble' => {
					  'HTML' => '',
					  'TeX' => ''
					},
		  'probFileName' => '/',
		};
	$env->{'imagesPath'} = $env->{'pgDirectories'}{'imagesPath'};
	$env->{'pdfPath'} = $env->{'pgDirectories'}{'pdfPath'};
	$env->{'macrosPath'} = $env->{'pgDirectories'}{'macrosPath'};
	$env->{'appletPath'} = $env->{'pgDirectories'}{'appletPath'};
	$env->{'htmlPath'} = $env->{'pgDirectories'}{'htmlPath'};

	my $pt = new WeBWorK::PG::Translator;

	foreach my $module_packages_ref (@$modules) {
		my ($module, @extra_packages) = @$module_packages_ref;
		# the first item is the main package
		$pt->evaluate_modules($module);
		# the remaining items are "extra" packages
		$pt->load_extra_packages(@extra_packages);
	}
	$pt->environment($env);
	$pt->initialize();

	$pt->unrestricted_load("$ENV{PG_ROOT}/macros/PG.pl");

	return $pt;
}

sub test_problem {
	my ($pt, $problem) = @_;

	if($TO_FILES) {
		make_path($OUTDIR . dirname($problem));
		open(STDOUT, ">", $OUTDIR . $problem . ".log");
		open(STDERR, ">&=", 1);
	} else {
		print "$problem:\n";
	}

	my $ps;
	open(my $f, $problem);
	while(<$f>) {
		$ps .= $_;
	}
	close $f;

	$pt->source_string($ps);

	$pt->rf_safety_filter(\&WeBWorK::PG::nullSafetyFilter);
	$pt->set_mask();
	$pt->translate();

	close(STDOUT);
	close(STDERR);
	if($TO_FILES && -z $OUTDIR . $problem . ".log") {
		unlink($OUTDIR . $problem . ".log");
	}
}
