FROM python:2-windowsservercore-ltsc2016
#Documentation: https://docs.google.com/document/d/1_ywSlpHvLFtv0UXwF6X25e8I16kUIuIPiKnF1TVx6-w/

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

###vvvvvvvvvvvvvvvvvvvv###
## Manage some pre-requisites
RUN powershell Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force


###vvvvvvvvvvvvvvvvvvvv###
### Install Got Your Back
#
ENV GYB_VER=1.0
RUN Invoke-WebRequest -Uri "https://github.com/jay0lee/got-your-back/releases/download/v${env:GYB_VER}/gyb-${env:GYB_VER}-windows.zip" -OutFile "C:\gyb-windows.zip"; \
    Expand-Archive "C:\gyb-windows.zip" -DestinationPath C:\; Remove-Item -Force "C:\gyb-windows.zip"
#   To work around issue https://github.com/MicrosoftDocs/Virtualization-Documentation/issues/497 
#   The C:\gyb folder has to be empty when we mount it.  Therefore, the user must copy gyb.exe and other contents into this mount.
RUN Move-Item C:\gyb c:\gyb-src; \
    New-Item -Type File C:\gyb-src\nobrowser.txt; New-Item -Type File C:\gyb-src\noupdatecheck.txt; New-Item -Type File C:\gyb-src\nocache.txt;
###^^^^^^^^^^^^^^^^^^^^###


###vvvvvvvvvvvvvvvvvvvv###
### Install GAM
#   We are using the source because the gam.exe had an issue with utf-8 (cp65001) support in powershell.
#
ENV GAM_VER=4.40
ENV PYTHONIOENCODING=utf-8
RUN Invoke-WebRequest -Uri "https://github.com/jay0lee/GAM/archive/v${env:GAM_VER}.zip" -OutFile C:\gam.zip; \
    Expand-Archive C:\gam.zip -DestinationPath C:\; Remove-Item -Force C:\gam.zip;
#   To work around issue https://github.com/MicrosoftDocs/Virtualization-Documentation/issues/497 
#   The C:\gam folder has to be empty when we mount it.  Therefore, the user must copy gam.py and other contents into this mount.
RUN New-Item -Type Directory -Path C:\gam-src; \
    Copy-Item -Recurse "C:\GAM-${env:GAM_VER}\src\*" C:\gam-src\; \
    New-Item -Type File C:\gam-src\nobrowser.txt; New-Item -Type File C:\gam-src\noupdatecheck.txt; New-Item -Type File C:\gam-src\nocache.txt;  \
    Remove-Item -Force -Recurse "C:\GAM-${env:GAM_VER}";
###^^^^^^^^^^^^^^^^^^^^###

### Configure Our scripts 
COPY scripts c:\scripts
ENTRYPOINT ["powershell", "-NoProfile", "-Command"]
CMD ["C:\\scripts\\mail_backup.ps1"]

VOLUME C:\\data
VOLUME C:\\gam
VOLUME C:\\gyb
