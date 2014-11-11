#!/usr/bin/perl
use Cwd;
use File::Path;

#/************ Setting Environment Variables *******************/
$ENV{'CCM_HOME'}="/opt/ccm71";
$ENV{'PATH'}="$ENV{'CCM_HOME'}/bin:$ENV{'PATH'}";
open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm start -d /data/ccmdb/provident -m -q -r build_mgr -h ccmuk1 -nogui |");
$ENV{'CCM_ADDR'}=<ccm_addr>;
close(ccm_addr);
$CCM="$ENV{'CCM_HOME'}/bin/ccm";
@platformList740=("JAVA5");
$LINAS5_HOST=pedlinux5;
#/* Global Environment Variables ******* /

chdir "/data/ccmbm/final_script/kiran_test";
$ccm_request_type=`$CCM query "cvtype=\'problem\' and crstatus=\'Closed\' and problem_number=\'3951\'"`;
$patch_number=`$CCM query -u -f %patch_number`;
$patch_readme=`$CCM query -u -f %patch_readme`;
$patch_number=~ s/^\s+|\s+$//g;
open OP,"+> $patch_number\_README.txt";
print OP $patch_readme;
close OP;
`dos2unix $patch_number\_README.txt 2>&1 1>/dev/null`;

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
		($temp,$TaskNumber)=split(/_/,$TaskFullNumber);
		$TaskNumber=~ s/^\s+|\s+$//g;
		($PatchNumber)=split(/,/,$TaskNumber);
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

# Reconfigure the project
open OP, "<config.properties";
my @op=<OP>;
close OP;

foreach $op(@op)
{
	if($op =~ /BUILD_PLTFORMS_740/)
	{
		my ($temp,$test)=split(/'/,$op);
		($temp,$test1)=split(/'/,$test);
                @ary=split(/\s+/,$temp);
		push(@ary,@platformList740);
	}
}
$PatchReleaseVersion=7.4.0;
$PROV_LINAS5_DIR="Provident_Dev-patch_linAS5_$PatchReleaseVersion";
$projectName=$PROV_LINAS5_DIR;

# Set the CCM workarea 
$ccmworkarea=`$CCM wa -show -recurse $projectName|tr " " "\n"|grep  "'" | tr  \' " "`;
print "CCM WorkArea is: $ccmworkarea";

# Reconfigure the project
# Provident_Dev-patch_linAS5_7.4.0 9996
$SYSTEM_FOLDER_NO_740=1252;
`$CCM folder -modify -add_task $TaskNumber $SYSTEM_FOLDER_NO`;
`$CCM reconfigure -rs -r -p $projectName`;

# Go to pedlinux5 and gmake clean all
`rsh $LINAS5_HOST "cd $ccmworkarea; /usr/bin/gmake clean all;"`;
chdir($ccmworkarea);
`gmake clean all`;

# Go to Delivery project and reconcile and build the tar file
$PatchReleaseVersion=7.4.0;
$PROV_LINAS5_DIR="Provident_Delivery-patch_linAS5_$PatchReleaseVersion";
$projectName=$PROV_LINAS5_DIR;
$ccmworkarea=`$CCM wa -show -recurse $projectName|tr " " "\n"|grep  "'" | tr  \' " "`;
print "CCM Delivery Project WorkArea is: $ccmworkarea";
`$CCM reconcile -missing_wa_file -update_wa $ccmworkarea`;

#find_binaries $DEV_DIR_NAME $JAVA_DIR_NAME $SSH_HOST
$PatchFiles=`sed -n "/AFFECTS/,/TO/ p" $patch_number\_README.txt  | sed "\$ d" | grep -v "AFFECTS"`;
print "\$PatchFiles are: $PatchFiles";

my @files;
foreach (@PatchFiles)
{
        print "\$PatchFiles is: $_";
        push(@files,basename($_));
}
print "@files";

open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm stop |");
close(ccm_addr);
exit;
