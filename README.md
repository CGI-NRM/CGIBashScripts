# CGIBashScripts
A repository for storing bash scripts of common use at CGI.

# Dependencies
These repos need to be cloned to your home folder in the following way in order for all scripts to work:
```bash
cd ~/
git clone https://github.com/tavinus/cloudsend.sh
```

# Usage
In the terminal:
```bash
cd ~/ # go to your home folder
git clone https://github.com/CGI-NRM/CGIBashScripts # clone down this repo
cd CGIBashScripts/ # navigate to it
```
In this folder, edit the file `.cgi_user_settings.sh` and add your specifics (it can also be stored in your home folder). Then, in the terminal:
```bash
source ~/CGIBashScripts/cgi_scripts.sh
```
This will make the aliases and functions available to you in your session.
To make them persistently available, add the line `source ~/CGIBashScripts/cgi_scripts.sh` to your `.bashrc`. If unsure how to, simply do (exactly like this):
```bash
echo "source ~/CGIBashScripts/cgi_scripts.sh" >> ~/.bashrc
```

## Help
For a brief help message (work in progress) simply do:
```bash
cgi_help
```

