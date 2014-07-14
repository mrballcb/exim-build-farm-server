#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Data::Dumper;
use Getopt::Long;

use vars qw($dbhost $dbname $dbuser $dbpass $dbport
            $user_list_format
);
require "$ENV{BFConfDir}/BuildFarmWeb.pl";

die "no dbname" unless $dbname;
die "no dbuser" unless $dbuser;

my %opts = ( outfile => "/etc/mail/lists/farmers" );
GetOptions( \%opts,
  'outfile:s',
);

my $dsn="dbi:Pg:dbname=$dbname";
$dsn .= ";host=$dbhost" if $dbhost;
$dsn .= ";port=$dbport" if $dbport;

my $db = DBI->connect($dsn,$dbuser,$dbpass);

die $DBI::errstr unless $db;

my $sth = $db->prepare(q[ 
       SELECT owner_email
       FROM buildsystems AS b
       ORDER BY owner_email ASC
      ]);
$sth->execute();

my %list;
while (my $row = $sth->fetchrow_hashref)
{
  $list{$row->{owner_email}}++;
}
$db->disconnect();

open(my $fh, ">", $opts{outfile});
if ($fh) {
  print $fh (join "\n", (keys %list));
}
close $fh;
