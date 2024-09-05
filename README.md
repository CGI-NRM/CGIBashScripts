# CGIBashScripts
A repository for storing bash scripts of common use at CGI.

# Dependencies
These repos need to be cloned down in the following way in order for all scripts to work:
```bash
cd ~/
git clone https://github.com/tavinus/cloudsend.sh
```

# Usage
In the terminal:
```bash
cd ~/
git clone https://github.com/CGI-NRM/CGIBashScripts
cd CGIBashScripts/
```
In this folder, edit the file `user_settings.sh` and add your specifics. Then, in the terminal:
```bash
source cgi_scripts.sh
```
This will make the aliases and functions available to you in your session. To make them persistently available, add the line `source ~/CGIBashScripts/cgi_scripts.sh` to your `.bashrc`.
