# agzakmd.zsh-theme
#
# Based on:
# * agnoster's Theme - https://gist.github.com/3712874
#   A Powerline-inspired theme for ZSH
# * agnosterzak - https://github.com/zakaziko99/agnosterzak-ohmyzsh-theme
#
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  SEGMENT_SEPARATOR=$'\ue0b0'
}

# Begin a segment
# $1 - background color
# $2 - foreground color
# $3 - message
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  [[ -n $RIGHT ]] && echo -n "%{%F{$1}%}%{$bg%}{$fg%}"
  if [[ ! -n $RIGHT ]]; then
    if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
      echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
    else
      echo -n "%{$bg%}%{$fg%} "
    fi
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n "$3 "
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"

    #prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m"
  fi
}

# Battery Level
prompt_battery() {
  HEART='♥ '

  if [[ $(uname) == "Linux"  ]] ; then

    function battery_is_charging() {
      ! [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]]
    }

    function battery_pct() {
      if (( $+commands[acpi] )) ; then
        echo "$(acpi | cut -f2 -d ',' | tr -cd '[:digit:]')"
      fi
    }

    function battery_pct_remaining() {
      if [ ! $(battery_is_charging) ] ; then
        battery_pct
      else
        echo "External Power"
      fi
    }

    function battery_time_remaining() {
      if [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]] ; then
        echo $(acpi | cut -f3 -d ',')
      fi
    }

    b=$(battery_pct_remaining)
    if [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]] ; then
      if [ $b -gt 40 ] ; then
        prompt_segment green $whiteB
      elif [ $b -gt 20 ] ; then
        prompt_segment yellow $whiteB
      else
        prompt_segment red $whiteB
      fi
      echo -n "$HEART$(battery_pct_remaining)%%"
    fi

  fi
}


# Git: branch/detached head, dirty status
prompt_git() {
#«»±˖˗‑‐‒ ━ ✚‐↔←↑↓→↭⇎⇔⋆━◂▸◄►◆☀★☗☊✔✖❮❯⚑⚙
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }
  local ref dirty mode repo_path clean has_upstream
  local modified untracked added deleted tagged stashed
  local ready_commit git_status bgclr fgclr
  local commits_diff commits_ahead commits_behind has_diverged to_push to_pull

  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    git_status=$(git status --porcelain 2> /dev/null)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      clean=''
      bgclr='yellow'
      fgclr='magenta'
    else
      clean=' ✔'
      bgclr='green'
      fgclr="$whiteB"
    fi

    local upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
    if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then has_upstream=true; fi

    local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

    local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
    # if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files◆"; fi
    if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files☀"; fi

    local number_added=$(\grep -c "^A" <<< "${git_status}")
    if [[ $number_added -gt 0 ]]; then added=" $number_added✚"; fi

    local number_modified=$(\grep -c "^.M" <<< "${git_status}")
    if [[ $number_modified -gt 0 ]]; then
      modified=" $number_modified●"
      bgclr='red'
      fgclr="$whiteB"
    fi

    local number_added_modified=$(\grep -c "^M" <<< "${git_status}")
    local number_added_renamed=$(\grep -c "^R" <<< "${git_status}")
    if [[ $number_modified -gt 0 && $number_added_modified -gt 0 ]]; then
      modified="$modified$((number_added_modified+number_added_renamed))±"
    elif [[ $number_added_modified -gt 0 ]]; then
      modified=" ●$((number_added_modified+number_added_renamed))±"
    fi

    local number_deleted=$(\grep -c "^.D" <<< "${git_status}")
    if [[ $number_deleted -gt 0 ]]; then
      deleted=" $number_deleted‒"
      bgclr='red'
      fgclr="$whiteB"
    fi

    local number_added_deleted=$(\grep -c "^D" <<< "${git_status}")
    if [[ $number_deleted -gt 0 && $number_added_deleted -gt 0 ]]; then
      deleted="$deleted$number_added_deleted±"
    elif [[ $number_added_deleted -gt 0 ]]; then
      deleted=" ‒$number_added_deleted±"
    fi

    local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
    if [[ -n $tag_at_current_commit ]]; then tagged=" ☗$tag_at_current_commit "; fi

    local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
    if [[ $number_of_stashes -gt 0 ]]; then
      stashed=" $number_of_stashes⚙"
      bgclr='magenta'
      fgclr="$whiteB"
    fi

    if [[ $number_added -gt 0 || $number_added_modified -gt 0 || $number_added_deleted -gt 0 ]]; then ready_commit=' ⚑'; fi

    local upstream_prompt=''
    if [[ $has_upstream == true ]]; then
      commits_diff="$(git log --pretty=oneline --topo-order --left-right ${current_commit_hash}...${upstream} 2> /dev/null)"
      commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
      commits_behind=$(\grep -c "^>" <<< "$commits_diff")
      upstream_prompt="$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)"
      upstream_prompt=$(sed -e 's/\/.*$/ ☊ /g' <<< "$upstream_prompt")
    fi

    has_diverged=false
    if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then has_diverged=true; fi
    if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then
      if [[ $bgclr == 'red' || $bgclr == 'magenta' ]] then
        to_push=" ↑$commits_ahead"
      else
        to_push=" ↑$commits_ahead"
      fi
    fi
    if [[ $has_diverged == false && $commits_behind -gt 0 ]]; then to_pull=" ↓$commits_behind"; fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    prompt_segment $bgclr $fgclr

    echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR $upstream_prompt}${mode}$to_push$to_pull$clean$tagged$stashed$untracked$modified$deleted$added$ready_commit"
  fi
}

prompt_bzr() {
    (( $+commands[bzr] )) || return
    if (bzr status >/dev/null 2>&1); then
        status_mod=`bzr status | head -n1 | grep "modified" | wc -m`
        status_all=`bzr status | head -n1 | wc -m`
        revision=`bzr log | head -n2 | tail -n1 | sed 's/^revno: //'`
        if [[ $status_mod -gt 0 ]] ; then
            prompt_segment yellow black
            echo -n "bzr@"$revision "✚ "
        else
            if [[ $status_all -gt 0 ]] ; then
                prompt_segment yellow black
                echo -n "bzr@"$revision

            else
                prompt_segment green black
                echo -n "bzr@"$revision
            fi
        fi
    fi
}

prompt_hg() {
  (( $+commands[hg] )) || return
  local rev status
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red $whiteB
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green black
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^[MA]"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green black
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue white '%3~'
}

prompt_time() {
  prompt_segment blue white '%D{%I:%M %p}'
}

prompt_errorcode() {
  [[ $RETVAL -ne 0 ]] && prompt_segment red $whiteB "$RETVAL"
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_end
}

build_r_prompt() {
  RETVAL=$?
  RIGHT=1
  whiteB=15
  prompt_errorcode
  prompt_git
  prompt_bzr
  prompt_hg
  prompt_time
  prompt_battery
} 

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='%{%f%b%k%}$(build_r_prompt)'
