#!/usr/bin/perl
use Cwd;
use File::Path;
use File::Find;
use File::Basename;
use Switch;

#/************ Setting Environment Variables *******************/
$ENV{'CCM_HOME'}="/opt/ccm71";
$ENV{'PATH'}="$ENV{'CCM_HOME'}/bin:$ENV{'PATH'}";
$CCM="$ENV{'CCM_HOME'}/bin/ccm";
$Scripts_Dir="/data/ccmbm/final_script/kiran_test";
$database="/data/ccmdb/dsa/";
$dbbmloc="/data/ccmbm/dsa/";
my @PatchFiles,@files;
my $patch_number,$problem_number;
my @CRS,@crs,@tasks,$CRlist;
$PatchReleaseVersion;
$projectName;
$platformlist;
$hostname;
@platforms;
$ftpdir="/u/kkdaadhi/Patch_$patch_number";
$mailto='kiran.daadhi@evolving.com';
$ftpdir="/u/prathish/Jenkins/Patch_$patch_number";
%hash;
#$mailto='kiran.daadhi@evolving.com Shreraam.Gurumoorthy@evolving.com Viswanath.Banakar@evolving.com Kumar.SK@evolving.com Sekhar.Sahu@evolving.com Anand.Gubbi@evolving.com';
#/* Global Environment Variables ******* /

main();
sub main()
{
	start_ccm();
	query_cr(); 
	#send_email();
	#create_childcrs();
	move_cr_status();
	ccm_stop();
	exit;
}

