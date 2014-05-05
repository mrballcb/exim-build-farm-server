#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Data::Dumper;

die "Must pass one and only one sysname to delete\n"
  unless scalar @ARGV == 1;

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

my @tables = qw/alerts buildsystems build_status build_status_log
                build_status_recent_500 dashboard_mat latest_snapshot
                nrecent_failures personality/;
my $sth;
for my $loop (0 .. (scalar @tables - 1) ) {
  my $field = ($tables[$loop] eq 'personality') ? 'name' :
              ($tables[$loop] eq 'buildsystems') ? 'name':
              'sysname';
  printf "Deleting from %s with field %s\n", $tables[$loop], $field;
  $sth = $db->prepare("
       DELETE FROM $tables[$loop]
       WHERE $field = ?
      ");
  $sth->execute($ARGV[0]);
}
$db->disconnect();
