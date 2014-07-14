#!/usr/bin/perl

# Called by the user the web server runs as to clean up old database
# records and old build logs

use strict;
use warnings;
use DBI;
use Data::Dumper;

use vars qw($dbhost $dbname $dbuser $dbpass $dbport
);
require "$ENV{BFConfDir}/BuildFarmWeb.pl";

die "no dbname" unless $dbname;
die "no dbuser" unless $dbuser;

my $dsn="dbi:Pg:dbname=$dbname";
$dsn .= ";host=$dbhost" if $dbhost;
$dsn .= ";port=$dbport" if $dbport;

my $db = DBI->connect($dsn,$dbuser,$dbpass);

die $DBI::errstr unless $db;

my $del_sth = $db->prepare(q[
       DELETE FROM build_status
       WHERE snapshot < (now() - interval '3 months')
      ]);
my $del_recent_sth = $db->prepare(q[
       DELETE FROM build_status_recent_500
       WHERE snapshot < (now() - interval '3 months')
      ]);

$del_sth->execute();
$del_recent_sth->execute();

my $buildlogs = "$ENV{BFConfDir}/buildlogs";

my @dirs = `find $buildlogs -mindepth 1 -type d -ctime +95`;
foreach my $dir (@dirs) {
  chomp $dir;
  print `rm -rf $dir`;
}
