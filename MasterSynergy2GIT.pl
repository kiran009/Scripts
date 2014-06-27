#!/usr/bin/perl
use Cwd;
use File::Path;
use GetOpt::Long;

#/************ Setting Environment Variables *******************/
$ENV{'CCM_HOME'}="/opt/ccm71";
$ENV{'PATH'}="$ENV{'CCM_HOME'}/bin:$ENV{'PATH'}";
$CCM="$ENV{'CCM_HOME'}/bin/ccm";
$GIT="/usr/bin/git";
#/***************************************************************/

open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm start -m -q -d /ccm/ccmdb/adg -h ccmindia1 -nogui |");
$ENV{'CCM_ADDR'}=<ccm_addr>;
close(ccm_addr);

$wd=cwd();

print "Before creating git repo please run the following \n\n";
print "git config --global user.email \"you@evolving.com\"\n";
print "git config --global user.name \"Your Name\" \n\n";
OPTIONS:print "\n1.Create Product Assembly repos \t 2. Create Customer Assembly repos \t 3. Exit \n\n";
print "Enter your option (1/2/3): ";
$option=<STDIN>;
chomp($option);

sub repocreation
{
	$releasedef=$_[0];
	chomp($releasedef);
	print "$releasedef \n";
	unlink "$wd/projectlist";
	print "Do you want to create fresh gitrepo directory ? y/n :";
	$val=<STDIN>;
	chomp($val);
	if ($val=~"y")
	{
		rmtree( [ "$wd/gitrepos/" ],1);
		chdir $wd;
		mkpath('gitrepos');
	}
	if ($val=~"n")
	{
		print "Proceeding with repo creation in the same directory \n";
	}
	print "Reading from release definition file \n";
	if ($releasedef =~ "customerreleasedef")
	{
		open(FILE,"$wd/$releasedef");
		while (<FILE>)
		{
			chomp($_);
		        push @{$project{$_}},`$CCM query -t project \"release=\'$_\' and status=\'sqa\'" -u -f \"%name-%version\"`;
		}
		close FILE;
	}
	elsif ($releasedef =~ "productreleasedef")
	{
		open(FILE,"$wd/$releasedef");
		while (<FILE>)
		{
		        chomp($_);
		        push @{$project{$_}},`$CCM query -t project \"release=\'$_\' and status=\'integrate\'" -u -f \"%name-%version\"`;
		}
		close FILE;
	}

	foreach $rel (keys %project)
	{
        	foreach $projectname (@{$project{$rel}})
	        {
        	        chomp($projectname);
                	open(FH,">>$wd/projectlist");
	                print FH $projectname,"\n";
        	        close FH;
	        }
	}

	$i=0;
	print "Checking for latest baseline \n";
	open(FILE,"$wd/projectlist");
	while(<FILE>)
	{
		chomp($_);
		($key,$val)=split /-/,$_;
		$name=$key;
		if (exists($hash{$name}))
		{
			undef @array;
			push @array,$hash{$name};
			push @array,$val;
			foreach (@array)
			{
				chomp($_);
	        		$date1=`$CCM query -t project \"name=\'$name\' and version=\'$_\'\" -u -f \"%modify_time\"`;
				chomp($date1);
				$result=qx[date -d "$date1" +"%H:%M:%S, %m/%d/%Y"];
				chomp($result);
				($H,$M,$S,$d,$m,$Y) = $result =~ m{^([0-9]{2}):([0-9]{2}):([0-9]{2}), ([0-9]{2})/([0-9]{2})/([0-9]{4})\z};
				$d1="$Y$m$d$H$M$S";
				$datearray{$_}=$d1;
			}
			$maxval=-1;
			while(($ver,$dt)=each %datearray)
			{
				if($dt>$maxval)
				{
					$maxval=$dt;
					$maxkey=$ver;
				}
			}
			$hash{$name}=$maxkey;
		#	@arr=sort{$a cmp $b} @newarray;
		#	print "$arr[$#arr] \n";
					
		}
		else
		{
			$hash{$key}=$val;
		}
}
close FILE;
}

if ($option == 1)
{
	repocreation('productreleasedef');
	print "Creating git repos for product assembly under $wd/gitrepos \n";
	while(($name,$version)=each %hash)
	{
		chomp($name);
		chomp($version);
		$objname=`$CCM query -t project \"name=\'$name\' and version=\'$version\'\" -u -f \"%objectname\"`;
		chomp($objname);
		print "\nCFS of $objname \n";
		open(ccmfile,"$CCM cfs -path $wd/gitrepos $objname |");
		close ccmfile;
		chdir("$wd/gitrepos/$name");
		print "Initializing git repo \n";
		open(gitrepo,"/usr/bin/git init |");
		close gitrepo;
		print "Committing files to git repo \n";
		open(add,"/usr/bin/git add -A |");
		close add;
		open(commit,"/usr/bin/git commit -m \"initial repository\" |");
		close commit;
		system("curl --header \"PRIVATE-TOKEN: bdsDmMa2VkvEF3m9fuzm\"  \"https://gitlab.telespree.com/api/v3/projects\" -H \"Accept: application/json\" -H \"Content-type: application/json\" -H \"name: master\" -X POST --data \'{\"event_name\": \"project_create\",\"name\":\"$name\",\"path\":\"$name\"}\'");
		open(addorigin,"/usr/bin/git remote add origin git\@gitlab.telespree.com\:shreraam\/$name.git |");
		close addorigin;
		open(pushrepo,"/usr/bin/git push -u origin master |");
		close pushrepo;
	
	}	
}
elsif($option == 2)
{
	repocreation('customerreleasedef');
	print "Creating git repos for customer assembly under $wd/gitrepos \n";
	while(($name,$version)=each %hash)
	{	
        	chomp($name);
			chomp($version);
	        $objname=`$CCM query -t project \"name=\'$name\' and version=\'$version\'\" -u -f \"%objectname\"`;
        	chomp($objname);
	        print "CFS of $objname \n";
        	open(ccmfile,"$CCM cfs -path $wd/gitrepos $objname |");
	        close ccmfile;
        	chdir("$wd/gitrepos/$name");
			print "Removing products directory \n";
			rmtree('$wd/gitrepos/$name/products/');	
	        print "Initializing git repo \n";
        	open(gitrepo,"/usr/bin/git init |");
	        close gitrepo;
        	print "Committing files to git repo \n";
	        open(add,"/usr/bin/git add -A |");
        	close add;
	        open(commit,"/usr/bin/git commit -m \"initial repository\" |");
        	close commit;
	        system("curl --header \"PRIVATE-TOKEN: bdsDmMa2VkvEF3m9fuzm\"  \"https://gitlab.telespree.com/api/v3/projects\" -H \"Accept: application/json\" -H \"Content-type: application/json\" -H \"name: master\" -X POST --data \'{\"event_name\": \"project_create\",\"name\":\"$name\",\"path\":\"$name\"}\'");
        	open(addorigin,"/usr/bin/git remote add origin git\@gitlab.telespree.com\:shreraam\/$name.git |");
	        close addorigin;
        	open(pushrepo,"/usr/bin/git push -u origin master |");
	        close pushrepo;

	}

}
elsif ($option == 3)
{
	open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm stop |");
	close(ccm_addr);
    exit;
}
goto OPTIONS;