sub query_cr()
{
	# Get the list of CRs in 'Implemented' State
	chdir $Scripts_Dir;
	@ccm_query=`$CCM query "cvtype='problem' and crstatus='Implemented' and problem_number='3654'"`;
	@ccm_fmt=`$CCM query -u -f %problem_number,%patch_number`;
	$devId=`$CCM query -u -f %resolver`;
	foreach(@ccm_fmt)
	{
		($problem_number,$patch_number)=split(/,/,$_);
		print "\$problem_number is: $problem_number and \$patch_number is: $patch_number \n";
		chomp($patch_number);
		chomp($problem_number);
		#$ccm_qry=`$CCM query "cvtype='problem' and crstatus='Implemented' and patch_number=$patch_number"`;
		#print "\$ccm_qry is: $ccm_qry \n";
		$patch_number=~ s/^\s+|\s+$//g; 	
		$problem_number=~ s/^\s+|\s+$//g; 	
		$patchreadme=`$CCM query -u -f %patch_readme`;
		print "$patchreadme \n";
		open OP,"+> $patch_number\_README.txt";
		print OP $patchreadme;
		close OP;
		`dos2unix $patch_number\_README.txt 2>&1 1>/dev/null`;		
	}	
	read_readme();
	fetch_crs();
}
sub read_readme()
{
	# Read the README file for Task information
	open OP, "< $patch_number\_README.txt";
	my @op=<OP>;
	close OP;
	foreach $op(@op)
	{	
		if($op =~ /TASK/)
		{
			($temp,$TaskFullNumber)=split(/:/,$op);
            $TaskFullNumber=~ s/^\s+|\s+$//g; 			
			@tasks=split(/,/,$TaskFullNumber);
			foreach (@tasks)
			{
				my($temp,$task)=split(/_/,$_);
				push(@tasknumbers,$task);				
			}
			print "***************\@tasknumbers are: @tasknumbers *************** \n";				
		}
		if($op =~ /AFFECTS/)
		{
			($temp,$productFullName)=split(/:/,$op);
			$productFullName=~ s/^\s+|\s+$//g;
			($temp,$productVersion)=split(/\s+/,$productFullName);
			$productVersion=~ s/^\s+|\s+$//g;
		}
		if($op =~ /FIXES/)
		{
			($temp,$patchIssueNumbers)=split(/:/,$op);
		}
	}
}
sub fetch_crs()
{
	@CRS=`sed -n '/FIXES/,/AFFECTS/ p' $patch_number\_README.txt  | sed '\$ d' | grep -v 'FIXES' | sed '/^\$/d'`;
	chomp(@CRS);
	$PatchReleaseVersion=`grep 'AFFECTS' $patch_number\_README.txt | awk '{print \$3}'`;
	$PatchReleaseVersion=~ s/^\s+|\s+$//g;
	foreach (@CRS)
	{
		my($cr,@temp)=split(/\s+/,$_);
        push(@crs,$cr);	               
	}
	print "\@crs are: @crs\n";
	open OP, "<config_dsafur.properties";
	foreach (<OP>)
	{
        next if(/^#/);
        next if(/^$/);
        ($key,$value)=split(/=/,$_);
        chomp($key);
        chomp($value);
        $properties{$key}=$value;
	}
	close OP;
	# foreach $key(keys %properties)
	# {
        # print "key=>value\t $key=>$properties{$key}\n";
	# }
	print "\$PatchReleaseVersion is: $PatchReleaseVersion \n";
	switch($PatchReleaseVersion)
	{
		case "4.0.0" 
		{
			print "4.0.0"; 
			$platformlist=$properties{'BUILD_PLTFORMS_400'};
			$platformlist=~ s/^'|'$//g;
			@platforms=split(/\s+/,$platformlist);
			foreach $platform(@platforms)
			{
				# To be built on machine
				chomp($platform);
				$hostname=$properties{'$platform'.'_HOST'};
				$key=$platform.'_HOST';
				print "\$key value is: $key<<<\n";
				print ">>>> $properties{'linAS5_HOST'} \t $properties{'$key'} and $platform AND $hostname>>>>\n";
				ccm_stop();
				exit;
				$hostname=~ s/^\s+|\s+$//g;				
				$projectName="DSA_FUR_Dev-patch_".$platform."_".$PatchReleaseVersion;
				reconfigure_dev_proj_and_compile();	
				$projectName="DSA_FUR_Delivery-patch_".$platform."_".$PatchReleaseVersion;
				reconfigure_del_project();
			}
			find_binaries_tar();
		}
		case "4.1.0" 
		{
			print "4.1.0";
			$platformlist=$properties{'BUILD_PLTFORMS_410'};
			$platformlist=~ s/^'|'$//g;
			@platforms=split(/\s+/,$platformlist);
			foreach $platform(@platforms)
			{
				# To be built on machine
				$hostname=$properties{'$platform\_HOST'};
				$projectName="DSA_FUR_Dev-patch_".$platform."_".$PatchReleaseVersion;
				reconfigure_dev_proj_and_compile();	
				$projectName="DSA_FUR_Delivery-patch_".$platform."_".$PatchReleaseVersion;
				reconfigure_del_project();
			}
			find_binaries_tar();
		}		
		
	}	
}

sub find_binaries_tar()
{
	chdir $Scripts_Dir;
	@PatchFiles=`sed -n '/AFFECTS/,/TO/ p' $patch_number\_README.txt  | sed '\$ d' | grep -v 'AFFECTS' | sed '/^\$/d'`;
	@files;
	chomp(@PatchFiles);
	#$PatchReleaseVersion="4.0.0";
	# $FUR_LINAS5_DIR=$dbbmloc."DSA_FUR_Delivery-patch_linAS5_".$PatchReleaseVersion;
	# $dir=$FUR_LINAS5_DIR; 
	#$dir="/data/ccmbm/FURident/DSA_FUR_Delivery-patch_linAS5_7.4.0";	
	foreach (@PatchFiles)
	{
        	push(@files,basename($_));
	        push(@dirs,dirname($_));
        	$sourcedir=$destdir=$_;
	        $sourcedir=~ s/\$FURHOME/$dir\/DSA_FUR_Delivery/g;
        	$destdir=~s/\$FURHOME/$ftpdir/g;
	        print "*************** $sourcedir and $destdir ***************\n";
	        $hash{$sourcedir}=$destdir;
	}
	#Search the binaries in the delivery project
	foreach $dir(@dirs)
	{
	        $dir=~s/\$FURHOME/$ftpdir/g;
        	push(@newdir,$dir);
	        `mkdir -p $dir`;
	}
	while(($key,$value)=each %hash) {
        	`cp -f $key $value`;
	}
	print "\$ftpdir is: $ftpdir \n";
	#chdir $ftpdir;
	chomp($patch_number);
	`cd $ftpdir; rm -f Patch\_$patch_number\*;tar cvf Patch_$platform\_$patch_number.tar bin; gzip -f \*\.tar`;		
}

sub start_ccm()
{
	print "In Start CCM \n";
	open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm start -d $database -m -q -r build_mgr -h ccmuk1 -nogui |");
	$ENV{'CCM_ADDR'}=<ccm_addr>;
	close(ccm_addr);
}

sub send_email()
{
	system("/usr/bin/mutt -s 'FUR PATCH BUILD COMPLETED and available at: /u/kkdaadhi/' -a /data/ccmbm/final_script/kiran_test/gmake.log -a /data/ccmbm/final_script/kiran_test/reconfigure_devproject.log -a /data/ccmbm/final_script/kiran_test/reconfigure_delproject.log $mailto < /dev/null ");
}

sub move_cr_status()
{
	print "In Move CR status \n";
}
sub ccm_stop()
{
	print "In Stop CCM \n";
	open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm stop |");
	close(ccm_addr);
}

sub reconfigure_dev_proj_and_compile()
{
	#$FUR_LINAS5_DIR="DSA_FUR_Dev-patch_linAS5_".$PatchReleaseVersion;
	#$projectName=@_;
	# Set the CCM workarea 
	$ccmworkarea=`$CCM wa -show -recurse $projectName`;
	($temp,$workarea)=split(/'/,$ccmworkarea);
	$workarea=~ s/^\s+|\s+$//g;
	print "***************CCM WorkArea is: $workarea and \$hostsname value is: $hostname\n***************";

	`$CCM folder -modify -add_task @tasks 2>&1 1>/dev/null`;
	`$CCM reconfigure -rs -r -p $projectName 2>&1 1>/data/ccmbm/final_script/kiran_test/reconfigure_devproject.log`;

	# Go to pedlinux5 and gmake clean all
	#`OST "cd $ccmworkarea; /usr/bin/gmake clean all;"`;
	chdir "$workarea/DSA_FUR_Dev";
	`rsh $hostname 'cd $workarea/DSA_FUR_Dev; /usr/bin/gmake clean all 2>&1 1>/data/ccmbm/final_script/kiran_test/gmake.log'`;
}
sub reconfigure_del_project()
{
	print "*************** Delivery projectName is: $projectName  ***************\n";
	$ccmworkarea=`$CCM wa -show -recurse $projectName`;
	($temp,$workarea)=split(/'/,$ccmworkarea);
	print "***************CCM WorkArea of Delivery Project is: $workarea***************\n";	
	`$CCM reconfigure -rs -r -p $projectName 2>&1 1>/data/ccmbm/final_script/kiran_test/reconfigure_delproject.log`;
}