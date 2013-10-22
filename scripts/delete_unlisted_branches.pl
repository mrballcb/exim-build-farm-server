#!/usr/bin/perl

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

my ($brhandle,@branches_of_interest);
if (open($brhandle,"$ENV{BFConfDir}/htdocs/branches_of_interest.txt"))
{
    @branches_of_interest = <$brhandle>;
    close($brhandle);
    chomp(@branches_of_interest);
}

my $sth = $db->prepare(q[ 
       SELECT DISTINCT ON (sysname,branch)
       sysname,branch
       FROM build_status AS s
       JOIN buildsystems AS b ON (s.sysname = b.name)
       ORDER BY sysname, branch ASC
      ]);
$sth->execute();

my $del_sth = $db->prepare(q[
       DELETE FROM build_status
       WHERE sysname = ?
       AND branch = ?
      ]);
my $del_dash_sth = $db->prepare(q[
       DELETE FROM dashboard_mat
       WHERE sysname = ?
       AND branch = ?
      ]);
my $del_snap_sth = $db->prepare(q[
       DELETE FROM latest_snapshot
       WHERE sysname = ?
       AND branch = ?
      ]);
while (my $row = $sth->fetchrow_hashref)
{
  my $sysname = $row->{sysname};
  my $branch = $row->{branch};
  print "Considering $sysname:$branch\n";
  unless (grep {$_ eq $branch} @branches_of_interest)
  {
    print "** Delete branch $branch\n";
    $del_sth->execute($sysname,$branch);
    $del_dash_sth->execute($sysname,$branch);
    $del_snap_sth->execute($sysname,$branch);
  }
}
$db->disconnect();
