#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Data::Dumper;

use vars qw($dbhost $dbname $dbuser $dbpass $dbport
            $user_list_format
);
require "$ENV{BFConfDir}/BuildFarmWeb.pl";

die "no dbname" unless $dbname;
die "no dbuser" unless $dbuser;

my $dsn="dbi:Pg:dbname=$dbname";
$dsn .= ";host=$dbhost" if $dbhost;
$dsn .= ";port=$dbport" if $dbport;

my $db = DBI->connect($dsn,$dbuser,$dbpass);

die $DBI::errstr unless $db;

my $sth = $db->prepare(q[ 
       SELECT name, secret
       FROM buildsystems AS b
       ORDER BY name ASC
      ]);
$sth->execute();

$user_list_format = "%-20s %s\n";
printf $user_list_format, "SysName", "Secret";
while (my $row = $sth->fetchrow_hashref)
{
  printf $user_list_format, $row->{name}, $row->{secret};
}
$db->disconnect();
