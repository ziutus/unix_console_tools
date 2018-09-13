#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Cwd;


my $dirname=getcwd;
my @dirs= split "/", $dirname;
$dirname=$dirs[-1];

my @options=("SOFTWARE_VERSION", "SOFTWARE_RELEASE", "SOFTWARE_NAME", "SOFTWARE_DEPENDS", "MAINTAINER", "SOFTWARE_DESCRIPTION", 
	"SOFTWARE_DESCRIPTION_LONG", "SOFTWARE_LICENCE",  "SOFTWARE_GROUP", "SOFTWARE_HOMEPAGE", "SOFTWARE_SEPARATE_DIR_OPT", "USR_LOCAL");

my @options_env=("MAINTAINER","SOFTWARE_LICENCE");

my %options_default;

$options_default{"SOFTWARE_LICENCE"}="GPL";
$options_default{"SOFTWARE_GROUP"}="Development/Tools";
$options_default{"USR_LOCAL"}="yes";
$options_default{"SOFTWARE_SEPARATE_DIR_OPT"}="yes";
$options_default{"SOFTWARE_VERSION"}="0.0.1";
$options_default{"SOFTWARE_RELEASE"}="1";
$options_default{"SOFTWARE_DEPENDS"}="base-files";
$options_default{"SOFTWARE_NAME"}=$dirname;



my $RET1=undef;
my %MYFILE;
my @MYFILE;

my %OPTIONS;

sub ask_nice {

	my $message;
	my $return;
	my $return_read;

	#print Dumper(@_);

	($message, $return)  = @_;
	
	$return="" unless defined $return;
	
	print  "$message [$return]:";
	$return_read=<STDIN>;
	chomp $return_read;

	if (length($return_read)>0) {
		$return=$return_read;
	}

	while (! $return) {

		print  "$message [$return]:";
		$return_read=<STDIN>;
		chomp $return_read;

		if (length($return_read)>0) {
			$return=$return_read;
		}
	}

	return $return;
}

###
#
###
foreach my $option (@options_env) {
	if (defined($ENV{$option})) {
		$MYFILE{$option}=$ENV{$option};
	}
}

###
#
###


while ((my $key,my $value) = each(%options_default)){
		$MYFILE{$key}=$value;
}


###
#	reading options from configuration file
###
if ( -e ".create_package.conf") {
	open FILE, ".create_package.conf";
	my @MYFILE=<FILE>;
	close FILE;
	chomp @MYFILE;

	foreach my $line (@MYFILE) {
		my $key;
		my $value;
		
		if (length($line) > 0 ) {
			($key, $value) = split "=", $line ;
			$MYFILE{$key}=$value;
		}
	}
}

###
#
###
#foreach my 


###
#	Asking for options with values readed from config file 
###
foreach my $Option (@options) {
	$OPTIONS{$Option} = ask_nice($Option,$MYFILE{$Option});	
}


###	
#   writting file config file to directory
###
open FILE, ">.create_package.conf";
foreach my $Option (@options) {
	print FILE "$Option=\"", $OPTIONS{$Option}, "\"\n";
}
close FILE;	

###
#	end of script
###	
exit 0;
