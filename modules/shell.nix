{ pkgs, ... }:

{
  # ── fish ────────────────────────────────────────────────────────────────
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting   # no welcome message
    '';

    shellAliases = {
      clear = "printf '\\033[2J\\033[3J\\033[H'";
    };

    # Helpers used by the abbreviations below (ported from oh-my-zsh's git plugin).
    functions = {
      git_current_branch = {
        description = "Name of the current git branch";
        body = ''
          command git symbolic-ref --quiet --short HEAD 2>/dev/null
          or command git rev-parse --short HEAD 2>/dev/null
        '';
      };
      git_main_branch = {
        description = "Name of the repo's main branch";
        body = ''
          command git rev-parse --git-dir &>/dev/null; or return
          for ref in refs/heads/main refs/heads/trunk refs/heads/mainline refs/heads/default refs/heads/stable refs/heads/master refs/remotes/origin/main refs/remotes/origin/trunk refs/remotes/origin/mainline refs/remotes/origin/default refs/remotes/origin/stable refs/remotes/origin/master refs/remotes/upstream/main refs/remotes/upstream/trunk refs/remotes/upstream/mainline refs/remotes/upstream/default refs/remotes/upstream/stable refs/remotes/upstream/master
            if command git show-ref -q --verify $ref
              echo (string replace -r '^refs/(heads|remotes/[^/]+)/' "" $ref)
              return 0
            end
          end
          echo master
        '';
      };
      git_develop_branch = {
        description = "Name of the repo's develop branch";
        body = ''
          command git rev-parse --git-dir &>/dev/null; or return
          for branch in dev devel develop development
            if command git show-ref -q --verify refs/heads/$branch
              echo $branch
              return 0
            end
          end
          echo develop
        '';
      };
      gtl = {
        description = "List git tags matching a prefix, newest first";
        body = ''
          git tag --sort=-v:refname -n --list "$argv[1]*"
        '';
      };
    };

    # Everything from oh-my-zsh's `git` plugin that is a plain alias
    # (g, ga, gst, gco, gp, ...). Abbreviations expand as you type.
    shellAbbrs = {
      grt = "cd \"$(git rev-parse --show-toplevel || echo .)\"";
      ggpur = "ggu";
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gapa = "git add --patch";
      gau = "git add --update";
      gav = "git add --verbose";
      gwip = "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message \"--wip-- [skip ci]\"";
      gam = "git am";
      gama = "git am --abort";
      gamc = "git am --continue";
      gamscp = "git am --show-current-patch";
      gams = "git am --skip";
      gap = "git apply";
      gapt = "git apply --3way";
      gbs = "git bisect";
      gbsb = "git bisect bad";
      gbsg = "git bisect good";
      gbsn = "git bisect new";
      gbso = "git bisect old";
      gbsr = "git bisect reset";
      gbss = "git bisect start";
      gbl = "git blame -w";
      gb = "git branch";
      gba = "git branch --all";
      gbd = "git branch --delete";
      gbD = "git branch --delete --force";
      gbgd = "LANG=C git branch --no-color -vv | grep \": gone\\]\" | cut -c 3- | awk '\"'\"'{print $1}'\"'\"' | xargs git branch -d";
      gbgD = "LANG=C git branch --no-color -vv | grep \": gone\\]\" | cut -c 3- | awk '\"'\"'{print $1}'\"'\"' | xargs git branch -D";
      gbm = "git branch --move";
      gbnm = "git branch --no-merged";
      gbr = "git branch --remotes";
      ggsup = "git branch --set-upstream-to=origin/$(git_current_branch)";
      gbg = "LANG=C git branch -vv | grep \": gone\\]\"";
      gco = "git checkout";
      gcor = "git checkout --recurse-submodules";
      gcb = "git checkout -b";
      gcB = "git checkout -B";
      gcd = "git checkout $(git_develop_branch)";
      gcm = "git checkout $(git_main_branch)";
      gcp = "git cherry-pick";
      gcpa = "git cherry-pick --abort";
      gcpc = "git cherry-pick --continue";
      gclean = "git clean --interactive -d";
      gcl = "git clone --recurse-submodules";
      gclf = "git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules";
      gcam = "git commit --all --message";
      gcas = "git commit --all --signoff";
      gcasm = "git commit --all --signoff --message";
      gcs = "git commit --gpg-sign";
      gcss = "git commit --gpg-sign --signoff";
      gcssm = "git commit --gpg-sign --signoff --message";
      gcmsg = "git commit --message";
      gcsm = "git commit --signoff --message";
      gc = "git commit --verbose";
      gca = "git commit --verbose --all";
      "gca!" = "git commit --verbose --all --amend";
      "gcan!" = "git commit --verbose --all --no-edit --amend";
      "gcans!" = "git commit --verbose --all --signoff --no-edit --amend";
      "gcann!" = "git commit --verbose --all --date=now --no-edit --amend";
      "gc!" = "git commit --verbose --amend";
      gcn = "git commit --verbose --no-edit";
      "gcn!" = "git commit --verbose --no-edit --amend";
      gcf = "git config --list";
      gcfu = "git commit --fixup";
      gdct = "git describe --tags $(git rev-list --tags --max-count=1)";
      gd = "git diff";
      gdca = "git diff --cached";
      gdcw = "git diff --cached --word-diff";
      gds = "git diff --staged";
      gdw = "git diff --word-diff";
      gdup = "git diff @{upstream}";
      gdt = "git diff-tree --no-commit-id --name-only -r";
      gf = "git fetch";
      gfo = "git fetch origin";
      gg = "git gui citool";
      gga = "git gui citool --amend";
      ghh = "git help";
      glgg = "git log --graph";
      glgga = "git log --graph --decorate --all";
      glgm = "git log --graph --max-count=10";
      glods = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\" --date=short";
      glod = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\"";
      glola = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\" --all";
      glols = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\" --stat";
      glol = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\"";
      glolm = "git log $(git_main_branch) --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\"";
      glo = "git log --oneline --decorate";
      glog = "git log --oneline --decorate --graph";
      gloga = "git log --oneline --decorate --graph --all";
      glom = "git log --oneline --decorate --color $(git_main_branch)..";
      glp = "_git_log_prettily";
      glg = "git log --stat";
      glgp = "git log --stat --patch";
      gignored = "git ls-files -v | grep \"^[[:lower:]]\"";
      gfg = "git ls-files | grep";
      gm = "git merge";
      gma = "git merge --abort";
      gmc = "git merge --continue";
      gms = "git merge --squash";
      gmff = "git merge --ff-only";
      gmom = "git merge origin/$(git_main_branch)";
      gmum = "git merge upstream/$(git_main_branch)";
      gmtl = "git mergetool --no-prompt";
      gmtlvim = "git mergetool --no-prompt --tool=vimdiff";
      gl = "git pull";
      gpr = "git pull --rebase";
      gprv = "git pull --rebase -v";
      gpra = "git pull --rebase --autostash";
      gprav = "git pull --rebase --autostash -v";
      gprom = "git pull --rebase origin $(git_main_branch)";
      gpromi = "git pull --rebase=interactive origin $(git_main_branch)";
      gprum = "git pull --rebase upstream $(git_main_branch)";
      gprumi = "git pull --rebase=interactive upstream $(git_main_branch)";
      ggpull = "git pull origin \"$(git_current_branch)\"";
      gluc = "git pull upstream $(git_current_branch)";
      glum = "git pull upstream $(git_main_branch)";
      gp = "git push";
      gpd = "git push --dry-run";
      "gpf!" = "git push --force";
      gpsup = "git push --set-upstream origin $(git_current_branch)";
      gpv = "git push --verbose";
      gpoat = "git push origin --all && git push origin --tags";
      gpod = "git push origin --delete";
      ggpush = "git push origin \"$(git_current_branch)\"";
      gpu = "git push upstream";
      grb = "git rebase";
      grba = "git rebase --abort";
      grbc = "git rebase --continue";
      grbi = "git rebase --interactive";
      grbo = "git rebase --onto";
      grbs = "git rebase --skip";
      grbd = "git rebase $(git_develop_branch)";
      grbm = "git rebase $(git_main_branch)";
      grbom = "git rebase origin/$(git_main_branch)";
      grbum = "git rebase upstream/$(git_main_branch)";
      grbmi = "git rebase $(git_main_branch) --interactive";
      grbmia = "git rebase $(git_main_branch) --interactive --autosquash";
      grf = "git reflog";
      gr = "git remote";
      grv = "git remote --verbose";
      gra = "git remote add";
      grrm = "git remote remove";
      grmv = "git remote rename";
      grset = "git remote set-url";
      grup = "git remote update";
      grh = "git reset";
      gru = "git reset --";
      grhh = "git reset --hard";
      grhk = "git reset --keep";
      grhs = "git reset --soft";
      gpristine = "git reset --hard && git clean --force -dfx";
      gwipe = "git reset --hard && git clean --force -df";
      groh = "git reset origin/$(git_current_branch) --hard";
      grs = "git restore";
      grss = "git restore --source";
      grst = "git restore --staged";
      gunwip = "git rev-list --max-count=1 --format=\"%s\" HEAD | grep -q \"\\--wip--\" && git reset HEAD~1";
      grev = "git revert";
      greva = "git revert --abort";
      grevc = "git revert --continue";
      grm = "git rm";
      grmc = "git rm --cached";
      gcount = "git shortlog --summary --numbered";
      gsh = "git show";
      gshs = "git show --stat";
      gsps = "git show --pretty=short --show-signature";
      gstall = "git stash --all";
      gstaa = "git stash apply";
      gstc = "git stash clear";
      gstd = "git stash drop";
      gstl = "git stash list";
      gstp = "git stash pop";
      gsts = "git stash show --patch";
      gst = "git status";
      gss = "git status --short";
      gsb = "git status --short --branch";
      gsnut = "git status --untracked-files=no";
      gsi = "git submodule init";
      gsu = "git submodule update";
      gsuri = "git submodule update --recursive --init";
      gsd = "git svn dcommit";
      git-svn-dcommit-push = "git svn dcommit && git push github $(git_main_branch):svntrunk";
      gsr = "git svn rebase";
      gsw = "git switch";
      gswc = "git switch --create";
      gswd = "git switch $(git_develop_branch)";
      gswm = "git switch $(git_main_branch)";
      gta = "git tag --annotate";
      gts = "git tag --sign";
      gtv = "git tag | sort -V";
      gignore = "git update-index --assume-unchanged";
      gunignore = "git update-index --no-assume-unchanged";
      gwch = "git log --patch --abbrev-commit --pretty=medium --raw";
      gwt = "git worktree";
      gwta = "git worktree add";
      gwtls = "git worktree list";
      gwtmv = "git worktree move";
      gwtrm = "git worktree remove";
      gstu = "gsta --include-untracked";
      gk = "\\gitk --all --branches &!";
      gke = "\\gitk --all $(git log --walk-reflogs --pretty=%h) &!";
    };
  };

  # ── prompt ──────────────────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  # ── terminal ────────────────────────────────────────────────────────────
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      font-family = "Hack";
      font-size = 12;

      # Window background of the Orchis-Purple-Dark theme (@window_bg_color), instead
      # of Ghostty's own blue-grey default (#282C34). Content areas such as lists
      # and text views use the slightly lighter #2C2C2C if you prefer that.
      background = "#2C2C2C";
      window-padding-x = 10;
      window-padding-y = 10;
      confirm-close-surface = false;
    };
  };
}
