@echo off

cd Content\System\

UCC.exe make -nobind
UCC.exe mastermd5 -c *.u -c ..\*.ukx -c ..\*.s4m -c ..\*.utx

cd ..\..\