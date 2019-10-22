#/usr/bin/env bash
#bdereims@vmware.com

_cpodctl_completions()
{
  COMPREPLY+=("list")
  COMPREPLY+=("password")
  COMPREPLY+=("create")
  COMPREPLY+=("delete")
  COMPREPLY+=("addfiler")
  COMPREPLY+=("vcsa")
  COMPREPLY+=("backup")
  COMPREPLY+=("restore")
  COMPREPLY+=("help")
  COMPREPLY+=("lease")
}

complete -F _cpodctl_completions cpodctl 
