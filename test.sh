#! /bin/sh
export CCM_HOME=/opt/ccm71
export PATH=$CCM_HOME/bin:$PATH
export CCM_ADDR=`ccm start -d /data/ccmdb/provident -m -q -r build_mgr -h ccmuk1 -nogui`
ccm_requestType_qry=`ccm query "cvtype='problem' and crstatus='Closed' and problem_number='3929'`
export patchnumber=`ccm query -u -f %patch_number`
export patch_readme=`ccm query -u -f %patch_readme`
echo "$patchnumber:"
export patchnumber=`echo $patchnumber | cut -d" " -f1`
echo "$patchnumber:"
echo "$patch_readme" > ./${patchnumber}_README.txt
chmod -R 0777 ./${patchnumber}_README.txt;
dos2unix ./${patchnumber}_README.txt;

