
if which exa 1>/dev/null 2>&1 ; then
  alias ls='command exa --sort=Name --group-directories-first'
  alias ll='command exa --sort=Name --group-directories-first --time-style=long-iso -g -h -l'
  alias la='command exa --sort=Name --group-directories-first --time-style=long-iso -g -h -l -a'
  alias l.='command exa --sort=Name --group-directories-first --time-style=long-iso -g -h -l -a -a --links --inode --blocks --git'
  alias l.e='command exa --sort=Name --group-directories-first --time-style=long-iso -g -h -l -a -a --links --inode --blocks --extended --git'
  alias lg='command exa --sort=Name --group-directories-first --time-style=long-iso -g -h -l --git'
else
  alias ls='command ls -CF   --color --time-style=long-iso --group-directories-first'
  alias ll='command ls -CFl  --color --time-style=long-iso --group-directories-first'
  alias la='command ls -CFlA --color --time-style=long-iso --group-directories-first'
  alias l.='command ls -CFla --color --time-style=long-iso --group-directories-first'
fi
