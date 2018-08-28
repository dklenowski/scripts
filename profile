# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# Terraform
#export PATH=$PATH:/opt/terraform_0.7.2:/opt/terraform_0.6.16_darwin_amd64
export PATH=/opt/terraform:$PATH
export PATH=$PATH:/opt
#. ~/dev-dklenowski-openrc.sh

# User specific aliases and functions
export JAVA_HOME=`/usr/libexec/java_home`

export MAVEN_HOME=/opt/maven
export PATH=$PATH:$MAVEN_HOME/bin

export GRADLE_HOME=/opt/gradle-1.7
export PATH=$PATH:$GRADLE_HOME/bin

export GOPATH=~/go
export PATH=$PATH:$GOPATH/bin

# MySQL
export PATH=$PATH:/usr/local/mysql/bin

# Brew
export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# Python for brew
export PYTHONPATH=`brew --prefix`/lib/python2.7/site-packages:$PYTHONPATH

# puppet
export PATH=/opt/puppetlabs/bin:$PATH

# for elasticsearch and kibana
export ELASTIC_HOME=/opt/elasticsearch
export PATH=$PATH:$ELASTIC_HOME/bin

export KIBANA_HOME=/opt/kibana
export PATH=$PATH:$KIBANA_HOME/bin

# flutter
export export PATH=/Users/dklenowski/development/flutter/bin:$PATH


ssh-add -l

# some functions

function ga() {
  git add .
}

function gp() {
  git pull
}

function gcp() {
  git checkout production
}

function gcm() {
  git checkout master
}

function gca() {
  git commit --amend
}

function gpo() {
  branch=`git status | grep branch | awk '{print $3}'`
  if [ "$branch" == "" ]; then
    echo "Doesn't look like your on a branch"
  else
    git push origin $branch --force
  fi
}


# find stuff
function f() {
  find . -type f -not -iwholename '*.git*' -print -exec grep -i $1 {} \;
}

function fe() {
  res=`find ./ -iname $1`
  if [ "$res" ]; then
    vim $res
  else
    echo "Failed to find $1 (case insensitive)"
  fi
}

# find stuff for java
function fj() {
  find ./ -name $1.java
}

function fje() {
  res=`find ./ -iname $1.java`
  if [ "$res" ]; then
    vim $res
  else
    echo "Failed to find $1.java (case insensitive)"
  fi
}

function fje() {
  res=`find ./ -iname $1.java`
  if [ "$res" ]; then
    vim $res
  else
    echo "Failed to find $1.java (case insensitive)"
  fi
}

function fjg() {
  find ./ -name *.java -print -exec grep -i $1 {} \;
}


# maven stuff
function m() {
  mvn clean install
}

function mn() {
  mvn -Dmaven.test.skip=true clean install
}


# mercurial stuff
function hgpu() {
  hg pull
  hg update
}

function hgrm() {
  find ./ -name *\.orig -print -exec rm {} \;
}

function fyaml() {
  find ./ -type f -not -iwholename '*.git*' -name \*.yaml -print -exec grep -i $1 {} \;
}

function fpp() {
  find ./ -type f -not -iwholename '*.git*' -name \*.pp -print -exec grep -i $1 {} \;
}

_complete_ssh_hosts ()
{
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        comp_ssh_hosts=`cat ~/.ssh/known_hosts | \
                        cut -f 1 -d ' ' | \
                        sed -e s/,.*//g | \
                        grep -v ^# | \
                        uniq | \
                        grep -v "\[" ;
                cat ~/.ssh/config | \
                        grep "^Host " | \
                        awk '{print $2}'
                `
        COMPREPLY=( $(compgen -W "${comp_ssh_hosts}" -- $cur))
        return 0
}
complete -F _complete_ssh_hosts ssh

