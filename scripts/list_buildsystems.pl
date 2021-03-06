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
       SELECT name, status, operating_system, os_version, sys_owner, owner_email
       FROM buildsystems AS b
       ORDER BY name ASC
      ]);
$sth->execute();

printf $user_list_format, "SysName", "Status", "Owner", "Email", "Distro", "Version";
while (my $row = $sth->fetchrow_hashref)
{
  printf $user_list_format,
                  $row->{name}, $row->{status}, $row->{sys_owner},
                  $row->{owner_email}, $row->{operating_system},
                  $row->{os_version};
}
$db->disconnect();
